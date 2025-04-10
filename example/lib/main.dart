import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:audio_waveforms_example/chat_bubble.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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

  String? path;
  String? musicFile;
  bool isRecording = false;
  bool isRecordingCompleted = false;
  bool isLoading = true;
  late Directory appDirectory;

  final settings = const RecorderSettings(
    androidEncoderSettings:
        AndroidEncoderSettings(androidEncoder: AndroidEncoder.wav),
    sampleRate: 48000,
    bitRate: 128000,
  );

  @override
  void initState() {
    super.initState();
    _getDir();
    _initialiseControllers();
  }

  void _getDir() async {
    appDirectory = await getApplicationDocumentsDirectory();
    path = "${appDirectory.path}/vv.wav";
    isLoading = false;
    setState(() {});
  }

  void _initialiseControllers() {
    recorderController = RecorderController();
  }

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      musicFile = result.files.single.path;
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

  List<String> paths = [];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(),
      child: Scaffold(
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
                            isSender: index.isOdd,
                            width: MediaQuery.of(context).size.width / 2,
                            appDirectory: appDirectory,
                            path: paths[index],
                          );
                        },
                      ),
                    ),
                    // if (isRecordingCompleted)
                    //   WaveBubble(
                    //     path: path,
                    //     isSender: true,
                    //     appDirectory: appDirectory,
                    //   ),
                    if (musicFile != null)
                      WaveBubble(
                        path: musicFile,
                        isSender: true,
                        appDirectory: appDirectory,
                      ),
                    SafeArea(
                      child: Row(
                        children: [
                          Expanded(
                            child: AnimatedSwitcher(
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
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                        color: const Color(0xFF1E1B26),
                                      ),
                                      padding: const EdgeInsets.only(left: 18),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 15),
                                    )
                                  : Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E1B26),
                                        borderRadius:
                                            BorderRadius.circular(12.0),
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
                          IconButton(
                            onPressed: () {
                              recorderController.pause();
                              isLoading = false;
                              setState(() {});
                            },
                            icon: const Icon(Icons.pause),
                            color: Colors.white,
                            iconSize: 28,
                          ),
                          IconButton(
                            onPressed: _startOrStopRecording,
                            icon: const Icon(Icons.stop),
                            color: Colors.white,
                            iconSize: 28,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _startOrStopRecording() async {
    try {
      if (isRecording) {
        //   recorderController.reset();
        //
        path = await recorderController.stop(true);
        paths.add(path!);
        //
        //   if (path != null) {
        //     isRecordingCompleted = true;
        //     debugPrint(path);
        //     debugPrint("Recorded file size: ${File(path!).lengthSync()}");
        //   }
        // } else {
        //   await recorderController.record(path: path); // Path is optional
      } else {
        await recorderController.record(
          path: path,
          recorderSettings: settings,
        );
      } // Path is optional
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (recorderController.hasPermission) {
        setState(() {
          isRecording = !isRecording;
        });
      }
    }
  }

  void _refreshWave() {
    if (isRecording) recorderController.refresh();
  }
}
