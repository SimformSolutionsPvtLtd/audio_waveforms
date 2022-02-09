import 'dart:io' show Platform;
import 'dart:async';
import 'package:flutter/material.dart';

import '/src/base/utils.dart';
import 'audio_wave_interface.dart';

class WaveController extends ChangeNotifier {
  final List<double> _waveData = [];

  ///At which rate waveform needs to be updated
  late Duration updateFrequency = const Duration(milliseconds: 100);

  ///Db we get from native is too high so in Android it the value is substracted
  ///and in IOS value added
  late double normalizationFactor = Platform.isAndroid ? 60 : 40;

  ///Current list of decibels(different values for each platform)
  List<double> get waveData => _waveData;

  RecorderState _recorderState = RecorderState.stopped;

  ///Current state of the [recorder]
  RecorderState get recorderState => _recorderState;

  bool _isRecording = false;

  ///State of recordning on/off
  bool get isRecording => _isRecording;

  bool _shouldRefresh = true;

  bool get shouldRefresh => _shouldRefresh;

  Timer? _timer;

  bool _hasPermission = false;

  ///If we have microphone permission or not.
  bool get hasPermission => _hasPermission;

  ///Use this to check permission and starts recording.
  ///
  ///Can be called after pausing.
  ///If called after stoping the recording, it will re-initialize.
  ///
  ///Path paramater is optional, if you want to provide provide with name
  ///of the file.
  ///
  ///eg. /dir1/dir2/file-name
  ///
  ///Only supported audio file format is .m4a for IOS and .mp3 for Android.
  ///More formats will be added shortly.
  Future<void> record([String? path]) async {
    if (_recorderState != RecorderState.recording) {
      await checkPermission();
      if (_hasPermission) {
        if (Platform.isAndroid && _recorderState == RecorderState.stopped) {
          await _initRecorder(path);
        }
        if (Platform.isIOS) {
          _recorderState = RecorderState.initialized;
        }
        if (_recorderState == RecorderState.paused && Platform.isAndroid) {
          _isRecording = await AudioWaveInterface.instance.resume();
          if (_isRecording) {
            _startTimer();
            _recorderState = RecorderState.recording;
          } else {
            throw "Failed to resume recording";
          }
          notifyListeners();
          return;
        }

        if (_recorderState == RecorderState.initialized) {
          _isRecording = await AudioWaveInterface.instance.record(path);
          if (_isRecording) {
            _recorderState = RecorderState.recording;
            _startTimer();
          } else {
            throw "Failed to start recording";
          }
          notifyListeners();
        }
      } else {
        _recorderState = RecorderState.stopped;
        notifyListeners();
      }
    }
  }

  ///This method is only required for Android platform
  Future<void> _initRecorder(String? path) async {
    final initialized = await AudioWaveInterface.instance.initRecorder(path);
    if (initialized) {
      _recorderState = RecorderState.initialized;
    } else {
      throw "Failed to initialize recorder";
    }
    notifyListeners();
  }

  ///This method can be used to check microphone permission.
  /// Returns true if we have permission
  ///else false.
  ///
  /// This method is called during record().
  Future<bool> checkPermission() async {
    final result = await AudioWaveInterface.instance.checkPermission();
    if (result) {
      _hasPermission = result;
    }
    notifyListeners();
    return _hasPermission;
  }

  ///Use this to pause recording.
  ///Can start recording again after pausing.
  Future<void> pause() async {
    if (_recorderState == RecorderState.recording) {
      _isRecording = (await AudioWaveInterface.instance.pause()) ?? true;
      if (_isRecording) {
        throw "Failed to pause recording";
      }
      _timer?.cancel();
      _recorderState = RecorderState.paused;
    }
    notifyListeners();
  }

  ///Use this stop recording.
  ///Resouces are freed after calling this and file is saved.
  Future<void> stop() async {
    if (_recorderState == RecorderState.recording ||
        _recorderState == RecorderState.paused) {
      _isRecording = await AudioWaveInterface.instance.stop();
    }
    if (!_isRecording) {
      _timer?.cancel();
      _recorderState = RecorderState.stopped;
    } else {
      throw "Failed stop recording";
    }
    notifyListeners();
  }

  ///gets decibels from native
  Future<double?> _getDecibel() async =>
      await AudioWaveInterface.instance.getDecibel();

  ///gets decibel by every defined frequency
  void _startTimer() {
    _timer = Timer.periodic(
      updateFrequency,
      (timer) async {
        var db = await _getDecibel();
        if (db == null) {
          _recorderState = RecorderState.stopped;
          throw "Failed to get sound level";
        }
        _normalise(db);
        notifyListeners();
      },
    );
  }

  ///normalises the decibel
  void _normalise(double db) {
    if (Platform.isAndroid) {
      waveData.add(db - normalizationFactor);
    } else {
      if (db == 0.0) {
        waveData.add(0);
      } else if (db + normalizationFactor < 1) {
        waveData.add(0);
      } else {
        waveData.add(db + normalizationFactor);
      }
    }
    notifyListeners();
  }

  ///Use this function to get wave to the initial state after scrolling,
  ///whether recording is stopped or running.
  void refresh() {
    _shouldRefresh = true;
    notifyListeners();
  }

  ///This function can be used to handle the refresh state.
  ///for most cases refresh() should be fine.
  void setRefresh(bool refresh) {
    _shouldRefresh = refresh;
    notifyListeners();
  }

  ///This function must be called to free [resouces],
  ///it will also dispose the controller.
  void disposeFunc() async {
    if (_timer != null) {
      _timer!.cancel();
    }
    await stop();
    dispose();
  }
}
