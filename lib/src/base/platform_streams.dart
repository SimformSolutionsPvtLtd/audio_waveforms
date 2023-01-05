import 'dart:async';

import 'package:audio_waveforms/src/base/player_identifier.dart';

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

  /// Initialises native method call handlers and stream. Should be called
  /// only once before [dispose].
  Future<void> init() async {
    // Requires to be set before waiting for method call handler to be
    // initialised due to race condition when using widget in ListView.builder.
    isInitialised = true;

    _currentDurationController =
        StreamController<PlayerIdentifier<int>>.broadcast();
    _playerStateController =
        StreamController<PlayerIdentifier<PlayerState>>.broadcast();
    _extractedWaveformDataController =
        StreamController<PlayerIdentifier<List<double>>>.broadcast();
    _extractionProgressController =
        StreamController<PlayerIdentifier<double>>.broadcast();
    _completionController =
        StreamController<PlayerIdentifier<void>>.broadcast();
    await AudioWaveformsInterface.instance.setMethodCallHandler();
  }

  Stream<PlayerIdentifier<int>> get onDurationChanged =>
      _currentDurationController.stream;

  Stream<PlayerIdentifier<PlayerState>> get onPlayerStateChanged =>
      _playerStateController.stream;

  Stream<PlayerIdentifier<List<double>>> get onCurrentExtractedWaveformData =>
      _extractedWaveformDataController.stream;

  Stream<PlayerIdentifier<double>> get onExtractionProgress =>
      _extractionProgressController.stream;

  Stream<PlayerIdentifier<void>> get onCompletion =>
      _completionController.stream;

  late StreamController<PlayerIdentifier<int>> _currentDurationController;
  late StreamController<PlayerIdentifier<PlayerState>> _playerStateController;
  late StreamController<PlayerIdentifier<List<double>>>
      _extractedWaveformDataController;
  late StreamController<PlayerIdentifier<double>> _extractionProgressController;
  late StreamController<PlayerIdentifier<void>> _completionController;

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

  void addExtractedWaveformDataEvent(
      PlayerIdentifier<List<double>> playerIdentifier) {
    if (!_extractedWaveformDataController.isClosed) {
      _extractedWaveformDataController.add(playerIdentifier);
    }
  }

  void addExtractionProgress(PlayerIdentifier<double> progress) {
    if (!_extractionProgressController.isClosed) {
      _extractionProgressController.add(progress);
    }
  }

  void addCompletionEvent(PlayerIdentifier<void> event) {
    if (!_completionController.isClosed) {
      _completionController.add(event);
    }
  }

  void dispose() {
    _currentDurationController.close();
    _playerStateController.close();
    _extractedWaveformDataController.close();
    _currentDurationController.close();
    _completionController.close();
    AudioWaveformsInterface.instance.removeMethodCallHandler();
    isInitialised = false;
  }
}
