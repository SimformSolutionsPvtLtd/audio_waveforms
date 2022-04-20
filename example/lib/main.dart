import 'package:audio_waveforms_example/chat_bubble.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui show Gradient;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Audio Waveforms',
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

class _HomeState extends State<Home> with WidgetsBindingObserver {
  late final RecorderController recorderController;
  late final PlayerController playerController;
  String? path;
  String? musicFile;
  bool isPlaying = false;
  bool isRecording = false;

  @override
  void initState() {
    super.initState();
    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 16000;
    playerController = PlayerController()
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _getDir();
    _pickFile();
  }

  ///After completing the recording, this also
  ///can be passed to [playerController] to get waveforms.
  void _getDir() async {
    final dir = await getApplicationDocumentsDirectory();
    path = "${dir.path}/music.aac";
  }

  void _pickFile() async {
    await Future.delayed(const Duration(seconds: 3)).whenComplete(() async {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        musicFile = result.files.single.path;
        await playerController.preparePlayer(musicFile!);
      } else {
        print("File not picked");
      }
    });
  }

  @override
  void dispose() {
    recorderController.disposeFunc();
    playerController.stopAllPlayers();
    super.dispose();
  }

  ///As recording/playing media is resource heavy task,
  ///you don't want any resources to stay allocated even after
  ///app is killed. So it is recommended that if app is directly killed then
  ///this still will be called and we can free up resouces.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      recorderController.disposeFunc();
      playerController.disposeFunc();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF252331),
      appBar: AppBar(
        backgroundColor: const Color(0xFF252331),
        elevation: 0,
        title: const Text('Jonathan'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const ChatBubble(text: 'Hey', isSender: true),
            const ChatBubble(text: 'What\'s up?'),
            const ChatBubble(text: 'Can you share that audio?', isSender: true),
            const ChatBubble(text: 'sure'),
            if (playerController.playerState != PlayerState.stopped) ...[
              WaveBubble(
                playerController: playerController,
                isPlaying: playerController.playerState == PlayerState.playing,
                onTap: _playOrPlausePlayer,
              ),
              const ChatBubble(text: 'That was cool!', isSender: true),
            ],
            const Spacer(),
            Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isRecording
                      ? AudioWaveforms(
                          enableGesture: true,
                          size: Size(MediaQuery.of(context).size.width / 2, 50),
                          recorderController: recorderController,
                          waveStyle: WaveStyle(
                            waveColor: Colors.white,
                            extendWaveform: true,
                            showMiddleLine: false,
                            gradient: ui.Gradient.linear(
                              const Offset(70, 50),
                              Offset(MediaQuery.of(context).size.width / 2, 0),
                              [Colors.red, Colors.green],
                            ),
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.0),
                            color: const Color(0xFF1E1B26),
                          ),
                          padding: const EdgeInsets.only(left: 18),
                          margin: const EdgeInsets.symmetric(horizontal: 15),
                        )
                      : Container(
                          width: MediaQuery.of(context).size.width / 1.7,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1B26),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          padding: const EdgeInsets.only(left: 18),
                          margin: const EdgeInsets.symmetric(horizontal: 15),
                          child: const TextField(
                            decoration: InputDecoration(
                              hintText: "Type Something...",
                              hintStyle: TextStyle(color: Colors.white54),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                ),
                IconButton(
                  onPressed: _refreshWave,
                  icon: Icon(
                    isRecording ? Icons.refresh : Icons.send,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _startOrStopRecording,
                  icon: Icon(isRecording ? Icons.stop : Icons.mic),
                  color: Colors.white,
                  iconSize: 28,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _playOrPlausePlayer() async {
    playerController.playerState == PlayerState.playing
        ? await playerController.pausePlayer()
        : await playerController.startPlayer(false);
  }

  void _startOrStopRecording() async {
    if (isRecording) {
      await recorderController.stop(false);
    } else {
      await recorderController.record(path);
    }
    setState(() {
      isRecording = !isRecording;
    });
  }

  void _refreshWave() {
    if (isRecording) recorderController.refresh();
  }
}
