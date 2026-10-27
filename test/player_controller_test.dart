import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:audio_waveforms/src/base/constants.dart';
import 'package:audio_waveforms/src/base/platform_streams.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(Constants.methodChannelName);

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case Constants.getDuration:
          return 1000;
        default:
          return true;
      }
    });
    PlatformStreams.instance.playerControllerFactory.clear();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<PlayerController> preparedController() async {
    final controller = PlayerController();
    await controller.preparePlayer(
      path: '/audio.m4a',
      shouldExtractWaveform: false,
    );
    return controller;
  }

  test('pauseAllPlayers only pauses players which are playing', () async {
    final playing = await preparedController();
    await playing.startPlayer();

    final stopped = await preparedController();
    await stopped.startPlayer();
    await stopped.stopPlayer();

    final paused = await preparedController();
    await paused.startPlayer();
    await paused.pausePlayer();

    final initialized = await preparedController();

    expect(await playing.pauseAllPlayers(), isTrue);

    expect(playing.playerState, PlayerState.paused);
    expect(stopped.playerState, PlayerState.stopped);
    expect(paused.playerState, PlayerState.paused);
    expect(initialized.playerState, PlayerState.initialized);
  });
}
