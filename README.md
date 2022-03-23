![Audio Waveforms - Simform LLC.](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/blob/main/preview/banner.png)

# Audio Waveforms

Use this plugin to generate waveforms while recording audio in any file formats supported
by given encoders. We can use gestures to scroll through the waveforms and also style waveforms.

## Preview
<a href="https://raw.githubusercontent.com/SimformSolutionsPvtLtd/audio_waveforms/main/preview/demo.gif"><img src="https://raw.githubusercontent.com/SimformSolutionsPvtLtd/audio_waveforms/main/preview/demo.gif" width="390px;" height="700px;"/></a>

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
*Get the latest version in the 'Installing' tab on [pub.dev](https://pub.dev/packages/audiowaveforms)*

2.  Import the package.
```dart
import 'package:audio_waveforms/audio_waveforms.dart';
```

## Usage

1. Initialise WaveController.
```dart
late final WaveController waveController;

  @override
  void initState() {
    super.initState();
    waveController = WaveController();
  }
```
2. Use `AudioWaveforms` widget in widget tree.
```dart
AudioWaveforms(
  size: Size(MediaQuery.of(context).size.width, 200.0),
  waveController: waveController,
),
```
3. Start recording (it will also display waveforms)
```dart
await waveController.record();
```
You can provide file name with extension and full path in path parameter of record function. If
not provided .aac is default extension and dateTime will be file name.

4. Pause recording
```dart
await waveController.pause();
```
5. Stop recording
```dart
final path = await waveController.stop();
```
Calling this will save the recording at provided path and it will return path to that file.

6. Disposing WaveController
```dart
@override
  void dispose() {
    waveController.disposeFunc();
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
By enabling gestures, you can scroll through waveform in recording state or paused state

2. Refreshing the wave to initial position after scrolling
```dart
waveController.refresh();
```
Once scrolled waveform will stop updating position with newly added wave while recording so we can
use this to get waves updating again. It can also be used in paused/stopped state.

3. Changing background of the Waveform
```dart
 AudioWaveforms(
  size: Size(MediaQuery.of(context).size.width, 200.0),
  waveController: waveController,
  margin: const EdgeInsets.all(10.0),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(14.0),
    gradient: const LinearGradient(
      colors: <Color>[
       Color(0xFF615766),
       Color(0xFF394253),
       Color(0xFF412B4F),
      ],
    begin: Alignment.bottomLeft,
    stops: <double>[0.2, 0.45, 0.8],
    ),
  ),
),
```
4. Changing style of the waves
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
5. Applying gradient to waves
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

6. Show duration of the waveform
```dart
AudioWaveforms(
 waveStyle: WaveStyle(showDurationLabel: true),
),
```
7. Change frequency of wave update and normalise according to need and platform
```dart
late final WaveController waveController;

  @override
  void initState() {
    super.initState();
    waveController = WaveController()
      ..updateFrequency = const Duration(milliseconds: 100)
      ..normalizationFactor = Platform.isAndroid ? 60 : 40;
  }
```
8. Using different types of encoders and sample rate
```dart
late final WaveController waveController;

  @override
  void initState() {
    super.initState();
    waveController = WaveController()
      ..encoder = Encoder.aac
      ..sampleRate = 16000;
  }
```
