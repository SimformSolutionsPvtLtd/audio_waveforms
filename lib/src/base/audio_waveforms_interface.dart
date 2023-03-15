part of '../controllers/player_controller.dart';

class AudioWaveformsInterface {
  AudioWaveformsInterface._();

  static AudioWaveformsInterface instance = AudioWaveformsInterface._();

  static const MethodChannel _methodChannel =
      MethodChannel(Constants.methodChannelName);

  ///platform call to start recording
  Future<bool> record({
    required int audioFormat,
    required int sampleRate,
    int? bitRate,
    String? path,
    bool useLegacyNormalization = false,
  }) async {
    final isRecording = await _methodChannel.invokeMethod(
      Constants.startRecording,
      Platform.isIOS
          ? {
              Constants.path: path,
              Constants.encoder: audioFormat,
              Constants.sampleRate: sampleRate,
              Constants.bitRate: bitRate,
              Constants.useLegacyNormalization: useLegacyNormalization,
            }
          : {
              Constants.useLegacyNormalization: useLegacyNormalization,
            },
    );
    return isRecording ?? false;
  }

  /// Platform call to initialise the recorder.
  /// This method is only required for Android platform.
  Future<bool> initRecorder({
    String? path,
    required int encoder,
    required int outputFormat,
    required int sampleRate,
    int? bitRate,
  }) async {
    final initialized = await _methodChannel.invokeMethod(
      Constants.initRecorder,
      {
        Constants.path: path,
        Constants.outputFormat: outputFormat,
        Constants.encoder: encoder,
        Constants.sampleRate: sampleRate,
        Constants.bitRate: bitRate,
      },
    );
    return initialized ?? false;
  }

  ///platform call to pause recording
  Future<bool?> pause() async {
    final isRecording =
        await _methodChannel.invokeMethod(Constants.pauseRecording);
    return isRecording;
  }

  ///platform call to stop recording
  Future<List<String?>?> stop() async {
    final audioInfo =
        await _methodChannel.invokeMethod(Constants.stopRecording);
    return List.from(audioInfo ?? []);
  }

  ///platform call to resume recording.
  ///This method is only required for Android platform
  Future<bool> resume() async {
    final isRecording =
        await _methodChannel.invokeMethod(Constants.resumeRecording);
    return isRecording ?? false;
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
  Future<bool> preparePlayer({
    required String path,
    required String key,
    required int frequency,
    double? volume,
  }) async {
    var result = await _methodChannel.invokeMethod(Constants.preparePlayer, {
      Constants.path: path,
      Constants.volume: volume,
      Constants.playerKey: key,
      Constants.updateFrequency: frequency,
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
  
  ///platform call to set rate
  Future<bool> setRate(double rate, String key) async {
    var result = await _methodChannel.invokeMethod(Constants.setRate, {
      Constants.rate: rate,
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

  Future<List<double>> extractWaveformData({
    required String key,
    required String path,
    required int noOfSamples,
  }) async {
    final result =
        await _methodChannel.invokeMethod(Constants.extractWaveformData, {
      Constants.playerKey: key,
      Constants.path: path,
      Constants.noOfSamples: noOfSamples,
    });
    return List<double>.from(result ?? []);
  }

  Future<bool> stopAllPlayers() async {
    var result = await _methodChannel.invokeMethod(Constants.stopAllPlayers);
    return result ?? false;
  }

  Future<void> setMethodCallHandler() async {
    _methodChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case Constants.onCurrentDuration:
          var duration = call.arguments[Constants.current];
          var key = call.arguments[Constants.playerKey];
          if (duration.runtimeType == int) {
            var identifier = PlayerIdentifier<int>(key, duration);
            PlatformStreams.instance.addCurrentDurationEvent(identifier);
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
          var stateIdentifier = PlayerIdentifier<PlayerState>(key, playerState);
          var completionIdentifier = PlayerIdentifier<void>(key, null);
          PlatformStreams.instance.addCompletionEvent(completionIdentifier);
          PlatformStreams.instance.addPlayerStateEvent(stateIdentifier);
          if (PlatformStreams.instance.playerControllerFactory[key] != null) {
            PlatformStreams.instance.playerControllerFactory[key]
                ?._playerState = playerState;
          }
          break;
        case Constants.onCurrentExtractedWaveformData:
          var key = call.arguments[Constants.playerKey];
          var progress = call.arguments[Constants.progress];
          var waveformData =
              List<double>.from(call.arguments[Constants.waveformData]);
          PlatformStreams.instance.addExtractedWaveformDataEvent(
            PlayerIdentifier<List<double>>(key, waveformData),
          );
          PlatformStreams.instance.addExtractionProgress(
            PlayerIdentifier<double>(key, progress),
          );
          break;
      }
    });
  }

  void removeMethodCallHandler() {
    _methodChannel.setMethodCallHandler(null);
  }
}
