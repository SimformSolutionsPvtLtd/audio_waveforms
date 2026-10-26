---
name: audio-waveforms-expert
description: >-
  Expert guidance for the audio_waveforms Flutter package (RecorderController, AudioWaveforms, PlayerController, AudioFileWaveforms, WaveformExtractionController, WaveStyle, PlayerWaveStyle, RecorderSettings). Use when recording audio with a live waveform, playing audio files with a seekable waveform, extracting or caching waveform data, building chat voice-message bubbles, replaying audio after it finishes, or writing tests that mock the plugin. Also use when the waveform is empty or not showing, recorder waves freeze, audio won't play a second time, a spacing/waveThickness assert, "Cannot provide both ..." assert, LateInitializationError, "Failed to prepare player" or "Failed to start recording" appears, or when migrating 1.x code.
---

# audio_waveforms Expert

A Flutter plugin (Android, iOS, and macOS from 2.1.0) that records microphone audio with a live waveform (`RecorderController` + `AudioWaveforms`), plays local audio files with a seekable waveform (`PlayerController` + `AudioFileWaveforms`), and extracts waveform data from files for caching. This skill ships inside the package, so it matches the installed version. If it disagrees with the package source or CHANGELOG.md, trust those and tell the user.

Load these only when needed:

- [references/troubleshooting.md](references/troubleshooting.md): read it when an error or odd behavior appears, and **before building anything that depends on recorder duration, pause/resume, `stop()`, or cross-platform playback**. It holds the per-OS bugs and open issues.
- [references/testing.md](references/testing.md): read it when writing tests that touch a controller.

## Rules

