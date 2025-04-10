import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../base/platform_streams.dart';
import '/src/base/utils.dart';
import '../base/constants.dart';
import '../models/recorder_settings.dart';
import 'player_controller.dart';

// ignore_for_file: deprecated_member_use_from_same_package
class RecorderController extends ChangeNotifier {
  final List<double> _waveData = [];

  /// Current list of scaled waves. For IOS, this list contains normalised
  /// peak power and for Android, this list contains normalised peak
  /// amplitude.
  ///
  /// Values are between 0.0 to 1.0.
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

  /// IOS only.
  ///
  /// Overrides AVAudioSession settings with
  /// ```
  /// AVAudioSession.Category: .playAndRecord
  /// AVAudioSession.CategoryOptions: [.defaultToSpeaker, .allowBluetooth]
  /// ```
  /// You may use your implementation to set your preferred configurations.
  /// Changes to this property will only take effect after you call [record].
  ///
  /// **Important**-: If you set this property to false, you will be responsible
  /// for the setting current configuration. Failed to do so may result in
  /// audio not being recorded and waves not generating.
  ///
  /// Defaults to true.
  bool overrideAudioSession = true;

  bool get shouldClearLabels => _shouldClearLabels;

  bool _shouldClearLabels = false;

  bool _isDisposed = false;

  /// Provides currently recorded audio duration. Use [onCurrentDuration]
  /// stream to get latest events duration.
  Duration get elapsedDuration => _elapsedDuration;

  Duration _elapsedDuration = Duration.zero;

  /// Provides duration of recorded audio file when recording has been stopped.
  /// Until recording has been stopped, this duration will be
  /// zero(Duration.zero). Also, once new recording is started this duration
  /// will be reset to zero.
  Duration get recordedDuration => _recordedDuration;

  Duration _recordedDuration = Duration.zero;

  Timer? _recorderTimer;

  final ValueNotifier<int> _currentScrolledDuration = ValueNotifier(0);

  final StreamController<Duration> _currentDurationController =
      StreamController.broadcast();

  /// A stream to get current duration of currently recording audio file.
  /// Events are emitted every 50 milliseconds which means current duration is
  /// accurate to 50 milliseconds. To get Fully accurate duration use
  /// [recordedDuration] after stopping the recording.
  Stream<Duration> get onCurrentDuration => _currentDurationController.stream;

  final StreamController<RecorderState> _recorderStateController =
      StreamController.broadcast();

  final StreamController<Duration> _recordedFileDurationController =
      StreamController.broadcast();

  /// A Stream to monitor change in RecorderState. Events are emitted whenever
  /// there is change in the RecorderState.
  Stream<RecorderState> get onRecorderStateChanged =>
      _recorderStateController.stream;

  /// A stream to get duration of recording when audio recorder has
  /// been stopped. Events are only emitted if platform could extract the
  /// duration of audio file when recording is ended.
  Stream<Duration> get onRecordingEnded =>
      _recordedFileDurationController.stream;

  /// A stream to get the recorded audio bytes.
  Stream<Uint8List> get onAudioChunks =>
      PlatformStreams.instance.onRecordedBytes;

  StreamSubscription? _amplitudeStreamSubscription;

