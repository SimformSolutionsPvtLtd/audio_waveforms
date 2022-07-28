![Audio Waveforms - Simform LLC.](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/blob/main/preview/banner.png)

# Audio Waveforms

Use this plugin to generate waveforms while recording audio in any file formats supported
by given encoders or from audio files. We can use gestures to scroll through the waveforms or seek to
any position while playing audio and also style waveforms.

## Preview
<a href="https://raw.githubusercontent.com/SimformSolutionsPvtLtd/audio_waveforms/main/preview/demo.gif"><img src="https://raw.githubusercontent.com/SimformSolutionsPvtLtd/audio_waveforms/main/preview/demo.gif" width="390px;" height="700px;"/></a>

### Recorder

## Platform specific configuration

### Android

Change the minimum Android sdk version to 21 (or higher) in your `android/app/build.gradle` file.
```
minSdkVersion 21
```

Add RECORD_AUDIO permission in `AndroidManifest.xml`
```
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

### IOS

Add this two rows in `ios/Runner/Info.plist`
```
<key>NSMicrophoneUsageDescription</key>
<string>This app is requires Mic permission.</string>
```
This plugin requires ios 10.0 or higher. So add this line in `Podfile`
```
platform :ios, '10.0'
```
## Installing

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

## Usage

1. Initialise RecorderController
```dart
late final RecorderController recorderController;
@override
void initState() {
  super.initState();
  recorderController = RecorderController();
}
```
2. Use `AudioWaveforms` widget in widget tree
```dart
AudioWaveforms(
  size: Size(MediaQuery.of(context).size.width, 200.0),
  recorderController: recorderController,
),
```
3. Start recording (it will also display waveforms)
```dart
await recorderController.record();
```
You can provide file name with extension and full path in path parameter of record function. If
not provided .aac is the default extension and dateTime will be the file name.

4. Pause recording
```dart
await recorderController.pause();
```
5. Stop recording
```dart
final path = await recorderController.stop();
```
Calling this will save the recording at provided path and it will return path to that file.

6. Disposing RecorderController
```dart
@override
void dispose() {
 recorderController.dispose();
 super.dispose();
}
```

## Additional feature
1. Scroll through waveform
```dart
AudioWaveforms(
 enableGesture: true,
),
```
By enabling gestures, you can scroll through waveform in recording state or paused state.

2. Refreshing the wave to initial position after scrolling
```dart
recorderController.refresh();
```
Once scrolled waveform will stop updating position with newly added waves while recording so we can
use this to get waves updating again. It can also be used in paused/stopped state.

3. Changing style of the waves
```dart
AudioWaveforms(
 waveStyle: WaveStyle(
   color: Colors.white,
   showDurationLabel: true,
   spacing: 8.0,
   showBottom: false,
   extendWaveform: true,
   showMiddleLine: false,
 ),
),
```
4. Applying gradient to waves
```dart
AudioWaveforms(
  waveStyle: WaveStyle(
   gradient: ui.Gradient.linear(
    const Offset(70, 50),
    Offset(MediaQuery.of(context).size.width / 2, 0),
    [Colors.red, Colors.green],
   ),
  ),
),
```
5. Show duration of the waveform
```dart
AudioWaveforms(
 waveStyle: WaveStyle(showDurationLabel: true),
),
```
6. Change frequency of wave update and normalise according to need and platform
```dart
late final RecorderController recorderController;
  @override
  void initState() {
    super.initState();
    recorderController = RecorderController()
      ..updateFrequency = const Duration(milliseconds: 100)
      ..normalizationFactor = Platform.isAndroid ? 60 : 40;
  }
```
7. Using different types of encoders and sample rate
```dart
late final RecorderController recorderController;
  @override
  void initState() {
    super.initState();
    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 16000;
  }
```
8. Listening scrolled duration position
```dart
recorderController.currentScrolledDuration;
```
It is a ValueNotifier. You can listen to any changes in current scrolled duration by using this.
To use this `shouldCalculateScrolledPosition` flag needs to be enabled. Duration is in
milliseconds.

### Player

## Usage
1. Initialise PlayerController
```dart
late PlayerController playerController;
@override
void initState() {
  super.initState();
  playerController = PlayerController();
}
```
2. Prepare player
```dart
await playerController.preparePlayer(path);
```
Provide the audio file path in the parameter. You can also set volume with optional parameter.

3. Use `AudioFileWaveforms` in widget-tree
```dart
AudioFileWaveforms(
 size: Size(MediaQuery.of(context).size.width, 100.0),
 playerController: playerController,
)
```
4. Start player
```dart
await playerController.startPlayer();
```
As default when audio ends it will be seeked to start but you can pass false let it stay at end.

5. Pause player
```dart
await playerController.pausePlayer();
```
6. Stop player
```dart
await playerController.stopPlayer();
```
7. Disposing the playerController
```dart
@override
void dispose() {
 playerController.dispose();
 super.dispose();
}
```

## Additional feature
1. Set volume for the player
```dart
await playerController.setVolume(1.0);
```
2. Seek to any position
```dart
await playerController.seekTo(5000);
```
3. Get current/max duration of audio file
```dart
final duration = await playerController.getDuration(DurationType.max);
```
4. Seek using gestures
```dart
AudioFileWaveforms(
 enableSeekGesture: true,
)
```
Audio also can be seeked using gestures on waveforms (enabled by default).

5. Ending audio with different modes
```dart
await playerController.startPlayer(finishMode: FinishMode.stop);
```
Using `FinishMode.stop` will stop the player, `FinishMode.pause` will pause the player at the end
 and `FinishMode.loop` will loop the player.

6. Listening to player state changes
```dart
playerController.onPlayerStateChanged.listen((state) {});
```
7. Listening to current duration
```dart
playerController.onCurrentDurationChanged.listen((duration) {});
```
Duration is in milliseconds.
