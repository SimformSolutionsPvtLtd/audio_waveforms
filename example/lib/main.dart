import 'dart:async';
import 'package:flutter/material.dart';

import 'package:audio_wave/audio_wave.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:flutter_sound/public/tau.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_platform_interface.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Audio Wave',
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  FlutterSoundRecorder recorder = FlutterSoundRecorder(logLevel: Level.error);
  bool isPaused = false;
  bool isRecording = false;
  List<double> waveData = [];
  final recordingDataController = StreamController<FoodData>();
  bool isReCording = false;

  @override
  void initState() {
    super.initState();
    _openRecorder();
  }

  void _openRecorder() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }
    await recorder.openRecorder();
  }

  void _record() async {
    if (isPaused) {
      await recorder.resumeRecorder();
      isPaused = false;
    } else {
      await recorder.startRecorder(
        toStream: recordingDataController.sink,
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: 44000,
      );
      await recorder.setSubscriptionDuration(const Duration(milliseconds: 100));
      isPaused = false;
    }
    setState(() {});
  }

  Future<void> _pause() async {
    await recorder.pauseRecorder();
    isPaused = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 200),
          ColoredBox(
            color: Colors.black,
            child: StreamBuilder<RecordingDisposition>(
              stream: recorder.onProgress,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(height: 150.0);
                } else {
                  if (snapshot.data?.decibels != null &&
                      snapshot.data?.decibels != 0.0) {
                    waveData.add(snapshot.data!.decibels!);
                  }
                  return AudioWave(
                    waveData: waveData,
                    size: Size(MediaQuery.of(context).size.width, 200.0),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: CircleAvatar(
                  backgroundColor: Colors.black,
                  child: IconButton(
                    onPressed: _record,
                    color: Colors.white,
                    icon: const Icon(Icons.play_arrow),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Center(
                child: CircleAvatar(
                  backgroundColor: Colors.black,
                  child: IconButton(
                    onPressed: _pause,
                    color: Colors.white,
                    icon: const Icon(Icons.pause),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
