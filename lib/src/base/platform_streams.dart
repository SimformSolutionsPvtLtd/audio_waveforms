import 'dart:async';

import 'package:audio_waveforms/src/base/current_duration_identifier.dart';

///This class should be used for any type of native streams.
class PlatformStreams {
  PlatformStreams._();

  static PlatformStreams instance = PlatformStreams._();

  Stream<CurrentDurationIndentifier> get durationStream =>
      _durationStreamController.stream;

  final StreamController<CurrentDurationIndentifier> _durationStreamController =
      StreamController<CurrentDurationIndentifier>.broadcast();

  void addDurationEvent(CurrentDurationIndentifier event) {
    _durationStreamController.add(event);
  }

  void dispose() async {
    await _durationStreamController.close();
  }
}
