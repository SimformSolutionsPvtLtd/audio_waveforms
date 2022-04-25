import 'dart:async';
import 'dart:io';
import '/src/base/constants.dart';
import 'package:flutter/services.dart';

class AudioWaveInterface {
  AudioWaveInterface._();

  static AudioWaveInterface instance = AudioWaveInterface._();

  static const MethodChannel _methodChannel =
      MethodChannel(Constants.methodChannelName);

  ///platform call to start recording
  Future<bool> record(int audioFormat, int sampleRate, [String? path]) async {
    final _isRecording = await _methodChannel.invokeMethod(
        Constants.startRecording,
        Platform.isIOS
            ? {
                Constants.path: path,
                Constants.encoder: audioFormat,
                Constants.sampleRate: sampleRate,
              }
            : null);
    return _isRecording ?? false;
  }

  ///platform call to initialise the recorder.
  ///This method is only required for Android platform
  Future<bool> initRecorder(
      String? path, int encoder ,int audioFormat, int sampleRate) async {
    final initialized = await _methodChannel.invokeMethod(
      Constants.initRecorder,
      {
        Constants.path: path,
        Constants.audioFormat: audioFormat,
        Constants.encoder: encoder,
        Constants.sampleRate: sampleRate,
      },
    );
    return initialized ?? false;
  }

  ///platform call to pause recording
  Future<bool?> pause() async {
    final _isRecording =
        await _methodChannel.invokeMethod(Constants.pauseRecording);
    return _isRecording;
  }

  ///platform call to stop recording
  Future<String?> stop() async {
    final _isRecording =
        await _methodChannel.invokeMethod(Constants.stopRecording);
    return _isRecording;
  }

  ///platform call to resume recording.
  ///This method is only required for Android platform
  Future<bool> resume() async {
    final _isRecording =
        await _methodChannel.invokeMethod(Constants.resumeRecording);
    return _isRecording ?? false;
  }

  ///platform call to get decibel
  Future<double?> getDecibel() async {
    var db = await _methodChannel.invokeMethod(Constants.getDecibel);
    return db;
  }

  ///platform call to check microphone permission
  Future<bool> checkPermission() async {
    var hasPermission =
        await _methodChannel.invokeMethod(Constants.checkPermission);
    return hasPermission ?? false;
  }
}
