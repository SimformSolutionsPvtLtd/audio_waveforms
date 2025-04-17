# Migration Guides
#
## Migrating from v0.x to v1.0

### Breaking Changes

1. **PlayerController Changes**
   - The `playerController.preparePlayer()` method now returns a `Future<void>` instead of `void`
   - Waveform extraction is now done through a separate controller: `playerController.waveformExtraction`

2. **WaveformExtraction Changes**
   - Waveform extraction functionality has been moved to its own controller
   - The `extractWaveformData()` method is now accessed via `playerController.waveformExtraction.extractWaveformData()`

### Migration Steps

#### Updating Player Initialization

**Before:**
```dart
playerController.preparePlayer(path: filePath);
// Code that depends on player being ready
```

**After:**
```dart
await playerController.preparePlayer(path: filePath);
// Code that depends on player being ready
```

#### Updating Waveform Extraction

**Before:**
```dart
final waveformData = await playerController.extractWaveformData(path: filePath);
```

**After:**
```dart
final waveformData = await playerController.waveformExtraction.extractWaveformData(path: filePath);
```

#### Updating Event Listeners

**Before:**
```dart
playerController.onCurrentExtractedWaveformData.listen((data) {
  // Handle waveform data
});

playerController.onExtractionProgress.listen((progress) {
  // Handle extraction progress
});
```

**After:**
```dart
playerController.waveformExtraction.onCurrentExtractedWaveformData.listen((data) {
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
recorderController.checkPermission();
if (recorderController.hasPermission) {
  // Start recording
}
```

**After:**
```dart
final hasPermission = await recorderController.checkPermission();
if (hasPermission) {
  // Start recording
}
```

#### Updating AudioFileWaveforms Widget

**Before:**
```dart
AudioFileWaveforms(
  size: Size(300, 70),
  playerController: playerController,
);
```

**After:**
```dart
AudioFileWaveforms(
  controller: playerController,
  size: Size(300, 70),
  waveformType: WaveformType.fitWidth,
);
```

#### Updating WaveStyle

**Before:**
```dart
WaveStyle(
  showDurationLabel: false,
  spacing: 5.0,
);
```

**After:**
```dart
WaveStyle(
  showDurationLabel: false,
  spacing: 5.0,
  durationStyle: DurationStyle.timeLeft,
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
playerController.preparePlayer(
  path: filePath,
  shouldExtractWaveform: true,
);
```

**After:**
```dart
playerController.updateFrequency = UpdateFrequency.high;
await playerController.preparePlayer(
  path: filePath,
  shouldExtractWaveform: true,
);
```

#### Using Standalone Waveform Extraction

**Before:**
```dart
final waveformData = await playerController.waveformExtraction.extractWaveformData(path: filePath);
```

**After:**
You can still use the previous method, or use the standalone controller:
```dart
final waveformExtraction = WaveformExtractionController();
final waveformData = await waveformExtraction.extractWaveformData(path: filePath);
```
