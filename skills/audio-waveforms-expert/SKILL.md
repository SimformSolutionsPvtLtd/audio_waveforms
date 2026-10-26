---
name: audio-waveforms-expert
description: >-
  Expert guidance for the audio_waveforms Flutter package - RecorderController, AudioWaveforms, PlayerController, AudioFileWaveforms, WaveformExtractionController, WaveStyle, PlayerWaveStyle, RecorderSettings. Use when recording audio with a live waveform, playing audio files with a seekable waveform, extracting or caching waveform data, chat voice-message bubbles, replay after completion, waveform not showing or empty, recorder waves freezing, fixing "waveThickness can't be greater than spacing", "Cannot provide both noOfSamples and noOfSamplesPerSecond", "Cannot provide both a color and a decoration", "LateInitializationError: Field '_extractionProgressController'", "PlatformException(AudioWaveforms, Failed to prepare player", "Failed to start recording", "Cannot set the method call handler before the binary messenger has been initialized", or migrating 1.x code (androidEncoder:/androidOutputFormat: on record, tapUpUpdateDetails, playerController.extractWaveformData).
license: MIT
metadata:
  author: Simform Solutions
  package: audio_waveforms
  version: "2.0.2"
---

# audio_waveforms Expert - record, play and draw audio waveforms

**What:** A Flutter plugin (Android, iOS, and macOS from 2.1.0) that records audio from the microphone with a live waveform (`RecorderController` + `AudioWaveforms`) and plays local audio files with a seekable waveform (`PlayerController` + `AudioFileWaveforms`). It also extracts waveform data from files so you can cache it. This skill ships inside the package, so it matches the installed version. If it disagrees with the package source or CHANGELOG.md, trust those and tell the user.

## CRITICAL RULES

1. **`await preparePlayer(...)` first.** It creates the native player. Before it, `startPlayer`/`seekTo` silently do nothing, and `setFinishMode`, `getDuration`, `setVolume` and `setRate` return a `Future` that **never completes**. So does the native release inside `dispose()`, so disposing a never-prepared controller never finishes its cleanup.
2. **The default `FinishMode.stop` releases the player when the audio ends**, so `startPlayer()` then does nothing. To allow replay, call `setFinishMode(finishMode: FinishMode.pause)` (or `.loop`) after `preparePlayer`, or prepare again.
3. **Never read `controller.waveformExtraction.waveformData`.** It returns a copy that is always empty. Use the list returned by `extractWaveformData(...)`. `AudioFileWaveforms(continuousWaveform: false)` therefore draws nothing unless you pass `waveformData:`.
4. **Widgets capture some arguments once, in `initState`.** `AudioWaveforms` ignores later changes to `size`, `waveStyle` and `recorderController`; `AudioFileWaveforms` ignores later changes to `waveformData` and `continuousWaveform`, and keeps listening to the original `playerController`. Use a new `key` to apply them. An `AudioFileWaveforms` built *after* extraction finished (ListView recycling, tab switch) is empty, so cache the data and pass `waveformData:`.
5. **Don't dispose the last `PlayerController` while a `RecorderController` is in use.** A recorder on its own is fine, but disposing the last player, or calling `stopAllPlayers()`, closes the shared streams. The live recorder stops getting waves, and existing players stop getting position and state events.
6. **Use local file paths only.** Copy assets to a file and download remote audio first (iOS/macOS cannot open URLs). Android `content://` URIs are not supported. `preparePlayer` parses the path as a URI: it strips `file://`, and a `#` or `?` in the name truncates the path.
7. **When permission is denied, `record()` returns without error** and the state stays `stopped`, so check `hasPermission`. Failures arrive either as a thrown `String` ("Failed to start recording") or as a `PlatformException`, so use `catch (e)`, not `on Exception catch`.
8. **Pass `record(path:)` with an extension that matches the encoder** (`.m4a` for AAC, `.wav` for WAV/LinearPCM). Without a path the file is a date-named `.m4a` whatever the encoder, in the cache dir on Android and the documents dir on iOS/macOS.
9. **`spacing` must be greater than `waveThickness`** in `WaveStyle` and `PlayerWaveStyle`. `PlayerWaveStyle(spacing: 3)` asserts because the default thickness is 3.
10. **Use the 2.x names:** `RecorderSettings(androidEncoderSettings:, iosEncoderSettings:)`, `AudioFileWaveforms(playerController:)` (not `controller:`), `onTapUp` (not `tapUpUpdateDetails`), `waveformExtraction.extractWaveformData`. `startPlayer` has no `finishMode` parameter. Don't invent APIs for the limitations below.

