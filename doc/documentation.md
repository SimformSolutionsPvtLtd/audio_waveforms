# Overview

Audio Waveforms is a Flutter plugin that allows you to generate and display waveforms while recording or playing audio files. The plugin supports:

- Recording audio in various file formats based on supported encoders
- Displaying waveforms during audio recording
- Generating waveforms from existing audio files
- Customizing waveform appearance with colors, gradients, and more
- Gestures to scroll through waveforms or seek any position during playback

## Preview

![Audio Waveforms Demo](https://raw.githubusercontent.com/SimformSolutionsPvtLtd/audio_waveforms/main/preview/demo.gif)

## Key Features

- **Recording**: Record audio with customizable encoders and formats
- **Playback**: Play audio files with waveform visualization
- **Waveform Display**: Show waveforms for both recording and playback
- **Customization**: Style waveforms with various appearance options
- **Gestures**: Scroll through waveforms and seek positions with gestures
- **Waveform Extraction**: Extract and save waveform data for reuse

## Components

The plugin offers two main components:

1. **Recorder**: Allows recording audio while displaying waveform visualization in real-time
2. **Player**: Plays audio files with waveform visualization and seeking capabilities

Both components come with extensive customization options and event listeners for building rich audio experiences in your Flutter applications.


# Installation

## Prerequisites

Before you begin, ensure you have Flutter installed and configured properly.

### Add Dependency

Add the audio_waveforms dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  audio_waveforms: <latest-version>
```

Run the following commands to ensure clean installation:

```bash
flutter clean
flutter pub get
```

## Platform-Specific Setup

> Note: This permission is only required if you are using the recorder component. If you are only
> using the player component, you can skip this step.

### Android

1. Change the minimum Android SDK version in your `android/app/build.gradle` file:

```gradle
minSdkVersion 21
```

2. Add RECORD_AUDIO permission in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

### iOS

1. Add description for microphone usage in `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Add your own description.</string>
```

2. This plugin requires iOS 13.0 or higher. Add this line to your `Podfile`:

```text
platform :ios, '13.0'
```

## Verification

After completing the installation steps, you should be able to import and use the plugin in your Flutter application:

```dart
import 'package:audio_waveforms/audio_waveforms.dart';
```

If you encounter any issues during installation, make sure to:
- Delete the app from your device
- Perform `flutter clean` and `flutter pub get`
- Restart your IDE

# Basic Usage

## Recorder

This example demonstrates how to create a basic audio recorder with waveform visualization:

```dart
String? recordedFilePath;
final RecorderController recorderController = RecorderController();

@override
void initState() {
  super.initState();
  recorderController.checkPermission();
}

@override
void dispose() {
  recorderController.dispose();
  super.dispose();
}

@override
Widget build(BuildContext context) {
  return Column(
    children: [
      ElevatedButton(
        onPressed: () {
          if (recorderController.hasPermission) {
            recorderController.record(); // By default saves file with datetime as name
          }
        },
        child: Text('Record'),
      ),
      ElevatedButton(
        onPressed: () {
          recorderController.pause();
        },
        child: Text('Pause'),
      ),
      ElevatedButton(
        onPressed: () async {
          if (recorderController.isRecording) {
            recordedFilePath = await recorderController.stop();
          }
        },
        child: Text('Stop'),
      ),
      AudioWaveforms(
        controller: recorderController,
        size: Size(300, 50),
      ),
    ],
  );
}
```

## Player

This example demonstrates how to create a basic audio player with waveform visualization:

```dart
final PlayerController playerController = PlayerController();

@override
void initState() {
  super.initState();
  playerController.preparePlayer(path: '../myFile.mp3');
}

@override
void dispose() {
  playerController.dispose();
  super.dispose();
}

@override
Widget build(BuildContext context) {
  return Column(
    children: [
      ElevatedButton(
        onPressed: () {
          playerController.startPlayer();
        },
        child: Text('Play'),
      ),
      ElevatedButton(
        onPressed: () {
          playerController.pausePlayer();
        },
        child: Text('Pause'),
      ),
      ElevatedButton(
        onPressed: () {
          playerController.stopPlayer();
        },
        child: Text('Stop'),
      ),
      AudioFileWaveforms(
        controller: playerController,
        size: Size(300, 50),
      ),
    ],
  );
}
```

## Loading Audio Files

### From Assets

```dart
File file = File('${appDirectory.path}/audio.mp3');
final audioFile = await rootBundle.load('assets/audio.mp3');
await file.writeAsBytes(audioFile.buffer.asUint8List());
playerController.preparePlayer(path: file.path);
```

### From Device Storage

```dart
playerController.preparePlayer(path: filePath);
```

### From Network
Currently, playing remote audio files directly isn't supported. You need to download the file first, then play it locally.


# Advanced Usage

## Advanced Recorder Features

### Customizing Recording Settings

```dart
// Specify custom file path
recorderController.record(path: '../myFile.m4a');

// Configure encoders and output format
recorderController.record(
  recorderSettings: const RecorderSettings(
    iosEncoderSetting: IosEncoderSetting(
      iosEncoder: IosEncoder.kAudioFormatMPEG4AAC,
    ),
    androidEncoderSettings: AndroidEncoderSettings(
      androidEncoder: AndroidEncoder.aac,
      androidOutputFormat: AndroidOutputFormat.mpeg4,
    ),
  ),
);

// Update waveform refresh rate
recorderController.updateFrequency = const Duration(milliseconds: 100);

// Override iOS audio session
// If you set this property to true, audio session will be overridden otherwise it won't
recorderController.overrideAudioSession = false;
```

### Accessing Recording Information

```dart
// Get waveform data
final waveData = recorderController.waveData;

// Get elapsed recording duration
final duration = recorderController.elapsedDuration;

// Get recorded duration after stopping
final recordedDuration = recorderController.recordedDuration;

// Check if recording
final isRecording = recorderController.isRecording;

// Get current recorder state
final state = recorderController.recorderState;
```

### Listening to Recording Events

```dart
// Current recording duration events
recorderController.onCurrentDuration.listen((duration) {
  // Handle current duration update
});

// Recorder state changes
recorderController.onRecorderStateChanged.listen((state) {
  // Handle state changes
});

// Recording ended event
recorderController.onRecordingEnded.listen((duration) {
  // Handle recording completion
});

// Get scrolled duration
recorderController.currentScrolledDuration.addListener(() {
  // Handle scrolled position changes
});
```

## Advanced Player Features

### Customizing Player Settings

```dart
// Set player volume
playerController.setVolume(1.0); // Values between 0.0 and 1.0

// Set playback speed
playerController.setRate(1.0);

// Seek to specific position
playerController.seekTo(5000); // In milliseconds

// Configure behavior when audio finishes
playerController.setFinishMode(finishMode: FinishMode.loop);
// FinishMode options: 
// Keeps the buffered data and plays again after completion, creating a loop.
// loop,
//
// Stop audio playback but keep all resources intact.
// Use this if you intend to play again later.
// pause,
//
// Stops player and disposes it(a PlayerController won't be disposed).
// stop.
```

### Listening to Player Events

```dart
// Player state changes
playerController.onPlayerStateChanged.listen((state) {
  // Handle state changes
});

// Current playing position updates
playerController.onCurrentDurationChanged.listen((duration) {
  // Handle position changes
});

// Waveform extraction progress
playerController.waveformExtraction.onExtractionProgress.listen((progress) {
  // Handle extraction progress
});

// Playback completion event
playerController.onCompletion.listen((_) {
  // Handle completion
});
```

### Managing Multiple Players

```dart
// Stop all players at once
playerController.stopAllPlayers();

// Pause all players at once
playerController.pauseAllPlayers();
```

## Advanced Waveform Styling

### Recorder Waveform Styling

```dart
AudioWaveforms(
  controller: recorderController,
  size: Size(MediaQuery.of(context).size.width, 200.0),
  enableGesture: true,
  shouldCalculateScrolledPosition: true,
  waveStyle: WaveStyle(
    showMiddleLine: true,
    extendWaveform: true,
    showDurationLabel: true,
    spacing: 8.0,
    waveColor: Colors.blue,
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.blue, Colors.purple],
    ),
  ),
);
```

### Player Waveform Styling

```dart
AudioFileWaveforms(
  controller: playerController,
  size: Size(MediaQuery.of(context).size.width, 200.0),
  waveformType: WaveformType.fitWidth,
  continuousWaveform: true,
  playerWaveStyle: PlayerWaveStyle(
    fixedWaveColor: Colors.blue,
    liveWaveColor: Colors.red,
    spacing: 6,
    scaleFactor: 100,
    scrollScale: 1.2,
    waveCap: StrokeCap.round,
    waveThickness: 3,
  ),
);
```

## Using Standalone Waveform Extraction

```dart
final waveformExtraction = WaveformExtractionController();

