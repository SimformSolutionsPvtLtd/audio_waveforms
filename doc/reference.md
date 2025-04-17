# API References

#

## RecorderController

### Constructor

`RecorderController()`

### Properties

| Property                  | Type                 | Description                                  |
|---------------------------|----------------------|----------------------------------------------|
| `waveData`                | `List<double>`       | Normalized waveform data between 0.0 and 1.0 |
| `elapsedDuration`         | `Duration`           | Current recorded duration                    |
| `recordedDuration`        | `Duration`           | Duration after recording is stopped          |
| `hasPermission`           | `bool`               | Whether microphone permission is granted     |
| `isRecording`             | `bool`               | Whether recording is in progress             |
| `recorderState`           | `RecorderState`      | Current state of the recorder                |
| `updateFrequency`         | `Duration`           | Rate at which waveforms are updated          |
| `overrideAudioSession`    | `bool`               | Whether to override iOS audio session        |
| `currentScrolledDuration` | `ValueNotifier<int>` | Current scrolled position                    |

### Methods

| Method            | Parameters                                           | Return Type       | Description                         |
|-------------------|------------------------------------------------------|-------------------|-------------------------------------|
| `record`          | `{String? path, RecorderSettings? recorderSettings}` | `void`            | Start recording audio               |
| `pause`           | -                                                    | `void`            | Pause recording                     |
| `stop`            | `[bool callReset = true]`                            | `Future<String?>` | Stop recording and return file path |
| `reset`           | -                                                    | `void`            | Clear waveforms and duration        |
| `refresh`         | -                                                    | `void`            | Reset scroll position               |
| `checkPermission` | -                                                    | `Future<bool>`    | Check microphone permission         |
| `dispose`         | -                                                    | `void`            | Dispose controller and recorder     |

### Streams

| Stream                   | Type                    | Description                |
|--------------------------|-------------------------|----------------------------|
| `onCurrentDuration`      | `Stream<Duration>`      | Current recording duration |
| `onRecorderStateChanged` | `Stream<RecorderState>` | Recorder state changes     |
| `onRecordingEnded`       | `Stream<Duration>`      | Recording ended event      |

## PlayerController

### Constructor

`PlayerController()`

### Methods

| Method            | Parameters                                                                     | Return Type    | Description                     |
|-------------------|--------------------------------------------------------------------------------|----------------|---------------------------------|
| `preparePlayer`   | `{required String path, bool shouldExtractWaveform = false, int? noOfSamples}` | `Future<void>` | Prepare player with audio file  |
| `startPlayer`     | -                                                                              | `Future<void>` | Start audio playback            |
| `pausePlayer`     | -                                                                              | `Future<void>` | Pause audio playback            |
| `stopPlayer`      | -                                                                              | `Future<void>` | Stop audio playback             |
| `seekTo`          | `int milliseconds`                                                             | `Future<void>` | Seek to position                |
| `setVolume`       | `double volume`                                                                | `Future<void>` | Set player volume               |
| `setRate`         | `double rate`                                                                  | `Future<void>` | Set playback speed              |
| `setFinishMode`   | `{required FinishMode finishMode}`                                             | `void`         | Set behavior on finish          |
| `getDuration`     | `DurationType durationType`                                                    | `Future<int>`  | Get current or max duration     |
| `release`         | -                                                                              | `Future<void>` | Release native player resources |
| `stopAllPlayers`  | -                                                                              | `Future<void>` | Stop all players                |
| `pauseAllPlayers` | -                                                                              | `Future<void>` | Pause all players               |
| `dispose`         | -                                                                              | `void`         | Dispose controller and player   |

### Properties

| Property             | Type                           | Description                        |
|----------------------|--------------------------------|------------------------------------|
| `updateFrequency`    | `UpdateFrequency`              | Rate at which progress is updated  |
| `waveformExtraction` | `WaveformExtractionController` | Controller for waveform extraction |

### Streams

| Stream                     | Type                  | Description               |
|----------------------------|-----------------------|---------------------------|
| `onPlayerStateChanged`     | `Stream<PlayerState>` | Player state changes      |
| `onCurrentDurationChanged` | `Stream<int>`         | Current playback position |
| `onCompletion`             | `Stream<void>`        | Playback completion event |

## WaveformExtractionController

### Constructor

`WaveformExtractionController()`

### Methods

| Method                   | Parameters                                 | Return Type            | Description             |
|--------------------------|--------------------------------------------|------------------------|-------------------------|
| `extractWaveformData`    | `{required String path, int? noOfSamples}` | `Future<List<double>>` | Extract waveform data   |
| `stopWaveformExtraction` | -                                          | `void`                 | Stop extraction process |

### Streams

| Stream                           | Type                   | Description            |
|----------------------------------|------------------------|------------------------|
| `onCurrentExtractedWaveformData` | `Stream<List<double>>` | Current extracted data |
| `onExtractionProgress`           | `Stream<double>`       | Extraction progress    |

## AudioWaveforms (Recorder Widget)

### Constructor

`AudioWaveforms({required RecorderController controller, required Size size, bool enableGesture = true, bool shouldCalculateScrolledPosition = false, WaveStyle waveStyle = const WaveStyle()})`

### Parameters

| Parameter                         | Type                 | Description                 |
|-----------------------------------|----------------------|-----------------------------|
| `controller`                      | `RecorderController` | Controller for this widget  |
| `size`                            | `Size`               | Size of the waveform widget |
| `enableGesture`                   | `bool`               | Enable scroll gestures      |
| `shouldCalculateScrolledPosition` | `bool`               | Calculate scrolled position |
| `waveStyle`                       | `WaveStyle`          | Style for the waveforms     |

