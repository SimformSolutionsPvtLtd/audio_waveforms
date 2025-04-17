# Basic Usage
#
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
