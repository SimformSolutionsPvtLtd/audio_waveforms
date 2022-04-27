import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:audio_waveforms/src/base/audio_waveforms_interface.dart';
import 'package:audio_waveforms/src/base/platform_streams.dart';
import 'package:flutter/material.dart';

class PlayerController extends ChangeNotifier {
  Uint8List? _bufferData;

  ///provides data we got after reading audio file
  Uint8List? get bufferData => _bufferData;

  PlayerState _playerState = PlayerState.stopped;

  ///provides current state of the player
  PlayerState get playerState => _playerState;

  String? _audioFilePath;

  int _maxDuration = -1;

  ///provides [max] duration of currenly provided audio file.
  int get maxDuration => _maxDuration;

  bool _seekToStart = true;

  final UniqueKey _playerKey = UniqueKey();

  String get playerKey => _playerKey.toString();

  PlayerController() {
    AudioWaveformsInterface.instance.setMethodCallHandler();
  }

  ///Reads bytes from audio file
  Future<void> _readAudioFile(String path) async {
    _audioFilePath = path;
    File file = File(path);
    if (await file.exists()) {
      var bytes = await file.readAsBytes();
      _bufferData = bytes;
      if (_bufferData != null) {
        _playerState = PlayerState.readingComplete;
      } else {
        throw "Can't read given audio file";
      }
      notifyListeners();
    } else {
      throw "Please provide a valid file path";
    }
  }

  ///Call this to prepare player with optional [volume] parameters (has to be between 0.0 to 1.0).
  ///
  ///It first reads bytes from audio file so as soon as it completes
  /// it prepares audio player.
  ///
  ///[playerState] has to be PlayerState.readingComplete otherwise throws [Exception].
  ///
  ///This behavior is set to ensure that player is only re-initialised for new audio file.
  Future<void> preparePlayer(String path, [double? volume]) async {
    await _readAudioFile(path);
    if ((_playerState == PlayerState.readingComplete &&
        _audioFilePath != null)) {
      final isPrepared = await AudioWaveformsInterface.instance
          .preparePlayer(path, _playerKey.toString(), volume);
      if (isPrepared) {
        _maxDuration = await getDuration();
        _playerState = PlayerState.initialized;
      }
      notifyListeners();
    } else {
      throw "Can not call without reading new audio file";
    }
  }

  ///Use this function to start the player to play/resume the audio.
  ///
  ///When playing audio is finished player will be seeked to [start]. To change
  ///this behaviour pass false for [seekToStart] parameter and player position will
  ///stay at last
  Future<void> startPlayer([bool? seekToStart]) async {
    if (_playerState == PlayerState.initialized ||
        _playerState == PlayerState.paused) {
      _seekToStart = seekToStart ?? true;
      final isStarted = await AudioWaveformsInterface.instance
          .startPlayer(_playerKey.toString(), _seekToStart);
      if (isStarted) {
        _playerState = PlayerState.playing;
      } else {
        throw "Failed to start player";
      }
    }
    notifyListeners();
  }

  ///Use this to pause the playing audio
  Future<void> pausePlayer() async {
    final isPaused = await AudioWaveformsInterface.instance
        .pausePlayer(_playerKey.toString());
    if (isPaused) {
      _playerState = PlayerState.paused;
    }
    notifyListeners();
  }

  ///Use this to stop player. After calling this, resources are [freed].
  Future<void> stopPlayer() async {
    final isStopped = await AudioWaveformsInterface.instance
        .stopPlayer(_playerKey.toString());
    if (isStopped) {
      _playerState = PlayerState.stopped;
    }
    notifyListeners();
  }

  ///Sets valume for this player. Dosen't throw Exception.
  /// Returns false if it couldn't set the [volume].
  ///
  ///Volume has to be between 0.0 to 1.0.
  Future<bool> setVolume(double volume) async {
    final result = await AudioWaveformsInterface.instance
        .setVolume(volume, _playerKey.toString());
    return result;
  }

  ///Return [maximum] duration for [DurationType.max] and
  /// [current] duration for [DurationType.current] for playing content.
  ///The duration is in milliseconds, if no duration is available -1 is returned.
  ///
  /// Default is Duration.max
  Future<int> getDuration([DurationType? durationType]) async {
    final duration = await AudioWaveformsInterface.instance
        .getDuration(_playerKey.toString(), durationType?.index ?? 1);
    return duration ?? -1;
  }

  ///Moves the media to specified time position. pass progress parameter in milliseconds.
  ///
  /// Minimum Android O is required to use this funtion otherwise nothing happens.
  Future<void> seekTo(int progress) async {
    if (progress < 0) return;
    if (_playerState == PlayerState.playing) {
      await AudioWaveformsInterface.instance
          .seekTo(_playerKey.toString(), progress);
    }
  }

  ///Calling this will stop the player and it will dispose player in native
  ///It will also dispose the the controller.
  ///
  ///As there is common stream for every players stream
  /// will be still active without any events.
  /// To dispose it call [stopAllPlayers].
  void disposeFunc() async {
    if (playerState != PlayerState.stopped) await stopPlayer();
    dispose();
  }

  ///This method is to dispose [multiple] players all at once.
  ///
  /// This method is required to call only [once] from any one of the [PlayerController]s.
  ///
  /// Call this only when [truely] initialising a new [PlayerController] is not required.
  ///
  /// Note -: this method will close stream and dispose all the players but
  /// it will only dispose controller who's stopAllPlayers method was called
  /// calling [disposeFunc] is still required for every other [PlayerController]
  void stopAllPlayers() async {
    PlatformStreams.instance.dispose();
    await AudioWaveformsInterface.instance.stopAllPlayers();
    dispose();
  }
}
