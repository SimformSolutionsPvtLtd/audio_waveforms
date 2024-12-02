import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:audio_waveforms_example/audio_recorder.dart';
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

  String? path;
  String? musicFile;
  bool isRecording = false;
  bool isRecordingCompleted = false;
  bool isLoading = true;
  bool isFromAssets = false;
  Directory? appDirectory;
  List<File> audioFiles = [];

  @override
  void initState() {
    super.initState();
    _getDir();
    _initialiseControllers();
  }

  void _getDir() async {
    appDirectory = await getApplicationDocumentsDirectory();
    path = "${appDirectory!.path}/recording.m4a";
    setState(() {});
    loadAllAudioFiles();
    isLoading = false;
  }

  void _initialiseControllers() {
    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100;
  }

  void loadAllAudioFiles() async {
    loadFileInMemory();
    isFromAssets = true;
    setState(() {});
  }

  void loadFileInMemory() async {
    // Opening file from assets folder
    final file1 = File('${appDirectory!.path}/audio1.mp3');
    await file1.writeAsBytes((await rootBundle.load('assets/audios/audio1.mp3'))
        .buffer
        .asUint8List());
    audioFiles.add(file1);

    final file2 = File('${appDirectory!.path}/audio2.mp3');
    await file2.writeAsBytes((await rootBundle.load('assets/audios/audio2.mp3'))
        .buffer
        .asUint8List());
    audioFiles.add(file2);

    final file3 = File('${appDirectory!.path}/audio3.mp3');
    await file3.writeAsBytes((await rootBundle.load('assets/audios/audio3.mp3'))
        .buffer
        .asUint8List());
    audioFiles.add(file3);

    final file4 = File('${appDirectory!.path}/audio4.mp3');
    await file4.writeAsBytes((await rootBundle.load('assets/audios/audio4.mp3'))
        .buffer
        .asUint8List());
    audioFiles.add(file4);
    setState(() {});
  }

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      musicFile = result.files.single.path;
      audioFiles.add(File(musicFile!));
      isFromAssets = false;
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
      backgroundColor: const Color(0xff222326),
      appBar: AppBar(
        backgroundColor: const Color(0xff222326),
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
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: () async {
              await _startOrStopRecording();

              if (!context.mounted) {
                return;
              }
              showModalBottomSheet(
                showDragHandle: true,
                backgroundColor: const Color(0xff222326),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                context: context,
                builder: (context) {
                  return AudioRecorder(
                    appDirectory: appDirectory!,
                    isRecording: isRecording,
                    isRecordingCompleted: isRecordingCompleted,
                    musicFile: musicFile,
                    path: path,
                    recorderController: recorderController,
                    function: () async {
                      path = await recorderController.stop(false);

                      if (path != null) {
                        isRecordingCompleted = true;
                        debugPrint(path);
                        debugPrint(
                            "Recorded file size: ${File(path!).lengthSync()}");
                        isRecording = !isRecording;
                      }
                    },
                    updatePath: (filePath) {
                      audioFiles.add(File(filePath!));
                      setState(() {});
                    },
                  );
                },
              ).then((_) {
                recorderController.stop();
              });
            },
            backgroundColor: const Color(0xFF292D32),
            elevation: 5,
            child: const Icon(
              Icons.mic,
              color: Colors.blue,
            ),
          ),
          const SizedBox(
            width: 16,
          ),
          FloatingActionButton(
            onPressed: () async {
              _pickFile();
            },
            backgroundColor: const Color(0xFF292D32),
            elevation: 5,
            child: const Icon(
              Icons.upload_file,
              color: Colors.blue,
            ),
          ),
        ],
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
                      itemCount: audioFiles.length,
                      padding: const EdgeInsets.only(
                        bottom: 80,
                      ),
                      itemBuilder: (_, index) {
                        return WaveBubble(
                          path: audioFiles[index].path,
                          width: MediaQuery.of(context).size.width / 2,
                          appDirectory: appDirectory!,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Future<void> _startOrStopRecording() async {
    try {
      if (isRecording) {
        recorderController.reset();

        path = await recorderController.stop(false);

        if (path != null) {
          isRecordingCompleted = true;
          debugPrint(path);
          debugPrint("Recorded file size: ${File(path!).lengthSync()}");
        }
      } else {
        await recorderController.record(path: path); // Path is optional
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        isRecording = !isRecording;
      });
    }
  }

  void _refreshWave() {
    if (isRecording) recorderController.refresh();
  }

  Widget _getRecordOrUploadFileWidget({
    required IconData icon,
    required Color color,
    required VoidCallback function,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 16.0,
          ),
          // BoxShadow(
          //   color: Colors.black.withOpacity(0.4),
          //   offset: const Offset(6.0, 6.0),
          //   blurRadius: 16.0,
          // ),
        ],
      ),
      child: Center(
        child: IconButton(
          onPressed: function,
          icon: Icon(icon),
          color: color,
        ),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xff222326),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 16.0,
          ),
        ],
      ),
      child: Center(
        child: IconButton(
          onPressed: function,
          icon: Icon(icon),
          color: color,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
      ),
    );
  }
}
