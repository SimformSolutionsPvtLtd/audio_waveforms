# Overview

A Flutter package that allows you to generate waveforms while recording audio in any file format supported by given encoders or from audio files. You can use gestures to scroll through the waveforms or seek any position while playing audio and style waveforms.

## Preview

![The example app running on mobile](https://raw.githubusercontent.com/SimformSolutionsPvtLtd/audio_waveforms/main/preview/demo_v2_0_0.gif)

## Features

- Generate waveforms while recording audio.
- Generate waveforms from audio files.
- Record audio with customizable encoders and output formats.
- Play audio files with waveform visualization.
- Scroll through waveforms using gestures.
- Seek to any position in audio playback.
- Customize waveform appearance (colors, gradients, thickness, spacing).
- Real-time waveform updates during recording and playback.
- Extract waveform data for caching and reuse.
- Support for multiple audio formats.
- Duration labels and seek line customization.

## Key Components

- **RecorderController**: Manages audio recording operations and provides recording waveform data.
- **PlayerController**: Manages audio playback operations and provides playback waveform data.
- **WaveformExtractionController**: Extracts waveform data from audio files without player dependency.
- **AudioWaveforms**: A widget that displays waveforms during recording.
- **AudioFileWaveforms**: A widget that displays waveforms for audio file playback.
- **WaveStyle**: Customization options for recording waveforms.
- **PlayerWaveStyle**: Customization options for playback waveforms.

## Installation

```yaml
dependencies:
  audio_waveforms: <latest-version>
```

## Basic Implementation

### Recording Audio

```dart
// Import the package
import 'package:audio_waveforms/audio_waveforms.dart';

// Create a recorder controller
final recorderController = RecorderController();

// Check permissions
await recorderController.checkPermission();

// Start recording
if (recorderController.hasPermission) {
  await recorderController.record();
}

// Display waveforms
AudioWaveforms(
  controller: recorderController,
  size: Size(300, 50),
)

// Stop recording
String? path = await recorderController.stop();

// Dispose the controller
recorderController.dispose();
```

### Playing Audio

```dart
// Create a player controller
final playerController = PlayerController();

// Prepare the player
await playerController.preparePlayer(
  path: 'path/to/audio.mp3',
  shouldExtractWaveform: true,
);

// Start playing
await playerController.startPlayer();

// Display waveforms
AudioFileWaveforms(
  controller: playerController,
  size: Size(300, 50),
)

// Stop playing
await playerController.stopPlayer();

// Dispose the controller
playerController.dispose();
```

## Customizations

The package offers extensive customization options for:
- Waveform colors and gradients.
- Wave thickness and spacing.
- Show/hide top and bottom waves.
- Middle line and seek line appearance.
- Duration labels and formatting.
- Gesture controls for seeking.
- Recording encoders and output formats.
- Playback rate and volume control.
- Waveform scaling and scrolling effects.
- Background colors and transparency.

# Installation

To use the Audio Waveforms package in your Flutter project, follow these steps:

## 1. Add dependency to `pubspec.yaml`

Add the following dependency to your project's `pubspec.yaml` file:

```yaml
dependencies:
  audio_waveforms: <latest-version>
```

## 2. Install packages

Run the following command to install the package:

```bash
flutter pub get
```

## 3. Platform-specific Setup

### Android Setup

#### Update minimum SDK version

Change the minimum Android SDK version to 23 (or higher) in your `android/app/build.gradle` file:

```gradle
minSdkVersion 23
```

#### Add permissions

Add RECORD_AUDIO permission in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

### iOS Setup

#### Add microphone usage description

Add description to your microphone usage in `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app requires microphone access to record audio.</string>
```

#### Set minimum iOS version

This plugin requires iOS 13.0 or higher. Add this line to your `Podfile`:

```ruby
platform :ios, '13.0'
```

### macOS Setup

#### Add microphone usage description

Add description to your microphone usage in `macos/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app requires microphone access to record audio.</string>
```

#### Enable macOS desktop support

Enable macOS desktop support for your Flutter project:

```bash
flutter config --enable-macos-desktop
flutter create --platforms=macos .
```

#### Set minimum macOS version

This plugin requires macOS 10.14 or higher. Add this line to your `macos/Podfile`:

```ruby
platform :osx, '10.14'
```

#### macOS-Specific Implementation Notes

On macOS, the audio recording implementation differs from iOS due to platform limitations:

- **No AVAudioSession coordination**: macOS lacks the AVAudioSession layer that iOS uses to coordinate audio resources between apps.
- **AVAudioEngine conflict**: AVAudioEngine and AVAudioRecorder cannot both access the microphone simultaneously on macOS, causing resource conflicts.
- **Waveform generation**: Instead of real-time byte streaming, waveforms are generated through periodic polling of decibel levels every 50ms using the `getDecibel()` method.
- **Same API surface**: Despite these implementation differences, the public API remains identical across all platforms.

These implementation details are handled automatically by the plugin, requiring no changes to your application code.

## 4. Import the package

Add the import statement in your Dart files where you want to use Audio Waveforms:

```dart
import 'package:audio_waveforms/audio_waveforms.dart';
```

## 5. Clean and rebuild

Make sure to delete the app from your device and perform:

```bash
flutter clean
flutter pub get
```

Now you're ready to use Audio Waveforms in your Flutter application!

# Basic Usage - Recorder

This guide covers the fundamental implementation of audio recording with waveforms in your Flutter application.

## Setup RecorderController

First, create an instance of `RecorderController`:

```dart
final recorderController = RecorderController();
```

## Check Permissions

Before recording, check if the app has microphone permission:

```dart
@override
void initState() {
  super.initState();
  recorderController.checkPermission();
}
```

You can check permission status using:

```dart
if (recorderController.hasPermission) {
  // Permission granted
}
```

## Start Recording

Start recording audio with default settings:

```dart
await recorderController.record();
```

By default, this saves the file with the current date and time as the filename with `.m4a` extension.

### Recording with custom path

```dart
await recorderController.record(path: '/path/to/myFile.m4a');
```

## Pause Recording

Pause the current recording:

```dart
await recorderController.pause();
```

To resume recording, simply call `record()` again.

## Stop Recording

Stop the recording and get the file path:

```dart
String? path = await recorderController.stop();
```

You can also specify whether to clear waveforms after stopping:

```dart
String? path = await recorderController.stop(false); // Don't clear waveforms
```

## Display Waveforms

Add the `AudioWaveforms` widget to display recording waveforms:

```dart
AudioWaveforms(
  controller: recorderController,
  size: Size(300, 50),
)
```

## Reset Waveforms

Clear waveforms and duration legends:

```dart
recorderController.reset();
```

## Refresh Waveforms

Move waveforms back to original position if they have been scrolled:

```dart
recorderController.refresh();
```

## Dispose Controller

Always dispose the controller when done:

```dart
@override
void dispose() {
  recorderController.dispose();
  super.dispose();
}
```

## Complete Example

Here's a complete basic recording example:

```dart
import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

class RecorderScreen extends StatefulWidget {
  const RecorderScreen({Key? key}) : super(key: key);

  @override
  State<RecorderScreen> createState() => _RecorderScreenState();
}

class _RecorderScreenState extends State<RecorderScreen> {
  late final RecorderController recorderController;
  String? recordedFilePath;

  @override
  void initState() {
    super.initState();
    recorderController = RecorderController();
    recorderController.checkPermission();
  }

  @override
  void dispose() {
    recorderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Recorder')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AudioWaveforms(
              controller: recorderController,
              size: Size(MediaQuery.of(context).size.width - 32, 80),
              waveStyle: WaveStyle(
                waveColor: Colors.blue,
                showMiddleLine: true,
                middleLineColor: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    if (recorderController.hasPermission) {
                      await recorderController.record();
                    }
                  },
                  child: const Text('Record'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    await recorderController.pause();
                  },
                  child: const Text('Pause'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    if (recorderController.isRecording) {
                      recordedFilePath = await recorderController.stop();
                      print('Recorded file path: $recordedFilePath');
                    }
                  },
                  child: const Text('Stop'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

# Basic Usage - Player

This guide covers the fundamental implementation of audio playback with waveforms in your Flutter application.

## Setup PlayerController

First, create an instance of `PlayerController`:

```dart
final playerController = PlayerController();
```

## Prepare Player

Before playing, prepare the player with an audio file:
```dart
await playerController.preparePlayer(
  path: '/path/to/audio.mp3',
  shouldExtractWaveform: true,
);
```

Setting `shouldExtractWaveform` to `true` will automatically extract waveform data from the audio file.

### Configuring Waveform Sample Count

You can control waveform granularity using either:

**Fixed sample count:**
```dart
await playerController.preparePlayer(
  path: '/path/to/audio.mp3',
  shouldExtractWaveform: true,
  noOfSamples: 200, // Exactly 200 waveform bars
);
```

**Samples per second (dynamic):**
```dart
await playerController.preparePlayer(
  path: '/path/to/audio.mp3',
  shouldExtractWaveform: true,
  noOfSamplesPerSecond: 10, // 10 samples per second of audio
);
```

**Important**: Use only ONE of `noOfSamples` OR `noOfSamplesPerSecond`. If both are null, defaults to 100 samples. See the [Waveform Extraction Controller](#waveform-extraction-controller) section for detailed explanation of both approaches.

### Loading from Assets

To load audio from assets, first copy it to a temporary location:

```dart
import 'package:flutter/services.dart';
import 'dart:io';

final audioFile = await rootBundle.load('assets/audio.mp3');
final file = File('${appDirectory.path}/audio.mp3');
await file.writeAsBytes(audioFile.buffer.asUint8List());

await playerController.preparePlayer(
  path: file.path,
  shouldExtractWaveform: true,
);
```

### Loading from Device Storage

When loading from device storage, directly provide the file path:

```dart
await playerController.preparePlayer(
  path: '/storage/emulated/0/audio.mp3',
  shouldExtractWaveform: true,
);
```

### Loading from Network

Currently, playing remote audio files directly isn't supported. You will need to download the file
first, then play it locally.

## Start Playing

Start playing the audio:

```dart
await playerController.startPlayer();
```

You can also specify if the player should finish the current audio before starting new one:

```dart
await playerController.startPlayer(finishMode: FinishMode.loop);
```

## Pause Playing

Pause the current playback:

```dart
await playerController.pausePlayer();
```

## Stop Playing

Stop the player and release resources:

```dart
await playerController.stopPlayer();
```

## Display Waveforms

Add the `AudioFileWaveforms` widget to display playback waveforms:

```dart
AudioFileWaveforms(
  controller: playerController,
  size: Size(300, 50),
)
```

## Release Resources

Release native player resources:

```dart
await playerController.release();
```

## Dispose Controller

Always dispose the controller when done:

```dart
@override
void dispose() {
  playerController.dispose();
  super.dispose();
}
```

## Complete Example

Here's a complete basic playback example:

```dart
import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

class PlayerScreen extends StatefulWidget {
  final String audioPath;
  
  const PlayerScreen({Key? key, required this.audioPath}) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final PlayerController playerController;

  @override
  void initState() {
    super.initState();
    playerController = PlayerController();
    _preparePlayer();
  }

  void _preparePlayer() async {
    await playerController.preparePlayer(
      path: widget.audioPath,
      shouldExtractWaveform: true,
    );
  }

  @override
  void dispose() {
    playerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Player')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AudioFileWaveforms(
              controller: playerController,
              size: Size(MediaQuery.of(context).size.width - 32, 80),
              playerWaveStyle: PlayerWaveStyle(
                fixedWaveColor: Colors.grey,
                liveWaveColor: Colors.blue,
                showSeekLine: true,
                seekLineColor: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await playerController.startPlayer();
                  },
                  child: const Text('Play'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    await playerController.pausePlayer();
                  },
                  child: const Text('Pause'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    await playerController.stopPlayer();
                  },
                  child: const Text('Stop'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

# Advanced Usage - Recorder

This guide covers advanced features and customizations of the audio recorder.

## Custom Encoders and Output Formats

Specify custom encoders and output formats for different platforms:

```dart
await recorderController.record(
  recorderSettings: const RecorderSettings(
    sampleRate: 44100,
    bitRate: 128000,
    iosEncoderSetting: IosEncoderSetting(
      iosEncoder: IosEncoder.kAudioFormatMPEG4AAC,
      linearPCMBitDepth: null, // supported values: 8, 16, 24, 32
      linearPCMIsBigEndian: null,
      linearPCMIsFloat: null,
    ),
    androidEncoderSettings: AndroidEncoderSettings(
      androidEncoder: AndroidEncoder.aacLc,
    ),
  ),
);
```

### Available iOS Encoders

- `IosEncoder.kAudioFormatMPEG4AAC`       - AAC (default, supports .m4a)
- `IosEncoder.kAudioFormatLinearPCM`      - Linear PCM (supports .wav)
- `IosEncoder.kAudioFormatMPEG4AAC`       - AAC
- `IosEncoder.kAudioFormatMPEGLayer1`     - MP3 Layer 1
- `IosEncoder.kAudioFormatMPEGLayer2`     - MP3 Layer 2
- `IosEncoder.kAudioFormatMPEGLayer3`     - MP3 Layer 3
- `IosEncoder.kAudioFormatMPEG4AAC_ELD`   - AAC ELD
- `IosEncoder.kAudioFormatMPEG4AAC_HE`    - AAC HE
- `IosEncoder.kAudioFormatOpus`           - Opus
- `IosEncoder.kAudioFormatAMR`            - AMR-NB
- `IosEncoder.kAudioFormatAMR_WB`         - AMR-WB
- `IosEncoder.kAudioFormatAppleLossless`  - Apple Lossless
- `IosEncoder.kAudioFormatMPEG4AAC_HE_V`  - AAC HE V2

### Available Android Encoders


- `AndroidEncoder.aacLc`  - AAC LC (default)
- `AndroidEncoder.aacHe`  - AAC HE
- `AndroidEncoder.aacEld` - AAC ELD
- `AndroidEncoder.amrNb`  - AMR-NB
- `AndroidEncoder.amrWb`  - AMR-WB
- `AndroidEncoder.wav`    - WAV
- `AndroidEncoder.opus`   - Opus


**Important**: Ensure your file extension, sample rate, and bit rate are compatible with chosen 
encoder.

## Override Audio Session (iOS)

Control whether the plugin should override iOS audio session settings:

```dart
recorderController.overrideAudioSession = false;
```

When set to `false`, you're responsible for configuring the audio session. The plugin won't interfere with other apps or previously set audio sessions.

## Listening to Recording Events

### Current Duration Stream

Get the current recording duration (updates every 50ms):

```dart
recorderController.onCurrentDuration.listen((duration) {
  print('Current duration: ${duration.inSeconds}s');
});
```

### Recorder State Stream

Listen to recorder state changes:

```dart
recorderController.onRecorderStateChanged.listen((state) {
  switch (state) {
    case RecorderState.initialized:
      print('Initialised...');
      break;  
    case RecorderState.recording:
      print('Recording...');
      break;
    case RecorderState.paused:
      print('Paused');
      break;
    case RecorderState.stopped:
      print('Stopped');
      break;
  }
});
```

### Recording Ended Stream

Get the final duration when recording ends:

```dart
recorderController.onRecordingEnded.listen((duration) {
  print('Recording ended. Total duration: ${duration.inSeconds}s');
});
```

### Audio Chunk Stream

Get real-time audio chunks during recording:

```dart
recorderController.onAudioChunk.listen((chunk) {
  print('Received audio chunk of size: ${chunk.length} bytes');
});
```

## Scrolled Duration

Track the scrolled position of waveforms:

```dart
recorderController.currentScrolledDuration.addListener(() {
  final scrolledMs = recorderController.currentScrolledDuration.value;
  print('Scrolled to: ${scrolledMs}ms');
});
```

**Note**: Enable `shouldCalculateScrolledPosition` in the `AudioWaveforms` widget to use this feature.

## Accessing Recording Data

### Waveform Data

Get the normalized waveform data:

```dart
List<double> waveData = recorderController.waveData;
```

Values are between 0.0 and 1.0, representing normalized peak power (iOS) or amplitude (Android).

### Duration Information

```dart
// Current elapsed duration during recording
Duration elapsed = recorderController.elapsedDuration;

// Total recorded duration after stopping
Duration recorded = recorderController.recordedDuration;
```

### Permission Status

```dart
bool hasPermission = recorderController.hasPermission;
```

### Recording State

```dart
bool isRecording = recorderController.isRecording;
RecorderState state = recorderController.recorderState;
```

## Advanced Waveform Styling

Customize the appearance of recording waveforms:

```dart
AudioWaveforms(
  controller: recorderController,
  size: Size(MediaQuery.of(context).size.width, 100),
  shouldCalculateScrolledPosition: true,
  enableGesture: true,
  waveStyle: WaveStyle(
    waveColor: Colors.blue,
    showMiddleLine: true,
    middleLineColor: Colors.red,
    middleLineThickness: 2.0,
    waveThickness: 4.0,
    spacing: 6.0,
    showTop: true,
    showBottom: true,
    extendWaveform: true,
    showDurationLabel: true,
    durationStyle: TextStyle(
      color: Colors.white,
      fontSize: 12,
    ),
    durationLinesColor: Colors.grey,
    durationLinesHeight: 4.0,
    labelSpacing: 8.0,
    backgroundColor: Colors.black,
    scaleFactor: 20.0,
  ),
)
```

## Waveform Gradients

Apply gradients to waveforms:

```dart
import 'dart:ui' as ui;

AudioWaveforms(
  controller: recorderController,
  size: Size(300, 100),
  waveStyle: WaveStyle(
    gradient: ui.Gradient.linear(
      const Offset(0, 50),
      const Offset(300, 50),
      [Colors.blue, Colors.purple, Colors.pink],
    ),
  ),
)
```

## Duration Labels

Show duration labels with customization:

```dart
AudioWaveforms(
  controller: recorderController,
  size: Size(300, 150),
  waveStyle: WaveStyle(
    showDurationLabel: true,
    showHourInDuration: true, // Show HH:MM:SS instead of MM:SS
    durationStyle: TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    ),
    durationLinesColor: Colors.white.withOpacity(0.5),
    durationLinesHeight: 5.0,
    labelSpacing: 12.0,
    durationTextPadding: 5.0,
  ),
)
```

## Enable/Disable Gestures

Control gesture support for scrolling waveforms:

```dart
AudioWaveforms(
  controller: recorderController,
  size: Size(300, 80),
  enableGesture: true, // Enable scrolling
  shouldCalculateScrolledPosition: true, // Track scroll position
)
```

# Advanced Usage - Player

This guide covers advanced features and customizations of the audio player.

## Waveform Types

### FitWidth Waveforms

Display the entire audio waveform fitted within the widget width:

```dart
AudioFileWaveforms(
  controller: playerController,
  size: Size(300, 80),
  waveformType: WaveformType.fitWidth,
)
```

With `fitWidth`:
- The entire audio duration fits in the specified width
- Seek using **tap** and **drag** gestures
- Provide appropriate sample count for better quality

**Calculate samples for width:**

```dart
final style = PlayerWaveStyle(spacing: 5);
final samples = style.getSamplesForWidth(MediaQuery.of(context).size.width);

await playerController.preparePlayer(
  path: audioPath,
  shouldExtractWaveform: true,
  noOfSamples: samples,
);
```

### Long Waveforms

Display waveforms that extend beyond the widget bounds:

```dart
AudioFileWaveforms(
  controller: playerController,
  size: Size(300, 80),
  waveformType: WaveformType.long,
)
```

With `long`:
- Waveforms extend outside widget bounds
- Completed part appears on the left, remaining on the right
- Seek using **drag** gesture
- Middle seek line shows current position

## Volume Control

Set the playback volume (0.0 to 1.0):

```dart
await playerController.setVolume(0.8); // 80% volume
```

## Playback Rate

Adjust the playback speed:

```dart
await playerController.setRate(1.5); // 1.5x speed
```

Values less than 1.0 slow down playback, values greater than 1.0 speed it up.

## Seek to Position

Jump to a specific position in milliseconds:

```dart
await playerController.seekTo(30000); // Seek to 30 seconds
```

## Finish Mode

Control player behavior when audio finishes:

```dart
// Loop the audio
await playerController.setFinishMode(finishMode: FinishMode.loop);

// Pause at the beginning
await playerController.setFinishMode(finishMode: FinishMode.pause);

// Stop and release resources
await playerController.setFinishMode(finishMode: FinishMode.stop);
```

## Update Frequency

Control how frequently the playback position updates:

```dart
// Smooth but more resource-intensive (updates every 50ms)
playerController.updateFrequency = UpdateFrequency.high;

// Balanced (updates every 100ms)
playerController.updateFrequency = UpdateFrequency.medium;

// Less smooth but lighter (updates every 200ms)
playerController.updateFrequency = UpdateFrequency.low;
```

Higher frequency provides smoother seek animations but may impact performance on low-end devices.

## Override Audio Session (iOS)

Configure iOS audio session settings:

```dart
playerController.overrideAudioSession = true;
```

When set to `true`, the plugin will configure the audio session with appropriate settings for playback.

## Get Audio Duration

Retrieve maximum or current duration:

```dart
// Get total audio duration
final maxDuration = await playerController.getDuration(DurationType.max);
print('Total duration: ${maxDuration}ms');

// Get current playback position
final currentDuration = await playerController.getDuration(DurationType.current);
print('Current position: ${currentDuration}ms');
```

You can also access max duration directly:

```dart
int maxDuration = playerController.maxDuration; // in milliseconds
```

## Listening to Player Events

### Player State Stream

Listen to player state changes:

```dart
playerController.onPlayerStateChanged.listen((state) {
  switch (state) {
    case PlayerState.playing:
      print('Playing...');
      break;
    case PlayerState.paused:
      print('Paused');
      break;
    case PlayerState.stopped:
      print('Stopped');
      break;
  }
});
```

### Current Duration Stream

Get real-time playback position updates:

```dart
playerController.onCurrentDurationChanged.listen((durationMs) {
  final seconds = durationMs ~/ 1000;
  print('Current position: ${seconds}s');
});
```

### Completion Stream

Get notified when audio finishes playing:

```dart
playerController.onCompletion.listen((_) {
  print('Playback completed');
});
```

## Precalculate Waveforms

Extract and cache waveform data for better performance:

```dart
// Extract waveform data
final waveformData = await playerController.waveformExtraction
    .extractWaveformData(
  path: audioPath,
  noOfSamples: 100,
);

// Save waveformData to local storage/database

// Later, use the cached data
AudioFileWaveforms(
  controller: playerController,
  size: Size(300, 80),
  waveformData: waveformData, // Use precalculated data
)
```

### Listen to Extraction Progress

```dart
// Listen to extraction progress
playerController.waveformExtraction.onExtractionProgress.listen((progress) {
  print('Extraction progress: ${progress * 100}%');
});

// Listen to extracted waveform data
playerController.waveformExtraction.onCurrentExtractedWaveformData
    .listen((data) {
  print('Extracted ${data.length} samples so far');
});
```

### Stop Waveform Extraction

```dart
// Start extraction
playerController.waveformExtraction.extractWaveformData(path: audioPath);

// Stop extraction if needed
playerController.waveformExtraction.stopWaveformExtraction();
```

**Note**: Calling `preparePlayer()` automatically stops previous extractions.

## Continuous Waveform

Control when waveforms are displayed during extraction:

```dart
AudioFileWaveforms(
  controller: playerController,
  size: Size(300, 80),
  continuousWaveform: true, // Show waveforms as they're extracted
)
```

- `true`: Shows waveforms progressively as data is extracted
- `false`: Shows waveforms only after complete extraction

## Advanced Waveform Styling

Customize the appearance of playback waveforms:

```dart
AudioFileWaveforms(
  controller: playerController,
  size: Size(MediaQuery.of(context).size.width, 100),
  playerWaveStyle: PlayerWaveStyle(
    fixedWaveColor: Colors.grey,
    liveWaveColor: Colors.blue,
    seekLineColor: Colors.red,
    seekLineThickness: 3.0,
    waveThickness: 4.0,
    spacing: 6.0,
    showTop: true,
    showBottom: true,
    showSeekLine: true,
    backgroundColor: Colors.black,
    scaleFactor: 100.0,
    scrollScale: 1.2, // Scale waves when scrolling
  ),
)
```

## Waveform Gradients

Apply gradients to playback waveforms:

```dart
import 'dart:ui' as ui;

AudioFileWaveforms(
  controller: playerController,
  size: Size(300, 100),
  playerWaveStyle: PlayerWaveStyle(
    fixedWaveGradient: ui.Gradient.linear(
      const Offset(0, 0),
      const Offset(300, 0),
      [Colors.grey, Colors.grey.shade400],
    ),
    liveWaveGradient: ui.Gradient.linear(
      const Offset(0, 0),
      const Offset(300, 0),
      [Colors.blue, Colors.purple, Colors.pink],
    ),
  ),
)
```

## Scroll Scale Effect

Add visual feedback when scrolling waveforms:

```dart
AudioFileWaveforms(
  controller: playerController,
  size: Size(300, 80),
  playerWaveStyle: PlayerWaveStyle(
    scrollScale: 1.3, // Scales waves by 30% when scrolling
  ),
)
```

Waves return to original size when scrolling ends.

## Gesture Callbacks

Get notified about user interactions with waveforms:

```dart
AudioFileWaveforms(
  controller: playerController,
  size: Size(300, 80),
  onTapUp: (details) {
    print('Tapped at: ${details.localPosition}');
  },
)
```

## Control Multiple Players

### Stop All Players

Stop all active players at once:

```dart
await playerController.stopAllPlayers();
```

### Pause All Players

Pause all active players at once:

```dart
await playerController.pauseAllPlayers();
```

These methods work across all `PlayerController` instances in your app.

# Waveform Extraction Controller

This guide covers using `WaveformExtractionController` independently for extracting waveform data without a player.

## Overview

`WaveformExtractionController` allows you to extract waveform data from audio files without needing a `PlayerController`. This is useful when you only need waveform visualization without playback functionality.

## Creating a Controller

```dart
final waveformExtraction = WaveformExtractionController();
```

## Extract Waveform Data

Extract waveform data from an audio file using one of two sampling strategies:

### Option 1: Fixed Sample Count

Specify an exact number of waveform samples:

```dart
final waveformData = await waveformExtraction.extractWaveformData(
  path: '/path/to/audio.mp3',
  noOfSamples: 200, // Exactly 200 data points
);
```

### Option 2: Samples Per Second (Dynamic)

Automatically calculate samples based on audio duration:

```dart
final waveformData = await waveformExtraction.extractWaveformData(
  path: '/path/to/audio.mp3',
  noOfSamplesPerSecond: 10, // 10 samples per second of audio
);
```

**How it works**: The total number of samples is calculated as `noOfSamplesPerSecond × audioDurationInSeconds`.

For example:
- A 30-second audio with `noOfSamplesPerSecond: 10` → 300 samples
- A 2-minute audio with `noOfSamplesPerSecond: 5` → 600 samples

**When to use each approach**:
- **Fixed count** (`noOfSamples`): When you want a specific number of bars regardless of audio length
- **Per second** (`noOfSamplesPerSecond`): When you want consistent waveform density across different audio durations

### Parameters

- `path` (required): Path to the audio file (local or network URL)
- `noOfSamples` (optional): Fixed number of samples to extract
- `noOfSamplesPerSecond` (optional): Samples per second for dynamic calculation

**Important**: 
- Provide only ONE of `noOfSamples` OR `noOfSamplesPerSecond`, not both
- If both are null, defaults to `noOfSamples = 100`
- Both `PlayerController` and `WaveformExtractionController` support these parameters

## Using Extracted Data

Use the extracted waveform data directly in `AudioFileWaveforms`:

```dart
AudioFileWaveforms(
  size: Size(300, 80),
  controller: playerController,
  waveformData: waveformData,
  playerWaveStyle: PlayerWaveStyle(
    fixedWaveColor: Colors.blue,
  ),
)
```

## Listen to Extraction Events

### Extraction Progress

Monitor the extraction progress:

```dart
waveformExtraction.onExtractionProgress.listen((progress) {
  // progress is a double between 0.0 and 1.0
  print('Extraction progress: ${(progress * 100).toInt()}%');
  
  // Update UI
  setState(() {
    extractionProgress = progress;
  });
});
```

### Current Extracted Data

Get waveform data as it's being extracted:

```dart
waveformExtraction.onCurrentExtractedWaveformData.listen((data) {
  print('Extracted ${data.length} samples so far');
  
  // You can use partial data for progressive display
  setState(() {
    partialWaveformData = data;
  });
});
```

## Stop Extraction

Stop the extraction process if needed:

```dart
// Start extraction
waveformExtraction.extractWaveformData(path: audioPath);

// Stop it later
waveformExtraction.stopWaveformExtraction();
```

This is useful when:
- User navigates away from the screen
- You need to extract a different file
- Extraction is taking too long

## Complete Example

Here's a complete example of extracting and displaying waveforms:

```dart
import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

class WaveformExtractionScreen extends StatefulWidget {
  final String audioPath;
  
  const WaveformExtractionScreen({Key? key, required this.audioPath}) 
      : super(key: key);

  @override
  State<WaveformExtractionScreen> createState() => 
      _WaveformExtractionScreenState();
}

class _WaveformExtractionScreenState extends State<WaveformExtractionScreen> {
  late final WaveformExtractionController waveformExtraction;
  List<double>? waveformData;
  double extractionProgress = 0.0;
  bool isExtracting = false;

  @override
  void initState() {
    super.initState();
    waveformExtraction = WaveformExtractionController();
    _setupListeners();
  }

  void _setupListeners() {
    waveformExtraction.onExtractionProgress.listen((progress) {
      setState(() {
        extractionProgress = progress;
      });
    });

    waveformExtraction.onCurrentExtractedWaveformData.listen((data) {
      setState(() {
        waveformData = data;
      });
    });
  }

  Future<void> _extractWaveform() async {
    setState(() {
      isExtracting = true;
      waveformData = null;
      extractionProgress = 0.0;
    });

    try {
      final data = await waveformExtraction.extractWaveformData(
        path: widget.audioPath,
        noOfSamples: 200,
      );

      setState(() {
        waveformData = data;
        isExtracting = false;
      });
    } catch (e) {
      print('Error extracting waveform: $e');
      setState(() {
        isExtracting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Waveform Extraction')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (waveformData != null)
              AudioFileWaveforms(
                size: Size(MediaQuery.of(context).size.width - 32, 100),
                waveformData: waveformData,
                playerWaveStyle: PlayerWaveStyle(
                  fixedWaveColor: Colors.blue,
                  scaleFactor: 100,
                ),
              )
            else if (isExtracting)
              Column(
                children: [
                  CircularProgressIndicator(value: extractionProgress),
                  const SizedBox(height: 16),
                  Text('${(extractionProgress * 100).toInt()}%'),
                ],
              )
            else
              const Text('Press button to extract waveform'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isExtracting ? null : _extractWaveform,
              child: const Text('Extract Waveform'),
            ),
            if (isExtracting)
              ElevatedButton(
                onPressed: () {
                  waveformExtraction.stopWaveformExtraction();
                  setState(() {
                    isExtracting = false;
                  });
                },
                child: const Text('Stop Extraction'),
              ),
          ],
        ),
      ),
    );
  }
}
```

## Caching Waveform Data

For better performance, cache extracted waveform data:

```dart
// Extract once
final waveformData = await waveformExtraction.extractWaveformData(
  path: audioPath,
  noOfSamples: 100,
);

// Save to local storage (using your preferred storage solution)
await saveWaveformData(audioPath, waveformData);

// Later, retrieve from cache
final cachedData = await loadWaveformData(audioPath);

if (cachedData != null) {
  // Use cached data
  AudioFileWaveforms(
  controller: playerController,
  size: Size(300, 80),
  waveformData: cachedData,
  );
} else {
  // Extract if not cached
  final data = await waveformExtraction.extractWaveformData(path: audioPath);
  await saveWaveformData(audioPath, data);
}
```

## Use with PlayerController

`WaveformExtractionController` is also accessible through `PlayerController`:

```dart
final playerController = PlayerController();

// Access built-in extraction controller
final waveformData = await playerController.waveformExtraction
    .extractWaveformData(path: audioPath);
```

This is useful when you need both playback and extraction capabilities.

# API Reference

This section provides a quick reference for the main classes and their properties.

## RecorderController

### Methods

| Method                                                       | Description                              |
|--------------------------------------------------------------|------------------------------------------|
| `record({String? path, RecorderSettings? recorderSettings})` | Start recording audio                    |
| `pause()`                                                    | Pause the current recording              |
| `stop([bool callReset = true])`                              | Stop recording and return file path      |
| `reset()`                                                    | Clear waveforms and duration labels      |
| `refresh()`                                                  | Reset waveform position to original      |
| `checkPermission()`                                          | Check microphone permission              |
| `dispose()`                                                  | Dispose controller and release resources |

### Properties

| Property                  | Type                 | Description                           |
|---------------------------|----------------------|---------------------------------------|
| `waveData`                | `List<double>`       | Normalized waveform data (0.0 to 1.0) |
| `elapsedDuration`         | `Duration`           | Current recording duration            |
| `recordedDuration`        | `Duration`           | Total duration after stopping         |
| `hasPermission`           | `bool`               | Microphone permission status          |
| `isRecording`             | `bool`               | Whether currently recording           |
| `recorderState`           | `RecorderState`      | Current recorder state                |
| `currentScrolledDuration` | `ValueNotifier<int>` | Scrolled position in milliseconds     |
| `overrideAudioSession`    | `bool`               | Override iOS audio session (iOS only) |

### Streams

| Stream                   | Type                    | Description                             |
|--------------------------|-------------------------|-----------------------------------------|
| `onCurrentDuration`      | `Stream<Duration>`      | Current duration updates (every 50ms)   |
| `onRecorderStateChanged` | `Stream<RecorderState>` | Recorder state changes                  |
| `onRecordingEnded`       | `Stream<Duration>`      | Final duration when recording ends      |
| `onAudioChunk`           | `Stream<Uint8List>`     | Real-time audio chunks during recording |

### Enums

**RecorderState**: `recording`, `paused`, `stopped`

## PlayerController

### Methods

| Method                                                                                                                   | Description                              |
|--------------------------------------------------------------------------------------------------------------------------|------------------------------------------|
| `preparePlayer({required String path, bool shouldExtractWaveform, int? noOfSamples, int? noOfSamplesPerSecond})`        | Prepare audio file for playback          |
| `startPlayer({FinishMode finishMode})`                                               | Start playing audio                      |
| `pausePlayer()`                                                                      | Pause playback                           |
| `stopPlayer()`                                                                       | Stop playback                            |
| `setVolume(double volume)`                                                           | Set volume (0.0 to 1.0)                  |
| `setRate(double rate)`                                                               | Set playback speed                       |
| `seekTo(int progress)`                                                               | Seek to position in milliseconds         |
| `setFinishMode({required FinishMode finishMode})`                                    | Set behavior when audio finishes         |
| `getDuration(DurationType durationType)`                                             | Get duration (max or current)            |
| `release()`                                                                          | Release native player resources          |
| `stopAllPlayers()`                                                                   | Stop all players                         |
| `pauseAllPlayers()`                                                                  | Pause all players                        |
| `dispose()`                                                                          | Dispose controller and release resources |

### Properties

| Property               | Type                           | Description                           |
|------------------------|--------------------------------|---------------------------------------|
| `playerState`          | `PlayerState`                  | Current player state                  |
| `maxDuration`          | `int`                          | Max duration in milliseconds          |
| `updateFrequency`      | `UpdateFrequency`              | Update rate for position              |
| `overrideAudioSession` | `bool`                         | Override iOS audio session (iOS only) |
| `waveformExtraction`   | `WaveformExtractionController` | Waveform extraction controller        |

### Streams

| Stream                     | Type                  | Description                      |
|----------------------------|-----------------------|----------------------------------|
| `onPlayerStateChanged`     | `Stream<PlayerState>` | Player state changes             |
| `onCurrentDurationChanged` | `Stream<int>`         | Position updates in milliseconds |
| `onCompletion`             | `Stream<void>`        | Audio playback completion        |

### Enums

**PlayerState**: `playing`, `paused`, `stopped`

**FinishMode**: `loop`, `pause`, `stop`

**DurationType**: `max`, `current`

**UpdateFrequency**: `low` (200ms), `medium` (100ms), `high` (50ms)

**WaveformType**: `fitWidth`, `long`

## WaveformExtractionController

### Methods

| Method                                                                                           | Description                           |
|--------------------------------------------------------------------------------------------------|---------------------------------------|
| `extractWaveformData({required String path, int? noOfSamples, int? noOfSamplesPerSecond})`      | Extract waveform data from audio file |
| `stopWaveformExtraction()`                                                                       | Stop ongoing extraction               |

### Streams

| Stream                           | Type                   | Description                             |
|----------------------------------|------------------------|-----------------------------------------|
| `onExtractionProgress`           | `Stream<double>`       | Extraction progress (0.0 to 1.0)        |
| `onCurrentExtractedWaveformData` | `Stream<List<double>>` | Partial waveform data during extraction |

## WaveStyle (for Recorder)

### Properties

| Property              | Type        | Default            | Description           |
|-----------------------|-------------|--------------------|-----------------------|
| `waveColor`           | `Color`     | `Colors.blueGrey`  | Wave color            |
| `showMiddleLine`      | `bool`      | `true`             | Show middle line      |
| `middleLineColor`     | `Color`     | `Colors.redAccent` | Middle line color     |
| `middleLineThickness` | `double`    | `3.0`              | Middle line thickness |
| `spacing`             | `double`    | `8.0`              | Space between waves   |
| `waveThickness`       | `double`    | `3.0`              | Wave thickness        |
| `showTop`             | `bool`      | `true`             | Show top waves        |
| `showBottom`          | `bool`      | `true`             | Show bottom waves     |
| `waveCap`             | `StrokeCap` | `StrokeCap.round`  | Wave end style        |
| `backgroundColor`     | `Color`     | `Colors.black`     | Background color      |
| `extendWaveform`      | `bool`      | `false`            | Extend to full width  |
| `showDurationLabel`   | `bool`      | `false`            | Show duration labels  |
| `showHourInDuration`  | `bool`      | `false`            | Show HH:MM:SS format  |
| `durationStyle`       | `TextStyle` | -                  | Duration text style   |
| `durationLinesColor`  | `Color`     | -                  | Duration line color   |
| `durationLinesHeight` | `double`    | -                  | Duration line height  |
| `gradient`            | `Shader?`   | `null`             | Wave gradient         |
| `scaleFactor`         | `double`    | `20.0`             | Wave scaling factor   |

## PlayerWaveStyle (for Player)

### Properties

| Property            | Type        | Default           | Description            |
|---------------------|-------------|-------------------|------------------------|
| `fixedWaveColor`    | `Color`     | `Colors.white54`  | Unplayed wave color    |
| `liveWaveColor`     | `Color`     | `Colors.white`    | Played wave color      |
| `seekLineColor`     | `Color`     | `Colors.white`    | Seek line color        |
| `seekLineThickness` | `double`    | `2.0`             | Seek line thickness    |
| `spacing`           | `double`    | `5.0`             | Space between waves    |
| `waveThickness`     | `double`    | `3.0`             | Wave thickness         |
| `showTop`           | `bool`      | `true`            | Show top waves         |
| `showBottom`        | `bool`      | `true`            | Show bottom waves      |
| `showSeekLine`      | `bool`      | `true`            | Show seek line         |
| `waveCap`           | `StrokeCap` | `StrokeCap.round` | Wave end style         |
| `backgroundColor`   | `Color`     | `Colors.black`    | Background color       |
| `fixedWaveGradient` | `Shader?`   | `null`            | Unplayed wave gradient |
| `liveWaveGradient`  | `Shader?`   | `null`            | Played wave gradient   |
| `scaleFactor`       | `double`    | `100.0`           | Wave scaling factor    |
| `scrollScale`       | `double`    | `1.0`             | Wave scale on scroll   |

### Methods

| Method                             | Description                        |
|------------------------------------|------------------------------------|
| `getSamplesForWidth(double width)` | Calculate samples needed for width |

## RecorderSettings

Model for recorder configuration:

```dart
RecorderSettings({
  IosEncoderSetting? iosEncoderSetting,
  AndroidEncoderSettings? androidEncoderSettings,
  int sampleRate = 44100,
  int bitRate = 128000,
})
```

## IosEncoderSetting

iOS encoder configuration:

```dart
IosEncoderSetting({
  required IosEncoder iosEncoder,
})
```

## AndroidEncoderSettings

Android encoder configuration:

```dart
AndroidEncoderSettings({
  required AndroidEncoder androidEncoder,
})
```

# Migration Guides

This document provides guidance for migrating between different versions of the Audio Waveforms package.

## Migration guide for version 2.0.0

Version 2.0.0 introduces several breaking changes to improve API consistency and functionality.

### Breaking Change 1: WaveformExtractionController

The `WaveformExtractionController` is now available as a standalone controller and is also bound to `PlayerController`.

#### Before (Pre-2.0.0):

```dart
// Waveform extraction was tightly coupled with PlayerController
final playerController = PlayerController();
await playerController.extractWaveformData(path: audioPath);
```

#### After (2.0.0+):

```dart
// Option 1: Use standalone controller
final waveformExtraction = WaveformExtractionController();
await waveformExtraction.extractWaveformData(path: audioPath);

// Option 2: Access through PlayerController
final playerController = PlayerController();
await playerController.waveformExtraction.extractWaveformData(path: audioPath);
```

### Breaking Change 2: Waveform Extraction Cancellation

Calling `preparePlayer` now automatically cancels any ongoing waveform extraction.

#### Before (Pre-2.0.0):

```dart
// No automatic cancellation
await playerController.preparePlayer(path: newPath);
```

#### After (2.0.0+):

```dart
// Automatically stops previous extraction
await playerController.preparePlayer(path: newPath);

// Or manually stop extraction
playerController.waveformExtraction.stopWaveformExtraction();
```

### Breaking Change 3: Gesture Callback Rename

The `tapUpUpdateDetails` parameter has been renamed to `onTapUp` for better clarity.

#### Before (Pre-2.0.0):

```dart
AudioFileWaveforms(
  controller: playerController,
  tapUpUpdateDetails: (details) {
    // Handle tap
  },
)
```

#### After (2.0.0+):

```dart
AudioFileWaveforms(
  controller: playerController,
  onTapUp: (details) {
    // Handle tap
  },
)
```

### Breaking Change 4: RecorderSettings Model

Recording configuration parameters have been consolidated into a `RecorderSettings` model.

#### Before (Pre-2.0.0):

```dart
await recorderController.record(
  path: path,
  encoder: AndroidEncoder.aac,
  outputFormat: AndroidOutputFormat.mpeg4,
  sampleRate: 44100,
  bitRate: 128000,
);
```

#### After (2.0.0+):

```dart
await recorderController.record(
  path: path,
  recorderSettings: const RecorderSettings(
    sampleRate: 44100,
    bitRate: 128000,
    iosEncoderSetting: IosEncoderSetting(
      iosEncoder: IosEncoder.kAudioFormatMPEG4AAC,
      linearPCMBitDepth: null, // supported values: 8, 16, 24, 32
      linearPCMIsBigEndian: null,
      linearPCMIsFloat: null,
    ),
    androidEncoderSettings: AndroidEncoderSettings(
      androidEncoder: AndroidEncoder.aacLc,
    ),
  ),
);
```

# Contributors

These are the main contributors who have helped shape the Audio Waveforms package.

## Main Contributors

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/Ujas-Majithiya">
        <img src="https://avatars.githubusercontent.com/u/56400956?s=100" width="100px;" alt=""/>
        <br />
        <sub><b>Ujas Majithiya</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/DevarshRanpara">
        <img src="https://avatars.githubusercontent.com/u/26064415?s=100" width="100px;" alt=""/>
        <br />
        <sub><b>Devarsh Ranpara</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/jayakbari1">
        <img src="https://avatars.githubusercontent.com/u/67188121?s=100" width="100px;" alt=""/>
        <br />
        <sub><b>Jay Akbari</b></sub>
      </a>
    </td>
  </tr>
  <tr>
    <td align="center">
      <a href="https://github.com/himanshu447">
        <img src="https://avatars.githubusercontent.com/u/35589687?s=100" width="100px;" alt=""/>
        <br />
        <sub><b>Himanshu Gandhi</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/ManojPadia">
        <img src="https://avatars.githubusercontent.com/u/69233459?s=100" width="100px;" alt=""/>
        <br />
        <sub><b>Manoj Padia</b></sub>
      </a>
    </td>
  </tr>
</table>

## How to Contribute

Contributions to the Audio Waveforms package are welcome! Here's how you can contribute:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Guidelines for Contributing

- Follow the coding style and conventions used in the project
- Write clear, concise commit messages
- Add tests for new features or bug fixes when applicable
- Update documentation as needed
- Make sure all existing tests pass before submitting a pull request
- Include example usage for new features
- Test on both iOS and Android platforms

## Reporting Issues

When reporting issues, please include:

- A clear and descriptive title
- Steps to reproduce the issue
- Expected behavior
- Actual behavior
- Screenshots or code snippets if applicable
- Flutter version, package version, and platform
- Device/simulator information

## Feature Requests

We welcome feature requests! Please:

- Check if the feature has already been requested
- Clearly describe the feature and its use case
- Explain why this feature would be useful to most users
- Provide examples of how the feature would be used

For more information about contributing, please check the [GitHub repository](https://github.com/SimformSolutionsPvtLtd/audio_waveforms).

# License

```
MIT License

Copyright (c) 2022 Simform Solutions

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

