import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'dart:ui' as ui show Gradient;

import 'package:path_provider/path_provider.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Audio Waveforms',
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
  late final RecorderController recorderController;
  String? path;
  String? musicFile;

  @override
  void initState() {
    super.initState();
    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 16000;
    _getDir();
  }

  ///For this example, use this record from mic and directly provide that
  /// path to also generate waveforms from file
  void _getDir() async {
    final dir = await getApplicationDocumentsDirectory();
    musicFile = "${dir.path}/music.aac";
  }

  @override
  void dispose() {
    recorderController.disposeFunc();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF394253),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AudioWaveforms(
            enableGesture: true,
            size: Size(MediaQuery.of(context).size.width, 100.0),
            waveController: recorderController,
            margin: const EdgeInsets.all(20.0),
            waveStyle: WaveStyle(
              waveColor: Colors.white,
              middleLineColor: Colors.white,
              durationLinesColor: Colors.white,
              durationLinesHeight: 8.0,
              extendWaveform: true,
              showMiddleLine: false,
              labelSpacing: 8.0,
              showDurationLabel: true,
              durationStyle: const TextStyle(
                color: Colors.white,
                fontSize: 18.0,
              ),
              gradient: ui.Gradient.linear(
                const Offset(70, 50),
                Offset(MediaQuery.of(context).size.width / 2, 0),
                [Colors.red, Colors.green],
              ),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.0),
              gradient: const LinearGradient(
                colors: <Color>[
                  Color(0xFF615766),
                  Color(0xFF394253),
                  Color(0xFF412B4F),
                ],
                begin: Alignment.bottomLeft,
                stops: <double>[0.2, 0.45, 0.8],
              ),
            ),
          ),
          const SizedBox(height: 40),
          Container(
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xff2D3548), Color(0xff151922)],
                    stops: [0.1, 0.45],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter),
                borderRadius: BorderRadius.circular(12.0)),
            padding: const EdgeInsets.all(12.0),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    onPressed: () => recorderController.record(musicFile),
                    color: Colors.white,
                    icon: const Icon(Icons.mic),
                  ),
                ),
                const Spacer(),
                CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    onPressed: recorderController.pause,
                    color: Colors.white,
                    icon: const Icon(Icons.pause),
                  ),
                ),
                const Spacer(),
                CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    onPressed: () async {
                      path = await recorderController.stop();
                      setState(() {});
                    },
                    color: Colors.white,
                    icon: const Icon(Icons.stop),
                  ),
                ),
                const Spacer(),
                CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    onPressed: recorderController.refresh,
                    color: Colors.white,
                    icon: const Icon(Icons.refresh),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          const SizedBox(height: 30),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AudioFileWaveformDemo(),
              ),
            ),
            child: const Chip(
              label: RotatedBox(
                quarterTurns: 2,
                child: Icon(Icons.arrow_back),
              ),
              backgroundColor: Colors.white,
              avatar: Icon(Icons.library_music),
            ),
          ),
        ],
      ),
    );
  }
}

class AudioFileWaveformDemo extends StatefulWidget {
  const AudioFileWaveformDemo({Key? key}) : super(key: key);

  @override
  _AudioFileWaveformDemoState createState() => _AudioFileWaveformDemoState();
}

class _AudioFileWaveformDemoState extends State<AudioFileWaveformDemo> {
  String? musicFile;
  late PlayerController playerController;

  @override
  void initState() {
    super.initState();
    playerController = PlayerController()
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _pickFile();
  }

  ///For this example,use this in initState to pick audio file from
  /// storage and get it's waveform
  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      musicFile = result.files.single.path;
      await playerController.preparePlayer(musicFile!);
    } else {
      print("File not picked");
    }
  }

  @override
  void dispose() {
    playerController.disposeFunc();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF394253),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (playerController.playerState != PlayerState.stopped)
            AudioFileWaveforms(
              size: Size(MediaQuery.of(context).size.width - 100, 70.0),
              playerController: playerController,
              padding: const EdgeInsets.all(18),
              density: 1.5,
              clipBehavior: Clip.hardEdge,
              decoration:  BoxDecoration(
                color: Colors.black,
                gradient: const LinearGradient(
                  colors: <Color>[
                    Color(0xFF615766),
                    Color(0xFF394253),
                    Color(0xFF412B4F),
                  ],
                  begin: Alignment.bottomLeft,
                  stops: <double>[0.2, 0.45, 0.8],
                ),
                borderRadius: BorderRadius.circular(12)
              ),
            ),
          const SizedBox(height: 50),
          Container(
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xff2D3548), Color(0xff151922)],
                    stops: [0.1, 0.45],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter),
                borderRadius: BorderRadius.circular(12.0)),
            padding: const EdgeInsets.all(12.0),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                const SizedBox(width: 24),
                Center(
                  child: CircleAvatar(
                    backgroundColor: Colors.black45,
                    child: IconButton(
                      onPressed: () async =>
                          await playerController.startPlayer(false),
                      color: Colors.white,
                      icon: const Icon(Icons.play_arrow),
                    ),
                  ),
                ),
                const Spacer(),
                Center(
                  child: CircleAvatar(
                    backgroundColor: Colors.black45,
                    child: IconButton(
                      onPressed: () async =>
                          await playerController.pausePlayer(),
                      color: Colors.white,
                      icon: const Icon(Icons.pause),
                    ),
                  ),
                ),
                const Spacer(),
                Center(
                  child: CircleAvatar(
                    backgroundColor: Colors.black45,
                    child: IconButton(
                      onPressed: () async =>
                          await playerController.stopPlayer(),
                      color: Colors.white,
                      icon: const Icon(Icons.stop),
                    ),
                  ),
                ),
                const Spacer(),
                Center(
                  child: CircleAvatar(
                    backgroundColor: Colors.black45,
                    child: IconButton(
                      onPressed: () async =>
                          await playerController.resumePlayer(),
                      color: Colors.white,
                      icon: const Icon(Icons.sync),
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
