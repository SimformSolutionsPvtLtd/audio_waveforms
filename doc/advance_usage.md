# Advanced Usage
#

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
// FinishMode options: loop, pause, stop
```

### Extracting and Using Waveform Data

```dart
// Extract waveform data for reuse
final waveformData = await playerController.waveformExtraction.extractWaveformData(
  path: '../audioFile.mp3',
  noOfSamples: 100,
);

// Apply waveform data to widget
AudioFileWaveforms(
  controller: playerController,
  size: Size(300, 50),
  waveformData: waveformData,
);

// Stop waveform extraction if needed
playerController.waveformExtraction.stopWaveformExtraction();
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