## AudioFileWaveforms (Player Widget)

### Constructor

`AudioFileWaveforms({required PlayerController controller, required Size size, WaveformType waveformType = WaveformType.fitWidth, bool continuousWaveform = false, List<double>? waveformData, PlayerWaveStyle playerWaveStyle = const PlayerWaveStyle()})`

### Parameters

| Parameter            | Type               | Description                 |
|----------------------|--------------------|-----------------------------|
| `controller`         | `PlayerController` | Controller for this widget  |
| `size`               | `Size`             | Size of the waveform widget |
| `waveformType`       | `WaveformType`     | Type of waveform display    |
| `continuousWaveform` | `bool`             | Show waveforms continuously |
| `waveformData`       | `List<double>?`    | Pre-extracted waveform data |
| `playerWaveStyle`    | `PlayerWaveStyle`  | Style for the waveforms     |

## WaveStyle

### Constructor

`WaveStyle({this.showMiddleLine = true, this.extendWaveform = true, this.showDurationLabel = true, this.spacing = 8.0, Color? waveColor, this.gradient, this.middleLineColor = Colors.red, this.middleLineThickness = 2.0, this.labelSpacing = 60, this.durationLinesColor = Colors.red, this.durationTextStyle, this.durationStyle, this.durationTextPadding = const EdgeInsets.only(right: 20.0), this.durationLinesHeight = 16.0, this.showBottom = true, this.bottomPadding = 12.0})`

### Parameters

| Parameter             | Type             | Description                |
|-----------------------|------------------|----------------------------|
| `showMiddleLine`      | `bool`           | Show middle line           |
| `extendWaveform`      | `bool`           | Extend waveform to edges   |
| `showDurationLabel`   | `bool`           | Show duration labels       |
| `spacing`             | `double`         | Space between waveforms    |
| `waveColor`           | `Color?`         | Color of waveforms         |
| `gradient`            | `Gradient?`      | Gradient for waveforms     |
| `middleLineColor`     | `Color`          | Color of middle line       |
| `middleLineThickness` | `double`         | Thickness of middle line   |
| `labelSpacing`        | `double`         | Space between labels       |
| `durationLinesColor`  | `Color`          | Color of duration lines    |
| `durationTextStyle`   | `TextStyle?`     | Style for duration text    |
| `durationStyle`       | `DurationStyle?` | Style for duration display |
| `durationTextPadding` | `EdgeInsets`     | Padding for duration text  |
| `durationLinesHeight` | `double`         | Height of duration lines   |
| `showBottom`          | `bool`           | Show bottom padding        |
| `bottomPadding`       | `double`         | Bottom padding amount      |

## PlayerWaveStyle

### Constructor

`PlayerWaveStyle({this.fixedWaveColor = Colors.blue, this.liveWaveColor = Colors.red, this.scrollScale = 1.0, this.waveCap = StrokeCap.round, this.waveThickness = 3.0, this.showBottom = true, this.showSeekLine = true, this.seekLineColor = Colors.red, this.seekLineThickness = 2.0, this.showMiddleLine = true, this.showTop = true, this.spacing = 6.0, this.showHourInDuration = false, this.scaleFactor = 80.0, this.bottomPadding = 10.0, this.topPadding = 10.0, this.borderRadiusValue = 0.0, this.waveBorderRadius = true, this.seekLineGradient, this.liveWaveGradient, this.fixedWaveGradient})`

### Parameters

| Parameter            | Type        | Description                  |
|----------------------|-------------|------------------------------|
| `fixedWaveColor`     | `Color`     | Color of fixed waves         |
| `liveWaveColor`      | `Color`     | Color of live waves          |
| `scrollScale`        | `double`    | Scale when scrolling         |
| `waveCap`            | `StrokeCap` | Cap style for waves          |
| `waveThickness`      | `double`    | Thickness of waves           |
| `showBottom`         | `bool`      | Show bottom padding          |
| `showSeekLine`       | `bool`      | Show seek line               |
| `seekLineColor`      | `Color`     | Color of seek line           |
| `seekLineThickness`  | `double`    | Thickness of seek line       |
| `showMiddleLine`     | `bool`      | Show middle line             |
| `showTop`            | `bool`      | Show top padding             |
| `spacing`            | `double`    | Space between waves          |
| `showHourInDuration` | `bool`      | Show hour in duration        |
| `scaleFactor`        | `double`    | Scale factor for waves       |
| `bottomPadding`      | `double`    | Bottom padding amount        |
| `topPadding`         | `double`    | Top padding amount           |
| `borderRadiusValue`  | `double`    | Border radius value          |
| `waveBorderRadius`   | `bool`      | Apply border radius to waves |
| `seekLineGradient`   | `Gradient?` | Gradient for seek line       |
| `liveWaveGradient`   | `Gradient?` | Gradient for live waves      |
| `fixedWaveGradient`  | `Gradient?` | Gradient for fixed waves     |

### Methods

| Method               | Parameters     | Return Type | Description                 |
|----------------------|----------------|-------------|-----------------------------|
| `getSamplesForWidth` | `double width` | `int`       | Calculate samples for width |

## Enums

### RecorderState

- `initialized`
- `recording`
- `paused`
- `stopped`

### PlayerState

- `initialized`
- `playing`
- `paused`
- `stopped`

### DurationType

- `current`
- `max`

### FinishMode

- `loop`
- `pause`
- `stop`

### UpdateFrequency

- `low` (200ms)
- `medium` (100ms)
- `high` (50ms)

### WaveformType

- `fitWidth`
- `long`
