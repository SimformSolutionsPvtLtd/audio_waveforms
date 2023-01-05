import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:audio_waveforms/src/base/constants.dart';
import 'package:audio_waveforms/src/base/platform_streams.dart';
import 'package:audio_waveforms/src/base/player_identifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part '../base/audio_waveforms_interface.dart';

class PlayerController extends ChangeNotifier {
  final List<double> _waveformData = [];

  List<double> get waveformData => _waveformData;

  PlayerState _playerState = PlayerState.stopped;

  /// Provides current state of the player
  PlayerState get playerState => _playerState;

  bool _shouldRefresh = true;

  bool get shouldRefresh => _shouldRefresh;

  void _setPlayerState(PlayerState state) {
    _playerState = state;
    PlatformStreams.instance
        .addPlayerStateEvent(PlayerIdentifier(playerKey, state));
  }

  int _maxDuration = -1;

  /// Provides [max] duration of currently provided audio file.
  int get maxDuration => _maxDuration;

  final UniqueKey _playerKey = UniqueKey();

  /// An unique key string associated with [this] player only
  String get playerKey => _playerKey.toString();

  final bool _shouldClearLabels = false;

  bool get shouldClearLabels => _shouldClearLabels;

  /// A stream to get current state of the player. This stream
  /// will emit event whenever there is change in the playerState.
  Stream<PlayerState> get onPlayerStateChanged =>
      PlatformStreams.instance.onPlayerStateChanged.filter(playerKey);

  /// A stream to get current duration. This stream will emit
  /// every 200 milliseconds. Emitted duration is in milliseconds.
  Stream<int> get onCurrentDurationChanged =>
      PlatformStreams.instance.onDurationChanged.filter(playerKey);

  /// A stream to get current extracted waveform data. This stream will emit
  /// list of doubles which are waveform data point.
  Stream<List<double>> get onCurrentExtractedWaveformData =>
      PlatformStreams.instance.onCurrentExtractedWaveformData.filter(playerKey);

  /// A stream to get current progress of waveform extraction.
  Stream<double> get onExtractionProgress =>
      PlatformStreams.instance.onExtractionProgress.filter(playerKey);

  /// A stream to get events when audio is finished playing.
  Stream<void> get onCompletion =>
      PlatformStreams.instance.onCompletion.filter(playerKey);

  PlayerController() {
    if (!PlatformStreams.instance.isInitialised) {
      PlatformStreams.instance.init();
    }
    PlatformStreams.instance.playerControllerFactory.addAll({playerKey: this});
  }

  /// Calls platform to prepare player.
  ///
  /// Path  is required parameter for providing location of the
  /// audio file.
  ///
  /// [volume] is optional parameters with minimum value 0.0 is treated
  /// as mute and 1.0 as max volume. Providing value greater 1.0 is also
  /// treated same as 1.0 (max volume).
  ///
  /// Waveforms also will be extracted when with function which can be
  /// accessed using [waveformData]. Passing false to [shouldExtractWaveform]
  /// will prevent extracting of waveforms.
  ///
  /// Waveforms also can be extracted using [extractWaveformData] function
  /// which can be stored locally or over the server. This data can be passed
  /// directly passed to AudioFileWaveforms widget.
  /// This will save the resources when extracting waveforms for same file
  /// everytime.
  ///
  /// [noOfSamples] indicates no of extracted data points. This will determine
  /// number of bars in the waveform.
  ///
  /// Defaults to 100.
  Future<void> preparePlayer({
    required String path,
    double? volume,
    bool shouldExtractWaveform = true,
    int noOfSamples = 100,
  }) async {
    path = Uri.parse(path).path;
    final isPrepared = await AudioWaveformsInterface.instance
        .preparePlayer(path, playerKey, volume);
    if (isPrepared) {
      _maxDuration = await getDuration();
      _setPlayerState(PlayerState.initialized);
    }

    if (shouldExtractWaveform) {
      extractWaveformData(
        path: path,
        noOfSamples: noOfSamples,
      ).then(
        (value) {
          waveformData
            ..clear()
            ..addAll(value);
          notifyListeners();
        },
      );
    }
    notifyListeners();
  }

  /// Extracts waveform data from provided audio file path.
  /// [noOfSamples] indicates number of extracted data points. This will
  /// determine number of bars in the waveform.
  ///
  /// This function will decode whole audio file and will calculate RMS
  /// according to provided number of samples. So it may take a while to fully
  /// decode audio file, specifically on android.
  ///
  /// For example, an audio file of 58 min and about 18 MB of size took about
  /// 4 minutes to decode on android while the same file took about 6-7 seconds
  /// on IOS.
  ///
  /// Providing less number if sample doesn't make a difference because it
  /// still have to decode whole file.
  ///
  /// noOfSamples defaults to 100.
  Future<List<double>> extractWaveformData({
    required String path,
    int noOfSamples = 100,
  }) async {
    path = Uri.parse(path).path;
    final result = await AudioWaveformsInterface.instance.extractWaveformData(
      key: playerKey,
      path: path,
      noOfSamples: noOfSamples,
    );
    return result;
  }

