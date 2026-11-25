# Testing code that uses audio_waveforms

Mock the plugin's method channel `simform_audio_waveforms_plugin/methods`. The name is internal, but it is the only seam:

```dart
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // controllers need the binding

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('simform_audio_waveforms_plugin/methods'),
      (call) async => switch (call.method) {
        'getDuration' => 3000,
        'extractWaveformData' => <double>[0.2, 0.5, 0.8],
        'stopRecording' => {
            'resultFilePath': '/tmp/a.m4a',
            'resultDuration': 3000
          },
        'stopExtraction' || 'finishMode' => null,
        'pauseRecording' => false, // native returns "is still recording"
        _ => true, // preparePlayer, startPlayer, checkPermission, ...
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('simform_audio_waveforms_plugin/methods'),
      null,
    );
  });

  testWidgets('renders player waveform', (tester) async {
    final player = PlayerController();
    await player.preparePlayer(
        path: '/tmp/a.m4a', shouldExtractWaveform: false);
    await tester.pumpWidget(
      MaterialApp(
        home: AudioFileWaveforms(
          size: const Size(200, 50),
          playerController: player,
          waveformData: const [0.2, 0.5, 0.8],
        ),
      ),
    );
    expect(player.playerState, PlayerState.initialized);
    expect(player.maxDuration, 3000);
    await player.startPlayer();
    expect(player.playerState, PlayerState.playing);
    player.dispose();
  });
}
```

Without the binding, creating a controller fails with "Cannot set the method call handler…". Without the mock, calls throw `MissingPluginException`. `record()` branches on `dart:io` `Platform`, so on a Linux or Windows test host it does nothing; recorder tests only exercise the code on a macOS host (iOS/macOS path).
