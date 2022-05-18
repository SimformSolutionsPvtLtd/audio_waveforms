part of '../controllers/player_controller.dart';

class AudioWaveformsInterface {
  AudioWaveformsInterface._();

  static AudioWaveformsInterface instance = AudioWaveformsInterface._();

  static const MethodChannel _methodChannel =
      MethodChannel(Constants.methodChannelName);

  ///platform call to start recording
  Future<bool> record(int audioFormat, int sampleRate, [String? path]) async {
    final _isRecording = await _methodChannel.invokeMethod(
        Constants.startRecording,
        Platform.isIOS
            ? {
                Constants.path: path,
                Constants.encoder: audioFormat,
                Constants.sampleRate: sampleRate,
              }
            : null);
    return _isRecording ?? false;
  }

  ///platform call to initialise the recorder.
  ///This method is only required for Android platform
  Future<bool> initRecorder(
      String? path, int encoder, int outputFormat, int sampleRate) async {
    final initialized = await _methodChannel.invokeMethod(
      Constants.initRecorder,
      {
        Constants.path: path,
        Constants.outputFormat: outputFormat,
        Constants.encoder: encoder,
        Constants.sampleRate: sampleRate,
      },
    );
    return initialized ?? false;
  }

  ///platform call to pause recording
  Future<bool?> pause() async {
    final _isRecording =
        await _methodChannel.invokeMethod(Constants.pauseRecording);
    return _isRecording;
  }

  ///platform call to stop recording
  Future<String?> stop() async {
    final _isRecording =
        await _methodChannel.invokeMethod(Constants.stopRecording);
    return _isRecording;
  }

  ///platform call to resume recording.
  ///This method is only required for Android platform
  Future<bool> resume() async {
    final _isRecording =
        await _methodChannel.invokeMethod(Constants.resumeRecording);
    return _isRecording ?? false;
  }

  ///platform call to get decibel
  Future<double?> getDecibel() async {
    var db = await _methodChannel.invokeMethod(Constants.getDecibel);
    return db;
  }

  ///platform call to check microphone permission
  Future<bool> checkPermission() async {
    var hasPermission =
        await _methodChannel.invokeMethod(Constants.checkPermission);
    return hasPermission ?? false;
  }

  ///platform call to prepare player
  Future<bool> preparePlayer(String path, String key, [double? volume]) async {
    var result = await _methodChannel.invokeMethod(Constants.preparePlayer, {
      Constants.path: path,
      Constants.volume: volume,
      Constants.playerKey: key,
    });
    return result ?? false;
  }

  ///platform call to start player
  Future<bool> startPlayer(String key, FinishMode finishMode) async {
    var result = await _methodChannel.invokeMethod(Constants.startPlayer, {
      Constants.playerKey: key,
      Constants.finishMode: finishMode.index,
    });
    return result ?? false;
  }

  ///platform call to stop player
  Future<bool> stopPlayer(String key) async {
    var result = await _methodChannel
        .invokeMethod(Constants.stopPlayer, {Constants.playerKey: key});
    return result ?? false;
  }

  ///platform call to pause player
  Future<bool> pausePlayer(String key) async {
    var result = await _methodChannel
        .invokeMethod(Constants.pausePlayer, {Constants.playerKey: key});
    return result ?? false;
  }

  ///platform call to get duration max/current
  Future<int?> getDuration(String key, int durationType) async {
    var duration = await _methodChannel.invokeMethod(Constants.getDuration, {
      Constants.durationType: durationType,
      Constants.playerKey: key,
    });
    return duration;
  }

  ///platform call to set volume
  Future<bool> setVolume(double volume, String key) async {
    var result = await _methodChannel.invokeMethod(Constants.setVolume, {
      Constants.volume: volume,
      Constants.playerKey: key,
    });
    return result ?? false;
  }

  ///platform call to seek audio at provided position
  Future<bool> seekTo(String key, int progress) async {
    var result = await _methodChannel.invokeMethod(Constants.seekTo,
        {Constants.progress: progress, Constants.playerKey: key});
    return result ?? false;
  }

  Future<bool> stopAllPlayers() async {
    var result = await _methodChannel.invokeMethod(Constants.stopAllPlayers);
    return result ?? false;
  }

  void setMethodCallHandler() async {
    _methodChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case Constants.onCurrentDuration:
          var duration = call.arguments[Constants.current];
          var key = call.arguments[Constants.playerKey];
          if (duration.runtimeType == int) {
            var indentifier = PlayerIdentifier<int>(key, duration);
            PlatformStreams.instance.addCurrentDurationEvent(indentifier);
          }
          break;
        case Constants.onDidFinishPlayingAudio:
          var key = call.arguments[Constants.playerKey];
          var playerState = (call.arguments[Constants.finishtype] is int) &&
                  call.arguments[Constants.finishtype] == 0
              ? PlayerState.playing
              : call.arguments[Constants.finishtype] == 1
                  ? PlayerState.paused
                  : PlayerState.stopped;
          var indentifier = PlayerIdentifier<PlayerState>(key, playerState);
          PlatformStreams.instance.addPlayerStateEvent(indentifier);
          if (PlatformStreams.instance.playerControllerFactory[key] != null) {
            PlatformStreams.instance.playerControllerFactory[key]
                ?._playerState = playerState;
          }
          break;
      }
    });
  }

  void removeMethodCallHandeler() {
    _methodChannel.setMethodCallHandler(null);
  }
}
