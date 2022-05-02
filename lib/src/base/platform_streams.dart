import 'dart:async';

import 'package:audio_waveforms/src/base/current_duration_identifier.dart';

///This class should be used for any type of native streams.
class PlatformStreams {
  PlatformStreams._();

  static PlatformStreams instance = PlatformStreams._();

  bool isInitialised = false;

  void init() {
    _durationStreamController =
        StreamController<CurrentDurationIndentifier>.broadcast();
    isInitialised = true;
  }

  Stream<CurrentDurationIndentifier> get durationStream =>
      _durationStreamController.stream;

  late StreamController<CurrentDurationIndentifier> _durationStreamController;

  void addDurationEvent(CurrentDurationIndentifier event) {
    _durationStreamController.add(event);
  }

  void dispose() async {
    await _durationStreamController.close();
    isInitialised = false;
  }
}
