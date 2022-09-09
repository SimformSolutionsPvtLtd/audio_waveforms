import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import '/src/base/utils.dart';
import 'player_controller.dart';

class RecorderController extends ChangeNotifier {
  final List<double> _waveData = [];

  /// At which rate waveform needs to be updated
  late Duration updateFrequency = const Duration(milliseconds: 100);

  late AndroidEncoder androidEncoder = AndroidEncoder.aac;

  late AndroidOutputFormat androidOutputFormat = AndroidOutputFormat.mpeg4;

  late IosEncoder iosEncoder = IosEncoder.kAudioFormatMPEG4AAC;

  late int sampleRate = 16000;

  late int bitRate = 64000;

  ///Db we get from native is too high so in Android it the value is subtracted
  ///and in IOS value added
  late double normalizationFactor = Platform.isAndroid ? 60 : 40;

  ///Current list of decibels(different values for each platform)
  List<double> get waveData => _waveData;

  RecorderState _recorderState = RecorderState.stopped;

  /// Provides current state of the [recorder]
  RecorderState get recorderState => _recorderState;

  bool _isRecording = false;

  /// A boolean check for state of recording. It is true when recording
  /// is on going otherwise false.
  bool get isRecording => _isRecording;

  bool _shouldRefresh = true;

  bool get shouldRefresh => _shouldRefresh;

  Timer? _timer;

  bool _hasPermission = false;

  /// A boolean to check for microphone permission status. It is true when
  /// user has provided the microphone permission otherwise false.
  bool get hasPermission => _hasPermission;

  bool shouldClearLabels = false;

  final ValueNotifier<int> _currentScrolledDuration = ValueNotifier(0);

  /// A ValueNotifier which provides current position of scrolled waveform with
  /// respect to [middle line].
  ///
  /// [shouldCalculateScrolledPosition] flag must be enabled to use it
  /// (available in [AudioWaveform] widget).
  ///
  /// For better idea how duration is reported, enable duration labels and
  /// scroll toward middle line.
  ///
  /// Reported duration is in [milliseconds].
  ValueNotifier<int> get currentScrolledDuration => _currentScrolledDuration;

  /// Calls platform to start recording.
  ///
  /// First, it checks for microphone permission, if permission
  /// isn't provided then function will complete with [RecorderState]
  /// set to [stopped].
  ///
  /// [checkPermission] is used to check microphone permission. Follow
  /// it's documentation for more info.
  ///
  /// Path parameter is optional and if not provided current datetime
  /// will be used for file name and default extension will be .aac.
  ///
  /// Below is the example format to save file with custom name and
  /// extension.
  ///
  /// eg. /dir1/dir2/file-name.mp3
  ///
  /// How recorder will behave for different RecorderState -:
  ///
  /// 1. Paused-:  If a recorder is paused, calling this function again
  /// will start recording again where it left of.
  ///
  /// 2. Stopped -: If a recorder is stopped from previous recording and again
  /// this function is called then it will re-initialise the recorder.
  Future<void> record([String? path]) async {
    if (_recorderState != RecorderState.recording) {
      await checkPermission();
      if (_hasPermission) {
        if (Platform.isAndroid && _recorderState == RecorderState.stopped) {
          await _initRecorder(path);
        }
        if (_recorderState == RecorderState.paused) {
          _isRecording = await AudioWaveformsInterface.instance.resume();
          if (_isRecording) {
            _startTimer();
            _recorderState = RecorderState.recording;
          } else {
            throw "Failed to resume recording";
          }
          notifyListeners();
          return;
        }
        if (Platform.isIOS) {
          _recorderState = RecorderState.initialized;
        }
        if (_recorderState == RecorderState.initialized) {
          _isRecording = await AudioWaveformsInterface.instance.record(
            audioFormat:
                Platform.isIOS ? iosEncoder.index : androidEncoder.index,
            sampleRate: sampleRate,
            bitRate: bitRate,
            path: path,
          );
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

  /// Initialises recorder for android platform.
  Future<void> _initRecorder(String? path) async {
    final initialized = await AudioWaveformsInterface.instance.initRecorder(
      path: path,
      encoder: androidEncoder.index,
      outputFormat: androidOutputFormat.index,
      sampleRate: sampleRate,
      bitRate: bitRate,
    );
    if (initialized) {
      _recorderState = RecorderState.initialized;
    } else {
      throw "Failed to initialize recorder";
    }
    notifyListeners();
  }

  /// Checks for microphone permission and return true if permission was
  /// provided otherwise returns false.
  ///
  /// If this is first time check for microphone permission then it
  /// opens a platform dialog with description string which was set
  /// during initial set up.
  ///
  /// This method is also called during [record].
  Future<bool> checkPermission() async {
    final result = await AudioWaveformsInterface.instance.checkPermission();
    if (result) {
      _hasPermission = result;
    }
    notifyListeners();
    return _hasPermission;
  }

  /// Pauses the current recording. Call [record] to resume recording.
  Future<void> pause() async {
    if (_recorderState == RecorderState.recording) {
      _isRecording = (await AudioWaveformsInterface.instance.pause()) ?? true;
      if (_isRecording) {
        throw "Failed to pause recording";
      }
      _timer?.cancel();
      _recorderState = RecorderState.paused;
    }
    notifyListeners();
  }

  /// Stops the current recording.
  ///
  /// Resources are freed after calling this and file is saved and
  /// returns path where file is saved and it also clears waveform and
  /// resets to initial state. To change this behaviour, pass false to
  /// stop function's parameter and this will effectively will not
  /// call [reset] to clear waves.
  ///
  /// When [callReset] is set to false it will require calling [reset] function
  /// manually else it will start showing waveforms from same place where it
  /// left of for previous recording.
  Future<String?> stop([bool callReset = true]) async {
    if (_recorderState == RecorderState.recording ||
        _recorderState == RecorderState.paused) {
      final path = await AudioWaveformsInterface.instance.stop();

      if (path != null) {
        _isRecording = false;
        _timer?.cancel();
        _recorderState = RecorderState.stopped;
        if (callReset) reset();
        return path;
      } else {
        throw "Failed stop recording";
      }
    }

    notifyListeners();
    return null;
  }

  /// Clears WaveData and labels from the list. This will effectively remove
  /// waves and labels from the UI.
  void reset() {
    refresh();
    _waveData.clear();
    shouldClearLabels = true;
    notifyListeners();
  }

  /// Sets [shouldClearLabels] flag to false.
  void revertClearLabelCall() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      shouldClearLabels = false;
      notifyListeners();
    });
  }

  /// Gets decibels from native
  Future<double?> _getDecibel() async =>
      await AudioWaveformsInterface.instance.getDecibel();

  /// Gets decibel by every defined frequency
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

  /// Normalises the decibel
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

  /// Refreshes the waveform to the initial state after scrolling.
  void refresh() {
    _shouldRefresh = true;
    notifyListeners();
  }

  /// Sets [_shouldRefresh] flag with provided boolean parameter.
  void setRefresh(bool refresh) {
    _shouldRefresh = refresh;
    notifyListeners();
  }

  /// A function internally used to set scrolled position to duration.
  void setScrolledPositionDuration(int duration) {
    _currentScrolledDuration.value = duration;
  }

  /// Releases any resources taken by this recorder and with this
  /// controller is also disposes.
  @override
  void dispose() async {
    if (_timer != null) _timer!.cancel();
    if (recorderState != RecorderState.stopped) await stop();
    _currentScrolledDuration.dispose();
    super.dispose();
  }
}
