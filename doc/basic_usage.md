## Basic usage
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