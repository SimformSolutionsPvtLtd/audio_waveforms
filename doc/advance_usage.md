**Advance usage**
```dart
controller.updateFrequency = const Duration(milliseconds: 100);  // Update speed of new wave
controller.androidEncoder = AndroidEncoder.aac;                  // Changing android encoder 
controller.androidOutputFormat = AndroidOutputFormat.mpeg4;      // Changing android output format
controller.iosEncoder = IosEncoder.kAudioFormatMPEG4AAC;         // Changing ios encoder
controller.sampleRate = 44100;                                   // Updating sample rate
controller.bitRate = null;                                       // Updating bitrate
controller.onRecorderStateChanged.listen((state){});             // Listening to recorder state changes
controller.onCurrentDuration.listen((duration){});               // Listening to current duration updates
controller.onRecordingEnded.listen((duration));                  // Listening to audio file duration
controller.recordedDuration;                                     // Get recorded audio duration 
controller.elapsedDuration;                                      // Get currently recorded audio duration
controller.currentScrolledDuration;                              // Current duration position notifier
controller.overrideAudioSession = true                           // Use default AudioSession config or not 
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
await controller.setRate(1.0);                                      // Update speed audio playback
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