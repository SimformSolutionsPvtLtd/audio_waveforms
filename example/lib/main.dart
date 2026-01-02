import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:audio_waveforms_example/chat_bubble.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final RecorderController recorderController;
  final List<String> assetPaths = const [
    'assets/audios/audio1.mp3',
    'assets/audios/audio2.mp3',
    'assets/audios/audio3.mp3',
    'assets/audios/audio4.mp3',
  ];

  final paths = <String>[];
  bool isRecording = false;
  bool isRecordingCompleted = false;
  bool isLoading = true;
  late Directory appDirectory;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    recorderController = RecorderController();
    appDirectory = await getApplicationDocumentsDirectory();
    for (final path in assetPaths) {
      final fileName = path.split('/').last;
      final file = File('${appDirectory.path}/$fileName');
      final byteData = await rootBundle.load(path);
      final bytes = byteData.buffer.asUint8List();
      await file.writeAsBytes((bytes));
      paths.add(file.path);
    }
    isLoading = false;
    setState(() {});
  }

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      paths.add(result.files.first.path!);
      setState(() {});
    } else {
      debugPrint("File not picked");
    }
  }

  @override
  void dispose() {
    recorderController.dispose();
    super.dispose();
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
            const Text(
              'Simform',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: paths.length,
                      itemBuilder: (_, index) {
                        return WaveBubble(
                          path: paths[index],
                          isSender: index.isOdd,
                          width: MediaQuery.of(context).size.width / 2,
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    child: Row(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: isRecording
                              ? AudioWaveforms(
                                  enableGesture: true,
                                  size: Size(
                                      MediaQuery.of(context).size.width / 2,
                                      50),
                                  recorderController: recorderController,
                                  waveStyle: const WaveStyle(
                                      waveColor: Colors.white,
                                      extendWaveform: true,
                                      showMiddleLine: false,
                                      showDurationLabel: true),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.0),
                                    color: const Color(0xFF1E1B26),
                                  ),
                                  padding: const EdgeInsets.only(left: 18),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 15),
                                )
                              : Container(
                                  width:
                                      MediaQuery.of(context).size.width / 1.7,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1B26),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  padding: const EdgeInsets.only(left: 18),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 15),
                                  child: TextField(
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      hintText: "Type Something...",
                                      hintStyle: const TextStyle(
                                          color: Colors.white54),
                                      contentPadding:
                                          const EdgeInsets.only(top: 16),
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

  void _startOrStopRecording() async {
    try {
      if (isRecording) {
        recorderController.reset();
        final path = await recorderController.stop(false);
        if (path != null) {
          paths.add(path);
          isRecordingCompleted = true;
        }
      } else {
        await recorderController.record(
          path: "${appDirectory.path}/recording.m4a",
          recorderSettings: const RecorderSettings(),
        );
      }
    } catch (e) {
      debugPrint("Error in recording: $e");
    }

    if (recorderController.hasPermission) {
      setState(() {
        isRecording = !isRecording;
      });
    }
  }

  void _refreshWave() {
    if (isRecording) recorderController.refresh();
  }
}
