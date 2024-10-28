![Audio Waveforms - Simform LLC.](https://raw.githubusercontent.com/SimformSolutionsPvtLtd/audio_waveforms/main/preview/banner.png)

# Audio Waveforms

Use this plugin to generate waveforms while recording audio in any file format supported
by given encoders or from audio files. We can use gestures to scroll through the waveforms or seek
any position while playing audio and style waveforms.

## Preview
<a href="https://raw.githubusercontent.com/SimformSolutionsPvtLtd/audio_waveforms/main/preview/demo.gif"><img src="https://raw.githubusercontent.com/SimformSolutionsPvtLtd/audio_waveforms/main/preview/demo.gif" width="390px;" height="700px;"/></a>


**Prerequisites**

1. Add dependency to `pubspec.yaml`

    ```dart
    dependencies:
        audio_waveforms: <latest-version>
    ```
2. Make sure delete the app from your device and perform `flutter clean` and then `flutter pub get`

# Usage
## Recorder
Below are platform specific setup for recording audio to be able work.
<details>
<summary>Android</summary>

Change the minimum Android sdk version to 21 (or higher) in your `android/app/build.gradle` file.

```
minSdkVersion 21
```

Add RECORD_AUDIO permission in `AndroidManifest.xml`
```
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```
</details>
<details>
<summary>IOS</summary>

Add description to your microphone usage in `ios/Runner/Info.plist`,

```
<key>NSMicrophoneUsageDescription</key>
<string>Add your own description.</string>
```
This plugin requires ios 12.0 or higher. So add this line to your `Podfile`.
```
platform :ios, '12.0'
```
</details>

### Quick example
This is a quick example showcasing how to show waveforms while recording,

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
            recorderController.record(); // By default saves file with datetime as name.
          }
        },
        child: Text('Record'),
      ),
       ElevatedButton(
        onPressed: () {
           recorderController.pause();
        },
        child: Text('Record'),
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

### Advance features of Recorder
#### Customizing recorder

1. File path,
   ```dart
   recorderController.record(path: '../myFile.m4a');
   ```
2. Encoders and output format,
   ```dart
   recorderController.record(
     androidEncoder: AndroidEncoder.aac,
     androidOutputFormat: AndroidOutputFormat.mpeg4,
     iosEncoder: IosEncoder.kAudioFormatMPEG4AAC,
   );
   ```
   **Note** -: These are default encoder and output format to support `.m4a` file format. If you change them make sure that your file **extension**, **sample rate** and **bit rate** supports them and also which are supported by `MediaRecorder` for Android and `AVAudioRecorder` for iOS.
3. Update the rate at which new waveforms are drawn,
   ```dart
   recorderController.updateFrequency = const Duration(milliseconds: 100);
   ```
4. Overriding ios recording session,
   ```dart
   recorderController.overrideAudioSession = false;
   ``` 
   By Setting this to false, you can use own implement your own implementation so that your doesn't interfere with other app or even this plugin does't override previously set audio session.

#### Function to control recording and waveforms
1. record
   ```dart
   recorderController.record(); // If path isn't provided by default sets current date time as file name m4a is used as file extension.
   ```
2. pause
   ```dart
   recorderController.pause(); // Pauses the recording.
   ```
   **Note**-: To resume recording, use **record** function.
3. Stop
   ```dart
   recorderController.stop(false); // Stops the current recording.
   ```
   The boolean parameter **callReset** detects if after stopping the recording waveforms should get cleared or not.
4. reset
   ```dart
   recorderController.reset(); // Clears waveforms and duration legends from the AudioWaveforms widget.
   ```
5. refresh
   ```dart
   recorderController.refresh(); // Move back waveforms to original position if they have ever been scrolled.
   ```
6. dispose
   ```dart
   recorderController.dispose(); // Dispose the controller and recorder if haven't already stopped.
   ```
#### Events to get from RecorderController
1. Streams which you can listen to,
   ```dart
   recorderController.onCurrentDuration.listen((duration){}); // Provides currently recorded duration of audio every 50 milliseconds.
   recorderController.onRecorderStateChanged.listen((state){}); // Provides current state of recorder.
   recorderController.onRecordingEnded.listen((duration){}); // Provided duration of the audio file after recording is ended. 
   ```
2. Get scrolled duration 
   ```dart
   recorderController.currentScrolledDuration;
   ```   
   A ValueNotifier which provides current position of scrolled waveform with respect to middle line.
   `shouldCalculateScrolledPosition` flag must be enabled to use it (available in AudioWaveform widget).
   For better idea how duration is reported, enable duration labels and scroll toward middle line.
   Reported duration is in **milliseconds**.
#### Other available parameters
```dart
recorderController.waveData; // The waveform data in form of normalised peak power for Ios and normalised peak amplitude for Android. The values are between 0.0 and 1.0.
recorderController.elapsedDuration; // Recorded duration of the file.
recorderController.recordedDuration; // Duration of recorded audio file when recording has been stopped. Until recording has been stopped, this duration will be zero(Duration.zero). Also, once new recording is started this duration will be reset to zero.
recorderController.hasPermission; // If we have microphone permission or not.
recorderController.isRecording; // If the recorder is currently recording.
recorderController.recorderState; // Current state of the recorder.
```

### Customizing the waveforms widget
```dart
AudioWaveforms(
  size: Size(MediaQuery.of(context).size.width, 200.0), // The size of your waveform widget.
  shouldCalculateScrolledPosition: true, // recorderController.currentScrolledDuration will notify only when this is enabled. 
  enableGesture: true, // Enable/disable scrolling of the waveforms. 
  waveStyle: WaveStyle(), // Customize how waveforms looks.
);
```
Using **WaveStyle**, you customize color, gradients, space between the waves, add duration legends and many more things.

## Player
### Quick example
This is a quick example showcasing how to show waveforms while playing an audio file,
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
        child: Text('play'),
      ),
      ElevatedButton(
        onPressed: () {
           playerController.pausePlayer();
        },
        child: Text('pause'),
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
#### How to prepare a player
1. Loading from assets
   - Before you set audio file path, you will need to load file into memory.
   ```dart
   File file = File('${appDirectory.path}/audio.mp3');
   final audioFile = await rootBundle.load('assets/audio.mp3');
   await file.writeAsBytes(audioFile.buffer.asUint8List());
   playerController.preparePlayer(path: file.path);
   ```
2. Loading from device storage
   - When you load a file from device storage, they are already in the memory so you can directly set the file path.    
3. Loading from network
   - Currently playing remote audio file isn't supported so first you will need to download it and then you can play it.  
4. Deciding if waveforms should be extracted with the preparePlayer
   ```dart
   playerController.preparePlayer(shouldExtractWaveform: true);
   ```
   **Note**-: When `shouldExtractWaveform` is enabled, with preparePlayer waveform data will also start to be extracted and `PlayerController` will hold the extracted waveform data so an `AudioFileWaveforms` widget with same PlayerController will always show same waveforms if it is rebuild or even if widget is removed from widget tree and added again.  
   
#### Customizing the Player
1. Choose how player should stop
   - FinishMode.loop: Plays audio file again after finishing it.
   - FinishMode.pause: Pauses at `0` millisecond after finishing the audio file.
   - FinishMode.stop: Stops the player at end and also releases resources taken the native player.
   ```dart
   playerController.startPlayer(finishMode: FinishMode.stop);
   ```
2. Set volume of the player
   ```dart
   playerController.setVolume(1.0); // Values should be between 0 and 1.
   ```
3. Update how fast audio file should be played
   ```dart
   playerController.setRate(1.0);
   ```
4. Seek to any position
   ```dart
   playerController.seekTo(5000); // Required value is in milliseconds.
   ```
#### Saving resources by precalculating the waveforms
You can precalculate waveforms by using `playerController.extractWaveformData()`.
This function gives back list of doubles which you can directly set into `AudioFileWaveforms` widget. Since calculating waveforms is expensive process, you can save this data somewhere and use it again when same file is used. 
```dart
final waveformData = await playerController.extractWaveformData(path: '../audioFile.mp3');

AudioFileWaveforms(
  ...
  waveformData: waveformData,
);
```

#### Listening to events from the player
```dart
playerController.onPlayerStateChanged.listen((state) {}); // Provides events when the player state changes.
playerController.onCurrentDurationChanged.listen((duration) {}); // Provides events when audio is sought to any duration.
playerController.onCurrentExtractedWaveformData.listen((data) {}); // Provides latest data while extracting the waveforms.
playerController.onExtractionProgress.listen((progress) {}); // Provides progress of the waveform extractions.
playerController.onCompletion.listen((_){}); // Provides events every time audio file is finished playing.  
```
#### Getting the current or maximum duration of the audio file
```dart
final fileLengthInDuration = await playerController.getDuration(DurationType.max);
final currentDuration = await playerController.getDuration(DurationType.current); // This is where file is paused or an in progress audio files current duration.
```
#### The types of waveforms
1. fitWidth
   ```dart
   AudioFileWaveforms(
    waveformType: WaveformType.fitWidth,
   );
   ```
   - These are the type of waveforms when you want the whole duration of the audio file's waveforms should fit in specified width.
   - With these type of waveforms, you can seek through audio with **tap** and **drag** gesture. 
   
   For this, you will need to provide number of samples for the width which you can get from the `PlayerWaveStyle`.
   ```dart
   final style = PlayerWaveStyle(...);
   final samples = style.getSamplesForWidth(screenWidth / 2);
   
   await playerController.preparePlayer(noOfSamples: samples); // extractWaveformData also has this parameter.
   ```
   **Note**-: If you don't provide number of samples then waveforms may get cut or won't fill whole space since default samples are 100.
2. long
   ```dart
   AudioFileWaveforms(
    waveformType: WaveformType.long,
   );
   ```
   - These are the type of waveforms which you want them get out side of widget bounds.
   - With these type of waveforms, you can seek through audio using **drag** gesture.
   - These waveforms will show completed part of the audio on left side and remaining part on the right side of the middle line.
   
   You may provide any number of samples for this.

#### Smoothening the waveforms seek animation
```dart
playerController.updateFrequency = UpdateFrequency.high;
```
There are 3 modes low, medium and high. Setting **updateFrequency** to `high` will update current progress of the playing file faster(every 50ms) which will mame waveform seek animation smooth and `low` makes slower(every 200ms) which could make seek animation a little laggy. You can update this according to device configuration.

#### Releasing resources of native player
```dart
playerController.release();
```
#### Stopping players all at once
```dart
playerController.stopAllPlayer();
```
There could be any number of players but you can just call this function from any **one** player and it will stop all the players.
#### Disposing the controller
```dart
playerController.dispose();
```
As a responsible flutter devs, we dispose our controllers and it will also release resources taken by a native player.

#### Customizing the AudioFileWaveforms widget
```dart
AudioFileWaveforms(
  continuousWaveform: true,
  playerWaveStyle: PlayerWaveStlye(),
);
```
- Enabling the `continuousWaveform` will show waveforms as soon as and as much as data is extracted. Disabling it show waveforms only after whole extraction process is complete.
- You can use PlayerWaveStyle to customize how waveforms looks. You can update waveform color, thickness, gradient, completed part, remaining part and much more.

#### Waveform scaling
```dart
PlayerWaveStyle(
  scaleFactor: 100,
  scrollScale: 1.2,
);
```
- Waveform data we get is very small value so we can scale them according to the our need using `scaleFactor`.
- If you want to provide some feedback when scrolling the waves then set `scrollScale` > 1.0.

## Main Contributors

<table>
  <tr>
    <td align="center"><a href="https://github.com/Ujas-Majithiya"><img src="https://avatars.githubusercontent.com/u/56400956?v=4" width="100px;" alt=""/><br /><sub><b>Ujas Majithiya</b></sub></a></td>
    <td align="center"><a href="https://github.com/DevarshRanpara"><img src="https://avatars.githubusercontent.com/u/26064415?s=100" width="100px;" alt=""/><br /><sub><b>Devarsh Ranpara</b></sub></a></td>
  </tr>
</table>