## Setup

- pubspec: `audio_waveforms: ^2.0.2`. Import only `package:audio_waveforms/audio_waveforms.dart`.
- Android: `<uses-permission android:name="android.permission.RECORD_AUDIO" />`, and `minSdkVersion 23` (the recorder needs API 23; below API 26 `seekTo` does nothing and its `Future` never completes).
- iOS: `NSMicrophoneUsageDescription` in `Info.plist`, `platform :ios, '13.0'` in the Podfile.
- macOS (2.1.0+): `NSMicrophoneUsageDescription`, plus `com.apple.security.device.audio-input` = `true` in **both** `DebugProfile.entitlements` and `Release.entitlements`; `platform :osx, '10.14'`.
- Create controllers after `runApp`/`WidgetsFlutterBinding.ensureInitialized()`, not as top-level globals.

## Recording

```dart
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';

class RecorderView extends StatefulWidget {
  const RecorderView({super.key, required this.dirPath, required this.onDone});
  final String dirPath; // e.g. getApplicationDocumentsDirectory().path
  final ValueChanged<String> onDone;

  @override
  State<RecorderView> createState() => _RecorderViewState();
}

class _RecorderViewState extends State<RecorderView> {
  final recorder = RecorderController();

  Future<void> _toggle() async {
    try {
      if (recorder.isRecording) {
        final path = await recorder.stop(); // clears waves; stop(false) keeps them
        if (path != null) widget.onDone(path);
      } else {
        await recorder.record(
          path: '${widget.dirPath}/${DateTime.now().millisecondsSinceEpoch}.m4a',
        );
        if (!recorder.hasPermission) {
          // Permission denied: record() returned without recording.
        }
      }
    } catch (e) {
      debugPrint('Recorder error: $e'); // a String or a PlatformException
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    recorder.dispose(); // stops recording but the file path is lost; stop() first
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      AudioWaveforms(
        size: const Size(250, 50),
        recorderController: recorder,
        enableGesture: true,
        waveStyle: const WaveStyle(
          waveColor: Colors.white,
          extendWaveform: true,
          showMiddleLine: false,
        ),
        decoration: BoxDecoration(
          color: Colors.black87, // use decoration OR backgroundColor, never both
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      IconButton(
        icon: Icon(recorder.isRecording ? Icons.stop : Icons.mic),
        onPressed: _toggle,
      ),
    ]);
  }
}
```

- `pause()` then `record()` resumes the same file. `reset()` clears the bars. `refresh()` jumps back to live after a drag.
- `waveData` values are 0–1; bar half-height = value × `WaveStyle.scaleFactor` (default 20).
- Streams: `onRecorderStateChanged`, `onCurrentDuration`, `onRecordingEnded`, `onAudioChunks` (raw `Uint8List`: 16-bit signed little-endian mono PCM at `sampleRate` on Android; Float32 samples at the hardware rate on iOS; Float32 at `sampleRate` on macOS). After `stop()`, `recordedDuration` holds the file length.
- `waveformRenderMode: WaveformRenderMode.rtl` draws from the right; `extendWaveform` is ignored there. `showDurationLabel: true` adds labels; raise `extraClipperHeight` if they are clipped.
- iOS `overrideAudioSession` (default `true`) sets `.playAndRecord`. If you set it to `false` without configuring the session yourself, you get no audio and no waves.