// Extract waveform data
final waveformData = await waveformExtraction.extractWaveformData(
  path: '../audioFile.mp3',
  noOfSamples: 100,
);

// Listen to extraction events
waveformExtraction.onCurrentExtractedWaveformData.listen((data) {
  // Handle extracted data
});

waveformExtraction.onExtractionProgress.listen((progress) {
  // Handle extraction progress
});

// Stop extraction if needed
waveformExtraction.stopWaveformExtraction();
```

## Saving resources by precalculating the waveforms
You can precalculate waveforms by using `playerController.waveformExtraction.extractWaveformData()`.
This function gives back list of doubles which you can directly set into `AudioFileWaveforms` widget. Since calculating waveforms is expensive process, you can save this data somewhere and use it again when same file is used.

If you only want to `extractWaveformData` without `playerController` you can do that using `WaveformExtractionController` [see more details here](#waveform-extraction-controller).
```dart
final waveformData = await playerController.waveformExtraction.extractWaveformData(path: '../audioFile.mp3');

AudioFileWaveforms(
  ...
  waveformData: waveformData,
);
```

# Migration Guides

## Migrating from v0.x to v1.0

### Breaking Changes

1. **PlayerController Changes**
   - The `playerController.preparePlayer()` method now returns a `Future<void>` instead of `void`
   - Waveform extraction is now done through a separate controller:
     `playerController.waveformExtraction`

2. **WaveformExtraction Changes**
   - Waveform extraction functionality has been moved to its own controller
   - The `extractWaveformData()` method is now accessed via
     `playerController.waveformExtraction.extractWaveformData()`

### Migration Steps

#### Updating Player Initialization

**Before:**

```dart
playerController.preparePlayer
(
path
:
filePath
);
// Code that depends on player being ready
```

**After:**

```dart
await
playerController.preparePlayer
(
path
:
filePath
);
// Code that depends on player being ready
```

#### Updating Waveform Extraction

**Before:**

```dart

