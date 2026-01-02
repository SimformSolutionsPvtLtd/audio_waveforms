part of '../controllers/player_controller.dart';

class AudioWaveformsInterface {
  AudioWaveformsInterface._();

  static AudioWaveformsInterface instance = AudioWaveformsInterface._();

  static const MethodChannel _methodChannel =
      MethodChannel(Constants.methodChannelName);

  ///platform call to start recording
  Future<bool> record({
    required RecorderSettings recorderSetting,
    String? path,
    bool overrideAudioSession = true,
  }) async {
    final isRecording = await _methodChannel.invokeMethod(
      Constants.startRecording,
      Platform.isIOS
          ? recorderSetting.iosToJson(
              path: path,
              overrideAudioSession: overrideAudioSession,
            )
          : null,
    );
    return isRecording ?? false;
  }

  /// Platform call to initialise the recorder.
  /// This method is only required for Android platform.
  Future<bool> initRecorder({
    String? path,
    required RecorderSettings recorderSettings,
  }) async {
    final initialized = await _methodChannel.invokeMethod(
      Constants.initRecorder,
      recorderSettings.androidToJson(path: path),
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
  Future<Map<String, dynamic>> stop() async {
    Map<Object?, Object?> audioInfo =
        await _methodChannel.invokeMethod(Constants.stopRecording);
    return audioInfo.cast<String, dynamic>();
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
    bool overrideAudioSession = false,
  }) async {
    var result = await _methodChannel.invokeMethod(Constants.preparePlayer, {
      Constants.path: path,
      Constants.volume: volume,
      Constants.playerKey: key,
      Constants.updateFrequency: frequency,
      Constants.overrideAudioSession: overrideAudioSession,
    });
    return result ?? false;
  }

  ///platform call to start player
  Future<bool> startPlayer(String key) async {
    var result = await _methodChannel.invokeMethod(Constants.startPlayer, {
      Constants.playerKey: key,
    });
    return result ?? false;
  }

  ///platform call to stop player
  Future<bool> stopPlayer(String key) async {
    var result = await _methodChannel.invokeMethod(Constants.stopPlayer, {
      Constants.playerKey: key,
    });
    return result ?? false;
  }

  ///platform call to release resource
  Future<bool> release(String key) async {
    var result = await _methodChannel.invokeMethod(Constants.releasePlayer, {
      Constants.playerKey: key,
    });
    return result ?? false;
  }

  ///platform call to pause player
  Future<bool> pausePlayer(String key) async {
    var result = await _methodChannel.invokeMethod(Constants.pausePlayer, {
      Constants.playerKey: key,
    });
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
    var result = await _methodChannel.invokeMethod(
      Constants.seekTo,
      {
        Constants.progress: progress,
        Constants.playerKey: key,
      },
    );
    return result ?? false;
  }

  /// Sets the release mode.
  Future<void> setReleaseMode(String key, FinishMode finishMode) async {
    return await _methodChannel.invokeMethod(Constants.finishMode, {
      Constants.finishType: finishMode.index,
      Constants.playerKey: key,
    });
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

  /// Stops current executing waveform extraction, if any.
  Future<void> stopWaveformExtraction(String key) async {
    return await _methodChannel.invokeMethod(Constants.stopExtraction, {
      Constants.playerKey: key,
    });
  }

  Future<bool> stopAllPlayers() async {
    var result = await _methodChannel.invokeMethod(Constants.stopAllPlayers);
    return result ?? false;
  }

  Future<bool> pauseAllPlayers() async {
    var result = await _methodChannel.invokeMethod(Constants.pauseAllPlayers);
    return result ?? false;
  }

  Future<void> setMethodCallHandler() async {
    _methodChannel.setMethodCallHandler((call) async {
      final instance = PlatformStreams.instance;
      switch (call.method) {
        case Constants.onCurrentDuration:
          final duration = call.arguments[Constants.current];
          final key = call.arguments[Constants.playerKey];
          if (duration.runtimeType == int) {
            final identifier = PlayerIdentifier<int>(key, duration);
            instance.addCurrentDurationEvent(identifier);
          }
          break;
        case Constants.onDidFinishPlayingAudio:
          final key = call.arguments[Constants.playerKey];
          final playerState =
              getPlayerState(call.arguments[Constants.finishType]);
          final stateIdentifier =
              PlayerIdentifier<PlayerState>(key, playerState);
          final completionIdentifier = PlayerIdentifier<void>(key, null);
          instance
            ..addCompletionEvent(completionIdentifier)
            ..addPlayerStateEvent(stateIdentifier)
            ..playerControllerFactory[key]?._playerState = playerState;
          break;
        case Constants.onCurrentExtractedWaveformData:
          var key = call.arguments[Constants.playerKey];
          var progress = call.arguments[Constants.progress];
          var waveformData =
              List<double>.from(call.arguments[Constants.waveformData]);
          instance.addExtractedWaveformDataEvent(
            PlayerIdentifier<List<double>>(key, waveformData),
          );
          instance.addExtractionProgress(
            PlayerIdentifier<double>(key, progress),
          );
          break;
        case Constants.onAudioChunk:
          final normalisedRms = call.arguments[Constants.normalisedRms];
          final bytes = call.arguments[Constants.bytes];
          final recordedDuration = call.arguments[Constants.recordedDuration];
          if (normalisedRms is double) {
            instance.addAmplitudeEvent(normalisedRms);
          }
          if (bytes is Uint8List) {
            instance.addRecordedBytes(bytes);
          }
          if (recordedDuration is int) {
            instance.addRecordedDurationEvent(recordedDuration);
          }
          break;
      }
    });
  }

  PlayerState getPlayerState(int finishModel) {
    switch (finishModel) {
      case 0:
        return PlayerState.playing;
      case 1:
        return PlayerState.paused;
      default:
        return PlayerState.stopped;
    }
  }

  void removeMethodCallHandler() {
    _methodChannel.setMethodCallHandler(null);
  }
}
