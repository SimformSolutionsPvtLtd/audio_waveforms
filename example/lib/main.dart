import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:audio_waveforms_example/chat_bubble.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

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
  late final PlayerController playerController1;
  late final PlayerController playerController2;
  late final PlayerController playerController3;
  late final PlayerController playerController4;
  late final PlayerController playerController5;
  late final PlayerController playerController6;

  String? path;
  String? musicFile;
  bool isRecording = false;
  late Directory appDirectory;

  @override
  void initState() {
    super.initState();
    _getDir();
    _initialiseControllers();
  }

  void _getDir() async {
    appDirectory = await getApplicationDocumentsDirectory();
    _preparePlayers();
    path = "${appDirectory.path}/music.aac";
  }

  Future<ByteData> _loadAsset(String path) async {
    return await rootBundle.load(path);
  }

  void _initialiseControllers() {
    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 16000
      ..bitRate = 64000;
    playerController1 = PlayerController()
      ..addListener(() {
        if (mounted) setState(() {});
      });
    playerController2 = PlayerController()
      ..addListener(() {
        if (mounted) setState(() {});
      });
    playerController3 = PlayerController()
      ..addListener(() {
        if (mounted) setState(() {});
      });
    playerController4 = PlayerController()
      ..addListener(() {
        if (mounted) setState(() {});
      });
    playerController5 = PlayerController()
      ..addListener(() {
        if (mounted) setState(() {});
      });
    playerController6 = PlayerController()
      ..addListener(() {
        if (mounted) setState(() {});
      });
  }

  void _preparePlayers() async {
    ///audio-1
    final file1 = File('${appDirectory.path}/audio1.mp3');
    await file1.writeAsBytes(
        (await _loadAsset('assets/audios/audio1.mp3')).buffer.asUint8List());
    playerController1.preparePlayer(file1.path);

    ///audio-2
    final file2 = File('${appDirectory.path}/audio2.mp3');
    await file2.writeAsBytes(
        (await _loadAsset('assets/audios/audio2.mp3')).buffer.asUint8List());
    playerController2.preparePlayer(file2.path);

    ///audio-3
    final file3 = File('${appDirectory.path}/audio3.mp3');
    await file3.writeAsBytes(
        (await _loadAsset('assets/audios/audio3.mp3')).buffer.asUint8List());
    playerController3.preparePlayer(file3.path);

    ///audio-4
    final file4 = File('${appDirectory.path}/audio4.mp3');
    await file4.writeAsBytes(
        (await _loadAsset('assets/audios/audio4.mp3')).buffer.asUint8List());
    playerController4.preparePlayer(file4.path);
  }

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      musicFile = result.files.single.path;
      await playerController6.preparePlayer(musicFile!);
    } else {
      debugPrint("File not picked");
    }
  }

  void _disposeControllers() {
    recorderController.dispose();
    playerController1.stopAllPlayers();
    playerController2.dispose();
    playerController3.dispose();
    playerController4.dispose();
    playerController5.dispose();
    playerController6.dispose();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  ///As recording/playing media is resource heavy task,
  ///you don't want any resources to stay allocated even after
  ///app is killed. So it is recommended that if app is directly killed then
  ///this still will be called and we can free up resouces.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _disposeControllers();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF252331),
      appBar: AppBar(
        backgroundColor: const Color(0xFF252331),
        elevation: 1,
        centerTitle: true,
        shadowColor: Colors.grey,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              scale: 1.5,
            ),
            const SizedBox(width: 10),
            const Text('Simform'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            if (playerController1.playerState != PlayerState.stopped) ...[
              WaveBubble(
                playerController: playerController1,
                isPlaying: playerController1.playerState == PlayerState.playing,
                onTap: () => _playOrPausePlayer(playerController1),
              ),
            ],
            if (playerController2.playerState != PlayerState.stopped) ...[
              WaveBubble(
                playerController: playerController2,
                isPlaying: playerController2.playerState == PlayerState.playing,
                onTap: () => _playOrPausePlayer(playerController2),
                isSender: true,
              ),
            ],
            if (playerController3.playerState != PlayerState.stopped) ...[
              WaveBubble(
                playerController: playerController3,
                isPlaying: playerController3.playerState == PlayerState.playing,
                onTap: () => _playOrPausePlayer(playerController3),
              ),
            ],
            if (playerController4.playerState != PlayerState.stopped) ...[
              WaveBubble(
                playerController: playerController4,
                isPlaying: playerController4.playerState == PlayerState.playing,
                onTap: () => _playOrPausePlayer(playerController4),
                isSender: true,
              ),
            ],
            if (playerController5.playerState != PlayerState.stopped) ...[
              WaveBubble(
                playerController: playerController5,
                isPlaying: playerController5.playerState == PlayerState.playing,
                onTap: () => _playOrPausePlayer(playerController5),
                isSender: true,
              ),
            ],
            if (playerController6.playerState != PlayerState.stopped) ...[
              WaveBubble(
                playerController: playerController6,
                isPlaying: playerController6.playerState == PlayerState.playing,
                onTap: () => _playOrPausePlayer(playerController6),
                isSender: true,
              ),
            ],
            const Spacer(),
            SafeArea(
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isRecording
                        ? AudioWaveforms(
                            enableGesture: true,
                            size: Size(MediaQuery.of(context).size.width / 2, 50),
                            recorderController: recorderController,
                            waveStyle: const WaveStyle(
                              waveColor: Colors.white,
                              extendWaveform: true,
                              showMiddleLine: false,
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
                            child: TextField(
                              readOnly: true,
                              decoration: InputDecoration(
                                hintText: "Type Something...",
                                hintStyle: const TextStyle(color: Colors.white54),
                                contentPadding: const EdgeInsets.only(top: 16),
                                border: InputBorder.none,
                                suffixIcon: IconButton(
                                  onPressed: _pickFile,
                                  icon: Icon(Icons.adaptive.share),
                                  color: Colors.white54,
                                ),
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
            ),
          ],
        ),
      ),
    );
  }

  void _playOrPausePlayer(PlayerController controller) async {
    controller.playerState == PlayerState.playing
        ? await controller.pausePlayer()
        : await controller.startPlayer(finishMode: FinishMode.loop);
  }

  void _startOrStopRecording() async {
    if (isRecording) {
      recorderController.reset();
      final path = await recorderController.stop(false);

      if (path != null) {
        debugPrint("Recorded file size: ${File(path).lengthSync()}");
        await playerController5.preparePlayer(path);
      }
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
