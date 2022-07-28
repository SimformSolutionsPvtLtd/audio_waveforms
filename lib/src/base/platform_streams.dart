import 'dart:async';

import 'package:audio_waveforms/src/base/player_indentifier.dart';

import '../../audio_waveforms.dart';

///This class should be used for any type of native streams.
class PlatformStreams {
  PlatformStreams._();

  ///This holds all the newly created [PlayerController] instances and
  ///the key to identify. it is a [Unique] key created along with
  ///PlayerController.
  final Map<String, PlayerController> playerControllerFactory = {};

  static PlatformStreams instance = PlatformStreams._();

  bool isInitialised = false;

  void init() {
    _currentDurationController =
        StreamController<PlayerIdentifier<int>>.broadcast();
    _playerStateController =
        StreamController<PlayerIdentifier<PlayerState>>.broadcast();
    AudioWaveformsInterface.instance.setMethodCallHandler();
    isInitialised = true;
  }

  Stream<PlayerIdentifier<int>> get onDurationChanged =>
      _currentDurationController.stream;

  Stream<PlayerIdentifier<PlayerState>> get onPlayerStateChanged =>
      _playerStateController.stream;

  late StreamController<PlayerIdentifier<int>> _currentDurationController;
  late StreamController<PlayerIdentifier<PlayerState>> _playerStateController;

  void addCurrentDurationEvent(PlayerIdentifier<int> playerIdentifier) {
    if (!_currentDurationController.isClosed) {
      _currentDurationController.add(playerIdentifier);
    }
  }

  void addPlayerStateEvent(PlayerIdentifier<PlayerState> playerIdentifier) {
    if (!_playerStateController.isClosed) {
      _playerStateController.add(playerIdentifier);
    }
  }

  void dispose() async {
    await _currentDurationController.close();
    await _playerStateController.close();
    AudioWaveformsInterface.instance.removeMethodCallHandeler();
    isInitialised = false;
  }
}
