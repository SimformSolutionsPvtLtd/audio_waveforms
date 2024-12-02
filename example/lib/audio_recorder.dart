import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';

typedef UpdatePath = void Function(String? path);

class AudioRecorder extends StatefulWidget {
  AudioRecorder({
    required this.recorderController,
    required this.isRecording,
    required this.isRecordingCompleted,
    required this.musicFile,
    required this.appDirectory,
    this.path = '',
    required this.function,
    required this.updatePath,
    super.key,
  });

  final RecorderController recorderController;
  bool isRecording;
  bool isRecordingCompleted;
  final String? musicFile;
  final Directory appDirectory;
  String? path;
  final VoidCallback function;
  final UpdatePath updatePath;

  @override
  State<AudioRecorder> createState() => _AudioRecorderState();
}

class _AudioRecorderState extends State<AudioRecorder> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xff222326),
                borderRadius: BorderRadius.circular(24),
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
              child: const Center(
                child: Icon(
                  Icons.mic_sharp,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (widget.isRecording) ...[
            AudioWaveforms(
              enableGesture: true,
              size: Size(MediaQuery.of(context).size.width / 2, 50),
              recorderController: widget.recorderController,
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
            ),
            const SizedBox(height: 20),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _getPlayAndPauseButtonWidget(
                icon: Icons.flag,
                radius: 32,
                color: Colors.white,
                function: () {},
              ),
              _getPlayAndPauseButtonWidget(
                icon: widget.isRecording
                    ? Icons.stop
                    : Icons.play_circle_outline_rounded,
                radius: 40,
                color: widget.isRecording ? Colors.red : Colors.blue,
                function: () async {
                  if (widget.recorderController.recorderState ==
                      RecorderState.stopped) {
                    widget.recorderController.record();
                    widget.isRecording = true;
                  } else {
                    widget.path = await widget.recorderController.stop();

                    if (widget.path != null) {
                      widget.updatePath(widget.path);
                      debugPrint(widget.path);
                      widget.isRecording = !widget.isRecording;
                    }
                  }
                  setState(() {});
                },
              ),
              _getPlayAndPauseButtonWidget(
                icon: Icons.arrow_circle_right,
                radius: 32,
                color: Colors.white,
                function: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getPlayAndPauseButtonWidget({
    required IconData icon,
    required double radius,
    required Color color,
    required VoidCallback function,
  }) {
    return CircleAvatar(
      radius: radius,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xff222326),
          borderRadius: BorderRadius.circular(24),
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
      ),
    );
  }
}