### Encoders (WAV example)

```dart
Future<void> recordWav(RecorderController recorder, String dirPath) {
  return recorder.record(
    path: '$dirPath/clip.wav', // extension must match the encoder
    recorderSettings: const RecorderSettings(
      sampleRate: 44100,
      bitRate: 128000,
      androidEncoderSettings: AndroidEncoderSettings(androidEncoder: AndroidEncoder.wav),
      iosEncoderSettings: IosEncoderSetting(
        iosEncoder: IosEncoder.kAudioFormatLinearPCM,
        linearPCMBitDepth: 16,
      ),
    ),
  );
}
```

Defaults: AAC (`aacLc` / `kAudioFormatMPEG4AAC`), 44100 Hz, 128 kbps. Android has no MP3 encoder.

## Playback (chat bubble pattern)

```dart
import 'dart:async';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';

class VoiceBubble extends StatefulWidget {
  const VoiceBubble({super.key, required this.path, this.cachedWaves});
  final String path; // local file path
  final List<double>? cachedWaves;

  @override
  State<VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<VoiceBubble> {
  final player = PlayerController();
  static const style = PlayerWaveStyle(
    fixedWaveColor: Colors.white54,
    liveWaveColor: Colors.white,
    spacing: 6,
    scaleFactor: 40, // about half the widget height
  );
  static const width = 200.0;
  List<double>? waves;
  late final StreamSubscription<PlayerState> stateSub;

  @override
  void initState() {
    super.initState();
    waves = widget.cachedWaves;
    stateSub = player.onPlayerStateChanged.listen((_) {
      if (mounted) setState(() {});
    });
    _prepare();
  }

  Future<void> _prepare() async {
    await player.preparePlayer(path: widget.path, shouldExtractWaveform: false);
    await player.setFinishMode(finishMode: FinishMode.pause); // allow replay
    if (waves == null) {
      final data = await player.waveformExtraction.extractWaveformData(
        path: widget.path,
        noOfSamples: style.getSamplesForWidth(width),
      );
      if (mounted) setState(() => waves = data); // persist `data` to reuse later
    }
  }

  @override
  void dispose() {
    stateSub.cancel();
    player.dispose(); // stops, releases and cancels extraction
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = player.playerState;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(
        icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
        onPressed: state.isStopped
            ? null
            : () => state.isPlaying ? player.pausePlayer() : player.startPlayer(),
      ),
      if (waves != null)
        AudioFileWaveforms(
          key: ValueKey(widget.path), // waveformData is read once; new key = rebuild
          size: const Size(width, 80),
          playerController: player,
          waveformData: waves!,
          waveformType: WaveformType.fitWidth,
          playerWaveStyle: style,
        ),
    ]);
  }
}
```

- `WaveformType.fitWidth` fits all bars into the width; size `noOfSamples` with `style.getSamplesForWidth(width)` or the end is cut off. `WaveformType.long` (the default) scrolls past a centre seek line.
- `preparePlayer(noOfSamplesPerSecond: n)` extracts n × seconds bars. Pass one of `noOfSamples`/`noOfSamplesPerSecond`, never both; the default is 100.
- Times are `int` milliseconds: `maxDuration`, `onCurrentDurationChanged`, `seekTo(ms)`, `getDuration(...)`. Once the native player is released (e.g. by `FinishMode.stop`), `getDuration` returns `-1` on Android and `0` on iOS/macOS. Set `updateFrequency` before `preparePlayer`.
- On iOS/macOS `seekTo` truncates to whole seconds (`seekTo(2900)` lands at 2 s).
- Use `pauseAllPlayers()` rather than `stopAllPlayers()` (rule 5). On Android, `stopAllPlayers()` also makes a later `preparePlayer` on an existing controller hang forever, so create a new controller. No sound in iOS silent mode: set `overrideAudioSession = true` before `preparePlayer`.
- Extraction decodes the whole file and is slow on Android (a 58-minute file takes about 4 minutes), so cache the result. `stopWaveformExtraction()` cancels it. `dispose()` cancels it too, and so does starting a new extraction on the same controller (including through `preparePlayer`). The cancelled call's `Future` never completes.