1. **`await preparePlayer(...)` first.** It creates the native player. Before it, `startPlayer`/`seekTo` silently do nothing, and `setFinishMode`, `getDuration`, `setVolume` and `setRate` return a `Future` that **never completes**. So does the native release inside `dispose()`, so disposing a never-prepared controller never finishes its cleanup.
2. **The default `FinishMode.stop` releases the player when the audio ends**, so `startPlayer()` then does nothing. To allow replay, call `setFinishMode(finishMode: FinishMode.pause)` (or `.loop`) after `preparePlayer`, or prepare again.
3. **Never read `controller.waveformExtraction.waveformData`.** It returns a copy that is always empty. Use the list returned by `extractWaveformData(...)`. `AudioFileWaveforms(continuousWaveform: false)` therefore draws nothing unless you pass `waveformData:`.
4. **Widgets capture some arguments once, in `initState`.** `AudioWaveforms` ignores later changes to `size`, `waveStyle` and `recorderController`; `AudioFileWaveforms` ignores later changes to `waveformData` and `continuousWaveform`, and keeps listening to the original `playerController`. Use a new `key` to apply them. An `AudioFileWaveforms` built *after* extraction finished (ListView recycling, tab switch) is empty, so cache the data and pass `waveformData:`.
5. **Don't dispose the last `PlayerController` while a `RecorderController` is in use.** A recorder on its own is fine, but disposing the last player, or calling `stopAllPlayers()`, closes the shared streams. The live recorder stops getting waves, and existing players stop getting position and state events. In a chat, hold one extra `PlayerController` while the recorder lives.
6. **Use local file paths only.** Copy Flutter assets to a file (`rootBundle.load`, then write) and download remote audio first (iOS/macOS cannot open URLs). Android `content://` URIs are not supported. `preparePlayer` parses the path as a URI: it strips `file://`, and a `#` or `?` in the name truncates the path. It also percent-encodes spaces and non-ASCII characters (`/a b.m4a` becomes `/a%20b.m4a`); the native side decodes that, so don't "fix" it.
7. **When permission is denied, `record()` returns without error** and the state stays `stopped`, so check `hasPermission`. Failures arrive either as a thrown `String` ("Failed to start recording") or as a `PlatformException`, so use `catch (e)`, not `on Exception catch`.
8. **Pass `record(path:)` with an extension that matches the encoder** (`.m4a` for AAC, `.wav` for WAV/LinearPCM). Without a path the file is a date-named `.m4a` whatever the encoder, in the cache dir on Android and the documents dir on iOS/macOS.
9. **`spacing` must be greater than `waveThickness`** in `WaveStyle` and `PlayerWaveStyle`. `PlayerWaveStyle(spacing: 3)` asserts because the default thickness is 3.
10. **Use the 2.x names** (see [1.x → 2.x](#1x--2x-migration)). `startPlayer` has no `finishMode` parameter. Don't invent APIs for the limitations in `references/troubleshooting.md`.

## Setup

- Add the dependency with `flutter pub add audio_waveforms` and never hard-code a version. Import only `package:audio_waveforms/audio_waveforms.dart`.
- Android: `<uses-permission android:name="android.permission.RECORD_AUDIO" />`, and `minSdkVersion 23` (the recorder needs API 23; below API 26 `seekTo` does nothing and its `Future` never completes).
- iOS: `NSMicrophoneUsageDescription` in `Info.plist`, `platform :ios, '13.0'` in the Podfile (the minimum in the package docs; the podspec itself declares 8.0).
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
        final path =
            await recorder.stop(); // clears waves; stop(false) keeps them
        if (path != null) widget.onDone(path);
      } else {
        await recorder.record(
          path:
              '${widget.dirPath}/${DateTime.now().millisecondsSinceEpoch}.m4a',
        );
        if (!recorder.hasPermission && mounted) {
          // Permission denied: record() returned without recording.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission is required')),
          );
        }
      }
    } catch (e) {
      debugPrint('Recorder error: $e'); // a String or a PlatformException
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    recorder
        .dispose(); // stops recording but the file path is lost; stop() first
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
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
            color:
                Colors.black87, // use decoration OR backgroundColor, never both
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        IconButton(
          icon: Icon(recorder.isRecording ? Icons.stop : Icons.mic),
          onPressed: _toggle,
        ),
      ],
    );
  }
}
```

- `pause()` then `record()` resumes the same file. `reset()` clears the bars. `refresh()` jumps back to live after a drag.
- `waveData` values are 0–1; bar half-height = value × `WaveStyle.scaleFactor` (default 20).
- Streams: `onRecorderStateChanged`, `onCurrentDuration`, `onRecordingEnded`, `onAudioChunks` (raw `Uint8List`: 16-bit signed little-endian mono PCM at `sampleRate` on Android; Float32 samples at the hardware rate on iOS; Float32 at `sampleRate` on macOS). After `stop()`, `recordedDuration` holds the file length.
- `waveformRenderMode: WaveformRenderMode.rtl` draws from the right; `extendWaveform` is ignored there. `showDurationLabel: true` adds labels; raise `extraClipperHeight` if they are clipped.
- `backgroundColor` on `AudioFileWaveforms`, `WaveStyle` and `PlayerWaveStyle` is unused; use `decoration: BoxDecoration(color: ...)`.
- iOS `overrideAudioSession` (default `true`) sets `.playAndRecord`. If you set it to `false` without configuring the session yourself, you get no audio and no waves.

### Encoders (WAV example)

```dart
Future<void> recordWav(RecorderController recorder, String dirPath) {
  return recorder.record(
    path: '$dirPath/clip.wav', // extension must match the encoder
    recorderSettings: const RecorderSettings(
      sampleRate: 44100,
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
  static final samples = style.getSamplesForWidth(width) - 1; // see below
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
    if (!mounted) return; // dispose() already released the player
    await player.setFinishMode(finishMode: FinishMode.pause); // allow replay
    if (!mounted || waves != null) return;
    final data = await player.waveformExtraction.extractWaveformData(
      path: widget.path,
      noOfSamples: samples,
    );
    if (mounted) setState(() => waves = data); // persist `data` to reuse later
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: state.isStopped
              ? null
              : () =>
                  state.isPlaying ? player.pausePlayer() : player.startPlayer(),
        ),
        // Built only once the data is ready: waveformData is read once.
        if (waves != null)
          AudioFileWaveforms(
            size: const Size(width, 80),
            playerController: player,
            waveformData: waves!,
            waveformType: WaveformType.fitWidth,
            playerWaveStyle: style,
          ),
      ],
    );
  }
}
```

- The example prepares once in `initState`. In a list, give each item `key: ValueKey(path)` so a different path gets a fresh `State`.
- `WaveformType.fitWidth` fits all bars into the width; size `noOfSamples` with `style.getSamplesForWidth(width) - 1`. `getSamplesForWidth` alone returns one bar too many: the painter skips the last bar when `width` is a multiple of `spacing` and otherwise draws it at the very edge. `WaveformType.long` (the default) scrolls past a centre seek line.
- `preparePlayer(noOfSamplesPerSecond: n)` extracts n × seconds bars. Pass one of `noOfSamples`/`noOfSamplesPerSecond`, never both; the default is 100.
- Times are `int` milliseconds: `maxDuration`, `onCurrentDurationChanged`, `seekTo(ms)`, `getDuration(...)`. Once the native player is released (e.g. by `FinishMode.stop`), `getDuration` returns `-1` on Android and `0` on iOS/macOS. Set `updateFrequency` before `preparePlayer`.
- On iOS/macOS `seekTo` truncates to whole seconds (`seekTo(2900)` lands at 2 s).
- Use `pauseAllPlayers()` rather than `stopAllPlayers()` (rule 5). On Android, `stopAllPlayers()` also makes a later `preparePlayer` on an existing controller hang forever, so create a new controller. No sound in iOS silent mode: set `overrideAudioSession = true` before `preparePlayer`.
- Extraction decodes the whole file and is slow on Android (a 58-minute file takes about 4 minutes), so cache the result. `stopWaveformExtraction()` cancels it. `dispose()` cancels it too, and so does starting a new extraction on the same controller (including through `preparePlayer`). The cancelled call's `Future` never completes, so queue extractions instead of overlapping them.

### Extraction without a player

```dart
Future<List<double>> wavesFor(String path) async {
  final extractor = WaveformExtractionController();
  return extractor.extractWaveformData(path: path, noOfSamples: 100);
}
```

Use `noOfSamples` here: `noOfSamplesPerSecond` asks a prepared player for the duration, so on a standalone extractor it never completes. Its streams throw `LateInitializationError` until some `PlayerController`/`RecorderController` exists.

## 1.x → 2.x migration

```dart
// ❌ 1.x: record(path: p, androidEncoder: AndroidEncoder.aac, androidOutputFormat: AndroidOutputFormat.mpeg4)
//        (or the same fields set on RecorderController)
// ✅ record(path: p, recorderSettings: const RecorderSettings(
//        androidEncoderSettings: AndroidEncoderSettings(androidEncoder: AndroidEncoder.aacLc)))
// ❌ playerController.extractWaveformData(path: p)   ✅ playerController.waveformExtraction.extractWaveformData(path: p)
// ❌ AudioFileWaveforms(controller: c, tapUpUpdateDetails: f)   ✅ AudioFileWaveforms(playerController: c, onTapUp: f)
// ❌ startPlayer(finishMode: FinishMode.loop)   ✅ await setFinishMode(finishMode: FinishMode.loop); await startPlayer();
```

## Out of scope

Say so instead of inventing APIs: trimming, editing or merging audio; format conversion; speech-to-text; background playback or lock-screen controls; audio focus; playlists; dB metering; duration labels on `AudioFileWaveforms`; feeding your own PCM to `AudioWaveforms`; Web, Windows and Linux (`MissingPluginException`).
