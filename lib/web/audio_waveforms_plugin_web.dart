import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import '../src/base/constants.dart';
import 'audio_player_web.dart';
import 'waveform_extractor_web.dart';

/// Web implementation of the AudioWaveforms plugin
/// This class serves as the main entry point for web platform
/// and delegates functionality to specialized web implementations
class AudioWaveformsPluginWeb {
  AudioWaveformsPluginWeb(this._channel);

  /// Waveform extractor implementation for web
  final WaveformExtractorWeb _waveformExtractor = WaveformExtractorWeb();

  /// Method channel for communication with Flutter
  late final MethodChannel _channel;

  /// Map to store audio players for each key
  final Map<String, AudioPlayerWeb> _audioPlayers = {};

  /// Registers this class as the web plugin implementation
  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel(
      Constants.methodChannelName,
      const StandardMethodCodec(),
      registrar,
    );

    final AudioWaveformsPluginWeb pluginInstance =
        AudioWaveformsPluginWeb(channel);
    channel.setMethodCallHandler(pluginInstance.handleMethodCall);
  }

  /// Handles method calls from the platform interface
  Future<dynamic> handleMethodCall(MethodCall call) async {
    final args = call.arguments as Map<dynamic, dynamic>?;

    switch (call.method) {
      // Player methods - delegated to AudioPlayerWeb
      case Constants.preparePlayer:
        final key = args?[Constants.playerKey] as String?;
        if (key != null) {
          _initPlayer(key);
          return _audioPlayers[key]?.preparePlayer(call.arguments);
        } else {
          throw PlatformException(
            code: Constants.audioWaveforms,
            message: Constants.cannotPreparePlayer,
            details: Constants.playerKeyIsNull,
          );
        }

      case Constants.startPlayer:
        final key = args?[Constants.playerKey] as String?;
        if (key != null) {
          return _audioPlayers[key]?.startPlayer();
        } else {
          throw PlatformException(
            code: Constants.audioWaveforms,
            message: Constants.cannotStartPlayer,
            details: Constants.playerKeyIsNull,
          );
        }

      case Constants.pausePlayer:
        final key = args?[Constants.playerKey] as String?;
        if (key != null) {
          return _audioPlayers[key]?.pausePlayer();
        } else {
          throw PlatformException(
            code: Constants.audioWaveforms,
            message: Constants.cannotPausePlayer,
            details: Constants.playerKeyIsNull,
          );
        }

      case Constants.stopPlayer:
        final key = args?[Constants.playerKey] as String?;
        if (key != null) {
          return _audioPlayers[key]?.stopPlayer();
        } else {
          throw PlatformException(
            code: Constants.audioWaveforms,
            message: Constants.cannotStopPlayer,
            details: Constants.playerKeyIsNull,
          );
        }

      case Constants.releasePlayer:
        final key = args?[Constants.playerKey] as String?;
        if (key != null) {
          final player = _audioPlayers[key];
          if (player != null) {
            // Dispose the player properly
            await player.dispose();
            // Remove from the map
            _audioPlayers.remove(key);
          }
          return true;
        } else {
          throw PlatformException(
            code: Constants.audioWaveforms,
            message: Constants.cannotReleasePlayer,
            details: Constants.playerKeyIsNull,
          );
        }

      case Constants.getDuration:
        final key = args?[Constants.playerKey] as String?;
        final durationType = args?[Constants.durationType] as int?;
        if (key != null && durationType != null) {
          return _audioPlayers[key]?.getDuration(durationType);
        } else {
          throw PlatformException(
            code: Constants.audioWaveforms,
            message: Constants.cannotGetDuration,
            details: Constants.playerKeyOrDurationTypeIsNull,
          );
        }

      case Constants.seekTo:
        final key = args?[Constants.playerKey] as String?;
        final progress = args?[Constants.progress] as int?;
        if (key != null && progress != null) {
          return _audioPlayers[key]?.seekTo(progress);
        } else {
          throw PlatformException(
            code: Constants.audioWaveforms,
            message: Constants.cannotSeekToPosition,
            details: Constants.playerKeyOrProgressIsNull,
          );
        }

      case Constants.setVolume:
        final key = args?[Constants.playerKey] as String?;
        final volume = args?[Constants.volume] as double?;
        if (key != null && volume != null) {
          return _audioPlayers[key]?.setVolume(volume);
        } else {
          throw PlatformException(
            code: Constants.audioWaveforms,
            message: Constants.cannotSetVolume,
            details: Constants.playerKeyOrVolumeIsNull,
          );
        }

      case Constants.setRate:
        final key = args?[Constants.playerKey] as String?;
        final rate = args?[Constants.rate] as double?;
        if (key != null && rate != null) {
          return _audioPlayers[key]?.setRate(rate);
        } else {
          throw PlatformException(
            code: Constants.audioWaveforms,
            message: Constants.cannotSetRate,
            details: Constants.playerKeyOrRateIsNull,
          );
        }

      case Constants.stopAllPlayers:
        for (final key in _audioPlayers.keys.toList()) {
          await _audioPlayers[key]?.stopPlayer();
        }
        return true;

      case Constants.pauseAllPlayers:
        for (final player in _audioPlayers.values) {
          await player.pausePlayer();
        }
        return true;

      case Constants.finishMode:
        final key = args?[Constants.playerKey] as String?;
        final finishType = args?[Constants.finishType] as int?;
        if (key != null) {
          return _audioPlayers[key]?.setFinishMode(finishType);
        } else {
          throw PlatformException(
            code: Constants.audioWaveforms,
            message: Constants.cannotSetFinishMode,
            details: Constants.playerKeyIsNull,
          );
        }

      // Waveform extraction - delegated to WaveformExtractorWeb
      case Constants.extractWaveformData:
        return _waveformExtractor.extractWaveformData(call.arguments);

      // Recorder methods - not supported on web platform
      case Constants.initRecorder:
      case Constants.startRecording:
      case Constants.stopRecording:
      case Constants.pauseRecording:
      case Constants.resumeRecording:
      case Constants.getDecibel:
      case Constants.checkPermission:
        throw PlatformException(
          code: Constants.unsupported,
          message: Constants.recordingNotSupportedOnWeb,
          details:
              'The method \'${call.method}\' ${Constants.methodNotAvailableForWeb}',
        );

      default:
        throw PlatformException(
          code: Constants.unimplemented,
          message:
              'The method \'${call.method}\' ${Constants.methodNotImplementedOnWeb}',
          details:
              '${Constants.audioWaveformsDoesNotImplement} \'${call.method}\'',
        );
    }
  }

  /// Initializes a new audio player for the given key if it doesn't exist
  void _initPlayer(String playerKey) {
    if (_audioPlayers[playerKey] == null) {
      _audioPlayers[playerKey] = AudioPlayerWeb(
        onDurationUpdate: (currentTime) {
          _channel.invokeMethod(
            Constants.onCurrentDuration,
            {
              Constants.playerKey: playerKey,
              Constants.current: currentTime,
            },
          );
        },
        onCompletion: () {
          _channel.invokeMethod(
            Constants.onDidFinishPlayingAudio,
            {
              Constants.playerKey: playerKey,
              Constants.finishType:
                  2, // 2 = stopped (default finish mode on web)
            },
          );
        },
      );
    }
  }

  /// Dispose all resources
  void dispose() {
    for (final player in _audioPlayers.values) {
      player.dispose();
    }
    _audioPlayers.clear();
  }
}