### Extraction without a player

```dart
Future<List<double>> wavesFor(String path) async {
  final extractor = WaveformExtractionController();
  return extractor.extractWaveformData(path: path, noOfSamples: 100);
}
```

Use `noOfSamples` here: `noOfSamplesPerSecond` asks a prepared player for the duration, so on a standalone extractor it never completes. Its streams throw `LateInitializationError` until some `PlayerController`/`RecorderController` exists.

## Anti-Patterns

```dart
// ❌ 1.x: record(path: p, androidEncoder: AndroidEncoder.aac, androidOutputFormat: AndroidOutputFormat.mpeg4)
//        (or the same fields set on RecorderController)
// ✅ record(path: p, recorderSettings: const RecorderSettings(
//        androidEncoderSettings: AndroidEncoderSettings(androidEncoder: AndroidEncoder.aacLc)))
// ❌ playerController.extractWaveformData(path: p)   ✅ playerController.waveformExtraction.extractWaveformData(path: p)
// ❌ AudioFileWaveforms(controller: c, tapUpUpdateDetails: f)   ✅ AudioFileWaveforms(playerController: c, onTapUp: f)
// ❌ startPlayer(finishMode: FinishMode.loop)   ✅ await setFinishMode(finishMode: FinishMode.loop); await startPlayer();
// ❌ final bars = c.waveformExtraction.waveformData;   ✅ final bars = await c.waveformExtraction.extractWaveformData(path: p);
// ❌ setFinishMode/getDuration before preparePlayer (hangs)   ✅ await preparePlayer(path: p); then the rest
// ❌ preparePlayer(path: 'assets/a.mp3' | 'https://…' | 'content://…')   ✅ copy/download to a file first
// ❌ on Exception catch (e) around record()   ✅ catch (e): errors can be Strings
```

## Known Limitations & Workarounds