final waveformData = await
playerController.extractWaveformData
(
path
:
filePath
);
```

**After:**

```dart

final waveformData = await
playerController.waveformExtraction.extractWaveformData
(
path
:
filePath
);
```

#### Updating Event Listeners

**Before:**

```dart
playerController.onCurrentExtractedWaveformData.listen
(
(data) {
// Handle waveform data
});

playerController.onExtractionProgress.listen((progress) {
// Handle extraction progress
});
```

**After:**

```dart
playerController.waveformExtraction.onCurrentExtractedWaveformData.listen
(
(data) {
// Handle waveform data
});

playerController.waveformExtraction.onExtractionProgress.listen((progress) {
// Handle extraction progress
});
```

## Migrating from v1.x to v2.0

### Breaking Changes

1. **Recorder Initialization**
   - The `checkPermission()` method is now asynchronous and returns a `Future<bool>`

2. **AudioFileWaveforms Widget**
   - The `playerController` parameter is now required
   - Added `waveformType` parameter with default value `WaveformType.fitWidth`

3. **WaveStyle Changes**
   - The `showDurationLabel` now defaults to `true`
   - Added new parameters for customizing duration labels

### Migration Steps

#### Updating Recorder Initialization

**Before:**

```dart
recorderController.checkPermission
();if
(
recorderController.hasPermission) {
// Start recording
}
```

**After:**

```dart

