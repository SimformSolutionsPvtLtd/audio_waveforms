![Audio Waveforms - Simform LLC.](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/blob/main/preview/banner.png)

# Audio Waveforms

Use this plugin to generate waveforms while recording audio in any file formats supported
by given encoders or from audio files. We can use gestures to scroll through the waveforms or seek to
any position while playing audio and also style waveforms.

## Preview
<a href="https://raw.githubusercontent.com/SimformSolutionsPvtLtd/audio_waveforms/main/preview/demo.gif"><img src="https://raw.githubusercontent.com/SimformSolutionsPvtLtd/audio_waveforms/main/preview/demo.gif" width="390px;" height="700px;"/></a>


**Check [migration guide](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/blob/main/migration_guide.md) to migrate from 0.1.5+1 to 1.0.0**


## Recorder

### Platform specific configuration


**Android**

Change the minimum Android sdk version to 21 (or higher) in your `android/app/build.gradle` file.
```
minSdkVersion 21
```

Add RECORD_AUDIO permission in `AndroidManifest.xml`
```
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```


**IOS**

Add this two rows in `ios/Runner/Info.plist`
```
<key>NSMicrophoneUsageDescription</key>
<string>This app requires Mic permission.</string>
```
This plugin requires ios 10.0 or higher. So add this line in `Podfile`
```
platform :ios, '10.0'
```
**Installing**

1.  Add dependency to `pubspec.yaml`

```dart
dependencies:
    audio_waveforms: <latest-version>
```
*Get the latest version in the 'Installing' tab on [pub.dev](https://pub.dev/packages/audio_waveforms)*

2.  Import the package.
```dart
import 'package:audio_waveforms/audio_waveforms.dart';
```

### Usage
1. Recording audio
```dart
RecorderController controller = RecorderController();      // Initialise
await controller.record(path: 'path');                     // Record (path is optional)
final hasPermission = await controller.checkPermission();  // Check mic permission (also called during record)
await controller.pause();                                  // Pause recording
final path = await controller.stop();                      // Stop recording and get the path
controller.refresh();                                      // Refresh waveform to original position
controller.dispose();                                      // Dispose controller
```

2. Use `AudioWaveforms` widget in widget tree
```dart
AudioWaveforms(
  size: Size(MediaQuery.of(context).size.width, 200.0),
  recorderController: controller,
  enableGesture: true,
  waveStyle: WaveStyle(
    ...
    color: Colors.white,
    showDurationLabel: true,
    spacing: 8.0,
    showBottom: false,
    extendWaveform: true,
    showMiddleLine: false,
    gradient: ui.Gradient.linear(
      const Offset(70, 50),
      Offset(MediaQuery.of(context).size.width / 2, 0),
      [Colors.red, Colors.green],
  ),
  ...
  ),
),
```
**Advance usage**
```dart
controller.updateFrequency = const Duration(milliseconds: 100);  // Update speed of new wave
controller.androidEncoder = AndroidEncoder.aac;                  // Changing android encoder 
controller.androidOutputFormat = AndroidOutputFormat.mpeg4;      // Changing android output format
controller.iosEncoder = IosEncoder.kAudioFormatMPEG4AAC;         // Changing ios encoder
controller.sampleRate = 44100;                                   // Updating sample rate
controller.bitRate = 48000;                                      // Updating bitrate
controller.onRecorderStateChanged.listen((state){});             // Listening to recorder state changes
controller.onCurrentDuration.listen((duration){});               // Listening to current duration updates
controller.onRecordingEnded.listen((duration));                  // Listening to audio file duration
controller.recordedDuration;                                     // Get recorded audio duration 
controller.currentScrolledDuration;                              // Current duration position notifier
```

## Player

### Usage
```dart
PlayerController controller = PlayerController();                   // Initialise
// Extract waveform data
final waveformData = await controller.extractWaveformData(
    path: 'path',
    noOfSamples: 100,
);
// Or directly extract from preparePlayer and initialise audio player
await controller.preparePlayer(
    path: 'path',
    shouldExtractWaveform: true,
    noOfSamples: 100,
    volume: 1.0,
); 
await controller.startPlayer(finishMode: FinishMode.stop);          // Start audio player
await controller.pausePlayer();                                     // Pause audio player
await controller.stopPlayer();                                      // Stop audio player
await controller.setVolume(1.0);                                    // Set volume level
await controller.seekTo(5000);                                      // Seek audio
final duration = await controller.getDuration(DurationType.max);    // Get duration of audio player
controller.updateFrequency = UpdateFrequency.low;                   // Update reporting rate of current duration.
controller.onPlayerStateChanged.listen((state) {});                 // Listening to player state changes
controller.onCurrentDurationChanged.listen((duration) {});          // Listening to current duration changes
controller.onCurrentExtractedWaveformData.listen((data) {});        // Listening to latest extraction data
controller.onExtractionProgress.listen((progress) {});              // Listening to extraction progress
controller.onCompletion.listen((_){});                              // Listening to audio completion
controller.stopAllPlayer();                                         // Stop all registered audio players
controller.dispose();                                               // Dispose controller
```

**Use `AudioFileWaveforms` widget in widget tree**
```dart
AudioFileWaveforms(
 size: Size(MediaQuery.of(context).size.width, 100.0),
 playerController: controller,
 enableSeekGesture: true,
 waveformType: WaveformType.long,
 waveformData: [],
 playerWaveStyle: const PlayerWaveStyle(
      fixedWaveColor: Colors.white54,
      liveWaveColor: Colors.blueAccent,
      spacing: 6,
      ...
      ),
      ...
);
```

## Main Contributors

<table>
  <tr>
    <td align="center"><a href="https://github.com/Ujas-Majithiya"><img src="https://avatars.githubusercontent.com/u/56400956?v=4" width="100px;" alt=""/><br /><sub><b>Ujas Majithiya</b></sub></a></td>
    <td align="center"><a href="https://github.com/DevarshRanpara"><img src="https://avatars.githubusercontent.com/u/26064415?s=100" width="100px;" alt=""/><br /><sub><b>Devarsh Ranpara</b></sub></a></td>
  </tr>
</table>