| Need | What happens | Workaround |
| --- | --- | --- |
| Replay after the end | `FinishMode.stop` releases the player | `setFinishMode(.pause)` after prepare, or prepare again on `onCompletion` |
| Recorder plus chat bubbles | Disposing the last bubble's player freezes the recorder | Hold one extra `PlayerController` while the recorder lives |
| Recycled list items | A rebuilt `AudioFileWaveforms` is empty | Cache the `List<double>` and pass `waveformData:` |
| Remote / HLS audio (#54, #443) | Not supported | Download to a file first |
| Flutter asset | Not a file path | `rootBundle.load` → write to a file |
| Background colour | `backgroundColor` on `AudioFileWaveforms`, `WaveStyle` and `PlayerWaveStyle` is unused | `decoration: BoxDecoration(color: ...)` |
| Bars clipped or tiny | Half-height = value × `scaleFactor` (player default 100) | `scaleFactor` ≈ height / 2 |
| Playable file while paused (#208) | Not possible | `stop()`, then record a new file |
| Live duration on Android | `onCurrentDuration`/`elapsedDuration` and duration labels run at 2× the real time (open #476) | Halve it on Android, or use `recordedDuration` after stop |
| Stop while paused on iOS | The next recording gets no waves, chunks or duration until you pause it, and then gets them only while paused | Call `record()` to resume, then `stop()` |
| Live duration on macOS | `onCurrentDuration` never emits, `elapsedDuration` stays zero and duration labels never appear | Run your own timer; use `recordedDuration` after stop |
| Android `stop()` sometimes never returns (open #470, #516) | File may be corrupt | `.timeout(...)` and show an error |
| Cross-OS playback of recordings (open #113, #198) | Can fail | AAC `.m4a`; test both directions |
| Web, Windows, Linux | `MissingPluginException` | Not supported |

Out of scope (say so, don't invent APIs): trimming, editing or merging audio; format conversion; speech-to-text; background playback or lock-screen controls; audio focus; playlists; dB metering; duration labels on `AudioFileWaveforms`; feeding your own PCM to `AudioWaveforms`.

## Testing

Mock the plugin's method channel `simform_audio_waveforms_plugin/methods`. The name is internal, but it is the only seam:

```dart
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // controllers need the binding

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('simform_audio_waveforms_plugin/methods'),
      (call) async => switch (call.method) {
        'getDuration' => 3000,
        'extractWaveformData' => <double>[0.2, 0.5, 0.8],
        'stopRecording' => {'resultFilePath': '/tmp/a.m4a', 'resultDuration': 3000},
        'stopExtraction' || 'finishMode' => null,
        'pauseRecording' => false, // native returns "is still recording"
        _ => true, // preparePlayer, startPlayer, checkPermission, ...
      },
    );
  });

  testWidgets('renders player waveform', (tester) async {
    final player = PlayerController();
    await player.preparePlayer(path: '/tmp/a.m4a', shouldExtractWaveform: false);
    await tester.pumpWidget(MaterialApp(
      home: AudioFileWaveforms(
        size: const Size(200, 50),
        playerController: player,
        waveformData: const [0.2, 0.5, 0.8],
      ),
    ));
    expect(player.playerState, PlayerState.initialized);
    expect(player.maxDuration, 3000);
    await player.startPlayer();
    expect(player.playerState, PlayerState.playing);
    player.dispose();
  });
}
```

Without the binding, creating a controller fails with "Cannot set the method call handler…". Without the mock, calls throw `MissingPluginException`. `record()` branches on `dart:io` `Platform`, so on a Linux or Windows test host it does nothing; recorder tests only exercise the code on a macOS host (iOS/macOS path).

## Symptom → Fix

| Symptom / error | Fix |
| --- | --- |
| `waveThickness can't be greater than spacing` | `spacing` > `waveThickness` (defaults: recorder 8/3, player 5/3) |
| `Cannot provide both noOfSamples and noOfSamplesPerSecond` | Pass only one |
| `Cannot provide both a color and a decoration` (`AudioWaveforms`) | Put the colour in `decoration` and drop `backgroundColor` |
| `LateInitializationError: Field '_extractionProgressController…'` (or `_extractedWaveformDataController`) | Create a `PlayerController` first, or use `player.waveformExtraction` |
| `Cannot set the method call handler before the binary messenger has been initialized` | Create controllers after `runApp`; in tests call `TestWidgetsFlutterBinding.ensureInitialized()` |
| `PlatformException(AudioWaveforms, Failed to prepare player, …2003334207…)` | The path is not a readable local file (asset, URL, `#`/`?` in name) or the format is unsupported. Android reports the same cause as `PlatformException(AudioWaveforms, <ExoPlayer message>, Unable to load media source.)` |
| `Failed to start recording` / `Failed to initialize recorder` (Android: `Error initializing encoder: …`, `Error initializing AudioRecord: …`, `Invalid buffer size`) | Directory missing, or extension/encoder/sampleRate mismatch; Android `opus` needs Android 10 (a denied permission returns silently instead, rule 7) |
| `setFinishMode`/`getDuration` never completes | Called before `preparePlayer` or after `stopAllPlayers()` (on Android `preparePlayer` then hangs too) |
| Play does nothing the second time | Rule 2 |
| `AudioFileWaveforms` shows no bars | Rules 3–4 |
| Recorder waves froze | Rule 5 |
| No waves on iOS | `overrideAudioSession = false` without your own `.playAndRecord` session |
| `seekTo` ignored | Player stopped, or Android below 8.0 |
| `MissingPluginException` | Unsupported platform, or a test without the channel mock |