final hasPermission = await
recorderController.checkPermission
();if
(
hasPermission) {
// Start recording
}
```

#### Updating AudioFileWaveforms Widget

**Before:**

```dart
AudioFileWaveforms
(
size: Size(300, 70),
playerController: playerController
,
);
```

**After:**

```dart
AudioFileWaveforms
(
controller: playerController,
size: Size(300, 70),
waveformType: WaveformType.fitWidth,
);
```

#### Updating WaveStyle

**Before:**

```dart
WaveStyle
(
showDurationLabel
:
false
,
spacing
:
5.0
,
);
```

**After:**

```dart
WaveStyle
(
showDurationLabel: false,
spacing: 5.0,
durationStyle: DurationStyle.
timeLeft
,
);
```

## Migrating from v2.x to v3.0

### Breaking Changes

1. **PlayerController Changes**
   - Added `UpdateFrequency` enum to control update rate
   - Changed default behavior of `continuousWaveform` to `true`

2. **New API for Standalone Waveform Extraction**
   - Added `WaveformExtractionController` class that can be used independently

### Migration Steps

#### Updating Player Controller

**Before:**

```dart
playerController.preparePlayer
(
path
:
filePath
,
shouldExtractWaveform
:
true
,
);
```

**After:**

```dart
playerController.updateFrequency = UpdateFrequency.high;await
playerController.preparePlayer
(
path
:
filePath
,
shouldExtractWaveform
:
true
,
);
```

#### Using Standalone Waveform Extraction

**Before:**

```dart

final waveformData = await
playerController.waveformExtraction.extractWaveformData
(
path
:
filePath
);
```

**After:**
You can still use the previous method, or use the standalone controller:

```dart

final waveformExtraction = WaveformExtractionController();
final waveformData = await
waveformExtraction.extractWaveformData
(
path
:
filePath
);
```


# Contributors

## Main Contributors

| ![Ujas Majithiya](https://avatars.githubusercontent.com/u/56400956?s=200) | ![Devarsh Ranpara](https://avatars.githubusercontent.com/u/26064415?s=200) | ![Jay Akbari](https://avatars.githubusercontent.com/u/67188121?s=200) | ![Himanshu Gandhi](https://avatars.githubusercontent.com/u/35589687?s=200) | ![Manoj Padia](https://avatars.githubusercontent.com/u/69233459?s=200) |
|:-------------------------------------------------------------------------:|:--------------------------------------------------------------------------:|:---------------------------------------------------------------------:|:--------------------------------------------------------------------------:|:----------------------------------------------------------------------:|
|            [Ujas Majithiya](https://github.com/Ujas-Majithiya)            |            [Devarsh Ranpara](https://github.com/DevarshRanpara)            |              [Jay Akbari](https://github.com/jayakbari1)              |             [Himanshu Gandhi](https://github.com/himanshu447)              |              [Manoj Padia](https://github.com/ManojPadia)              |

## How to Contribute

Contributions are welcome! If you'd like to contribute to this project, please follow these steps:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Implement your changes
4. Add tests if applicable
5. Commit your changes (`git commit -m 'Add some amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## Guidelines for Contributors

- Follow the coding style used throughout the project
- Write clear, concise commit messages
- Add comments to your code where necessary
- Update documentation for any changes you make
- Test your changes thoroughly before submitting a pull request

## Reporting Issues

If you find a bug or have a suggestion for improvement, please open an issue on the GitHub
repository. Be sure to include:

- A clear title and description
- Steps to reproduce the issue
- Expected behavior
- Actual behavior
- Screenshots or code snippets if applicable
- Your environment (Flutter version, device, OS, etc.)

## Code of Conduct

Please note that this project is released with a Contributor Code of Conduct. By participating in
this project, you agree to abide by its terms.


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