  /// A function to start the player to play/resume the audio.
  ///
  /// When playing audio is finished, this [player] will be [stopped]
  /// and [disposed] by default. To change this behavior use [FinishMode] enum.
  ///
  /// See also:
  /// * [FinishMode]
  Future<void> startPlayer({
    FinishMode finishMode = FinishMode.stop,
    bool forceRefresh = true,
  }) async {
    if (_playerState == PlayerState.initialized ||
        _playerState == PlayerState.paused) {
      final isStarted = await AudioWaveformsInterface.instance
          .startPlayer(playerKey, finishMode);
      if (isStarted) {
        _setPlayerState(PlayerState.playing);
      } else {
        throw "Failed to start player";
      }
    }
    _setRefresh(forceRefresh);
    notifyListeners();
  }

  /// Pauses currently playing audio.
  Future<void> pausePlayer() async {
    final isPaused =
        await AudioWaveformsInterface.instance.pausePlayer(playerKey);
    if (isPaused) {
      _setPlayerState(PlayerState.paused);
    }
    notifyListeners();
  }

  /// A function to stop player. After calling this, resources are freed.
  Future<void> stopPlayer() async {
    final isStopped =
        await AudioWaveformsInterface.instance.stopPlayer(playerKey);
    if (isStopped) {
      _setPlayerState(PlayerState.stopped);
    }
    notifyListeners();
  }

  /// Sets volume for this player. Doesn't throw Exception.
  /// Returns false if it couldn't set the volume.
  ///
  /// Minimum value [0.0] is treated as mute and 1.0 as max volume.
  /// Providing value greater 1.0 is also treated same as 1.0 (max volume).
  ///
  /// Default to 1.0
  Future<bool> setVolume(double volume) async {
    final result = await AudioWaveformsInterface.instance
        .setVolume(volume, playerKey);
    return result;
  }

  /// Returns maximum duration for [DurationType.max] and
  /// current duration for [DurationType.current] for playing media.
  /// The duration is in milliseconds, if no duration is available
  /// -1 is returned.
  ///
  /// Default to Duration.max.
  Future<int> getDuration([DurationType? durationType]) async {
    final duration = await AudioWaveformsInterface.instance
        .getDuration(playerKey, durationType?.index ?? 1);
    return duration ?? -1;
  }

  /// Moves the media to specified time(milliseconds) position.
  ///
  /// Minimum Android [O] is required to use this function
  /// otherwise nothing happens.
  Future<void> seekTo(int progress) async {
    if (progress < 0) return;
    if (_playerState == PlayerState.playing) {
      await AudioWaveformsInterface.instance.seekTo(playerKey, progress);
    }
  }

  /// Release any resources taken by this controller. Disposing this
  /// will stop the player and release resources from native.
  ///
  /// As there is common stream for every players, stream
  /// will be still active without any events.
  /// To dispose it call [stopAllPlayers] before calling this function.
  @override
  void dispose() async {
    if (playerState != PlayerState.stopped) await stopPlayer();
    PlatformStreams.instance.playerControllerFactory.remove(this);
    super.dispose();
  }

  /// This method is to free all players [resources] all at once.
  ///
  /// This method is required to call only [once] from any
  /// one of the PlayerController(s).
  ///
  /// Make sure to call this function before last remaining PlayerController.
  ///
  /// This method will close the stream and free resources taken by all
  /// players but it will only dispose this controller. So make sure free
  /// other PlayerController's resources.
  void stopAllPlayers() async {
    PlatformStreams.instance.dispose();
    await AudioWaveformsInterface.instance.stopAllPlayers();
    PlatformStreams.instance.playerControllerFactory.remove(this);
    super.dispose();
  }

  /// Sets [_shouldRefresh] flag with provided boolean parameter.
  void _setRefresh(bool refresh) {
    _shouldRefresh = refresh;
  }

  /// Sets [_shouldRefresh] flag with provided boolean parameter.
  void setRefresh(bool refresh) {
    _shouldRefresh = refresh;
    notifyListeners();
  }

  @override
  bool operator ==(Object other) {
    return other is PlayerController && other.playerKey == playerKey;
  }

  @override
  int get hashCode => super.hashCode; //ignore: unnecessary_overrides
}
