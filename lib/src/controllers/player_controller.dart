import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';

import '../base/audio_waveforms_interface.dart';

class PlayerController extends ChangeNotifier {
  Uint8List? _bufferData;

  ///provides data we got after reading audio file
  Uint8List? get bufferData => _bufferData;

  PlayerState _playerState = PlayerState.stopped;

  ///provides current state of the player
  PlayerState get playerState => _playerState;

  String? _audioFilePath;

  ///This stream controller can be used to listen to get current duration of playing
  ///audio. Events will be sent every 200 milliseconds.
  ///
  ///The duration data is in [milliseconds].
  StreamController<int> durationStreamController = StreamController<int>();

  StreamSubscription? _durationStreamSubscribtion;

  int _maxDuration = -1;

  ///provides [max] duration of currenly provided audio file.
  int get maxDuration => _maxDuration;

  bool _seekToStart = true;

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
      final isPrepared =
          await AudioWaveformsInterface.instance.preparePlayer(path, volume);
      if (isPrepared) {
        _maxDuration = await getDuration();
        _playerState = PlayerState.initialized;
      }
      notifyListeners();
    } else {
      throw "Can not call without reading new audio file";
    }
  }

  ///Use this function to start player to play the audio.
  ///
  ///When playing audio is finished player will be seeked to [start]. To change
  ///this behaviour pass false for [seekToStart] parameter and player position will
  ///stay at last
  Future<void> startPlayer([bool? seekToStart]) async {
    if (_playerState == PlayerState.initialized ||
        _playerState == PlayerState.paused) {
      _seekToStart = seekToStart ?? true;
      final isStarted = await AudioWaveformsInterface.instance
          .startPlayer(seekToStart ?? true);
      if (isStarted) {
        _playerState = PlayerState.playing;
        if (!durationStreamController.hasListener) {
          _startDurationStream();
        }
      } else {
        throw "Failed to start player";
      }
    }
    notifyListeners();
  }

  ///Use this to pause the playing audio
  Future<void> pausePlayer() async {
    _durationStreamSubscribtion?.pause();
    final isPaused = await AudioWaveformsInterface.instance.pausePlayer();
    if (isPaused) {
      _playerState = PlayerState.paused;
    }
    notifyListeners();
  }

  ///Resumes playing the audio. It retains [seekToStart] behaviour from
  /// startPlayer().
  Future<void> resumePlayer() async {
    if (_playerState == PlayerState.initialized ||
        _playerState == PlayerState.paused) {
      final isResumed =
          await AudioWaveformsInterface.instance.startPlayer(_seekToStart);
      if (isResumed) {
        _durationStreamSubscribtion?.resume();
        _playerState = PlayerState.resumed;
      }
    }
    notifyListeners();
  }

  ///Use this to stop player. After calling this, resources are [freed].
  Future<void> stopPlayer() async {
    await _durationStreamSubscribtion?.cancel();
    final isStopped = await AudioWaveformsInterface.instance.stopPlayer();
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
    final result = await AudioWaveformsInterface.instance.setVolume(volume);
    return result;
  }

  ///Return [maximum] duration for [DurationType.max] and
  /// [current] duration for [DurationType.current] for playing content.
  ///The duration is in milliseconds, if no duration is available -1 is returned.
  ///
  /// Default is Duration.max
  Future<int> getDuration([DurationType? durationType]) async {
    final duration = await AudioWaveformsInterface.instance
        .getDuration(durationType?.index ?? 1);
    return duration ?? -1;
  }

  ///Moves the media to specified time position. pass progress parameter in milliseconds.
  ///
  /// Minimum Android O is required to use this funtion otherwise nothing happens.
  Future<void> seekTo(int progress) async {
    if (_playerState == PlayerState.playing ||
        _playerState == PlayerState.resumed) {
      await AudioWaveformsInterface.instance.seekTo(progress);
    }
  }

  void _startDurationStream() {
    _durationStreamSubscribtion = AudioWaveformsInterface.instance
        .listenToDurationStream()
        .listen((currentDuration) {
      if (currentDuration is int) {
        durationStreamController.add(currentDuration);
      }
    });
    durationStreamController.stream.asBroadcastStream();
  }

  void disposeFunc() async {
    await durationStreamController.close();
    _durationStreamSubscribtion?.cancel();
    if (playerState != PlayerState.stopped) await stopPlayer();
    dispose();
  }
}