  /// A class having controls for recording audio and other useful handlers.
  RecorderController() {
    if (!PlatformStreams.instance.isInitialised) {
      PlatformStreams.instance.init();
    }
    _amplitudeStreamSubscription =
        PlatformStreams.instance.onAmplitude.listen(_updateOnNewAmplitude);
  }

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
  /// will be used for file name and default extension will be .m4a.
  ///
  /// Below is the example format to save file with custom name and
  /// extension.
  ///
  /// eg. /dir1/dir2/file-name.m4a
  ///
  /// How recorder will behave for different RecorderState -:
  ///
  /// 1. Paused-:  If a recorder is paused, calling this function again
  /// will start recording again where it left of.
  ///
  /// 2. Stopped -: If a recorder is stopped from previous recording and again
  /// this function is called then it will re-initialise the recorder.
  Future<void> record({
    String? path,
    RecorderSettings recorderSettings = const RecorderSettings(),
  }) async {
    if (!_recorderState.isRecording) {
      await checkPermission();
      if (_hasPermission) {
        if (Platform.isAndroid && _recorderState.isStopped) {
          await _initRecorder(
            path: path,
            recorderSettings: recorderSettings,
          );
        }
        if (_recorderState.isPaused) {
          _isRecording = await AudioWaveformsInterface.instance.resume();
          if (_isRecording) {
            _startTimer();
            _setRecorderState(RecorderState.recording);
          } else {
            throw "Failed to resume recording";
          }
          notifyListeners();
          return;
        }
        if (Platform.isIOS) {
          _setRecorderState(RecorderState.initialized);
        }
        if (_recorderState.isInitialized) {
          _isRecording = await AudioWaveformsInterface.instance.record(
            recorderSetting: recorderSettings,
            path: path,
            overrideAudioSession: overrideAudioSession,
          );
          if (_isRecording) {
            _setRecorderState(RecorderState.recording);
            _startTimer();
          } else {
            throw "Failed to start recording";
          }
          notifyListeners();
        }
      } else {
        _setRecorderState(RecorderState.stopped);
        notifyListeners();
      }
    }
  }

  /// Initialises recorder for android platform.
  Future<void> _initRecorder({
    String? path,
    required RecorderSettings recorderSettings,
  }) async {
    final initialized = await AudioWaveformsInterface.instance.initRecorder(
      path: path,
      recorderSettings: recorderSettings,
    );
    if (initialized) {
      _setRecorderState(RecorderState.initialized);
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
    if (_recorderState.isRecording) {
      _isRecording = (await AudioWaveformsInterface.instance.pause()) ?? true;
      if (_isRecording) {
        throw "Failed to pause recording";
      }
      _recorderTimer?.cancel();
      _timer?.cancel();
      _setRecorderState(RecorderState.paused);
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
    if (_recorderState.isRecording || _recorderState.isPaused) {
      final audioInfo = await AudioWaveformsInterface.instance.stop();
      _isRecording = false;
      _timer?.cancel();
      _recorderTimer?.cancel();
      if (audioInfo[Constants.resultDuration] != null) {
        final duration = audioInfo[Constants.resultDuration];

        _recordedDuration = Duration(milliseconds: duration);
        _recordedFileDurationController.add(recordedDuration);
      }
      _elapsedDuration = Duration.zero;
      _setRecorderState(RecorderState.stopped);
      if (callReset) reset();
      return audioInfo[Constants.resultFilePath];
    }

    notifyListeners();
    return null;
  }

  /// Clears WaveData and labels from the list. This will effectively remove
  /// waves and labels from the UI.
  void reset() {
    refresh();
    _waveData.clear();
    _shouldClearLabels = true;
    notifyListeners();
  }

  /// Sets [shouldClearLabels] flag to false.
  void revertClearLabelCall() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _shouldClearLabels = false;
      notifyListeners();
    });
  }

  /// Gets decibel by every defined frequency
  void _startTimer() {
    _recordedDuration = Duration.zero;
    const duration = Duration(milliseconds: 50);
    _recorderTimer = Timer.periodic(duration, (_) {
      _elapsedDuration += duration;
      _currentDurationController.add(elapsedDuration);
    });
  }

  void _updateOnNewAmplitude(double amplitude) {
    _waveData.add(amplitude);
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

  void _setRecorderState(RecorderState state) {
    if (!_recorderStateController.isClosed) {
      _recorderStateController.add(state);
      _recorderState = state;
    }
  }

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  /// Releases any resources taken by this recorder and with this
  /// controller is also disposed.
  @override
  void dispose() async {
    if (recorderState != RecorderState.stopped) await stop();
    _currentScrolledDuration.dispose();
    _currentDurationController.close();
    _recorderStateController.close();
    _recordedFileDurationController.close();
    _amplitudeStreamSubscription?.cancel();
    _recorderTimer?.cancel();
    _timer?.cancel();
    _timer = null;
    _recorderTimer = null;
    _isDisposed = true;
    super.dispose();
  }
}
