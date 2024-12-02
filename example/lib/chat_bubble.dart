import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isLast;

  const ChatBubble({
    super.key,
    required this.text,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 10, right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFF343145)),
                padding: const EdgeInsets.only(
                    bottom: 9, top: 8, left: 14, right: 12),
                child: Text(
                  text,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WaveBubble extends StatefulWidget {
  final String path;
  final double? width;
  final Directory appDirectory;

  const WaveBubble({
    super.key,
    required this.appDirectory,
    this.width,
    required this.path,
  });

  @override
  State<WaveBubble> createState() => _WaveBubbleState();
}

class _WaveBubbleState extends State<WaveBubble> {
  File? file;

  late PlayerController controller;
  late StreamSubscription<PlayerState> playerStateSubscription;

  final playerWaveStyle = const PlayerWaveStyle(
    fixedWaveColor: Colors.white54,
    liveWaveColor: Colors.white,
    spacing: 6,
  );

  @override
  void initState() {
    super.initState();
    controller = PlayerController();
    _preparePlayer();
    playerStateSubscription = controller.onPlayerStateChanged.listen((_) {
      setState(() {});
    });
  }

  void _preparePlayer() async {
    // Prepare player with extracting waveform if index is even.
    controller.preparePlayer(
      path: widget.path,
      noOfSamples: playerWaveStyle.getSamplesForWidth(800),
    );
  }

  @override
  void dispose() {
    playerStateSubscription.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.2),
            offset: const Offset(-6.0, -6.0),
            blurRadius: 16.0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            offset: const Offset(-6.0, -6.0),
            blurRadius: 16.0,
          ),
        ],
        color: const Color(0xFF292D32),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!controller.playerState.isStopped)
            _getPlayAndPauseButtonWidget(
              icon: controller.playerState.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow,
              radius: 24,
              color:
                  controller.playerState.isPlaying ? Colors.red : Colors.blue,
              function: () async {
                controller.playerState.isPlaying
                    ? await controller.pausePlayer()
                    : await controller.startPlayer();
                controller.setFinishMode(finishMode: FinishMode.loop);
              },
            ),

          const SizedBox(width: 10),
          AudioFileWaveforms(
            size: Size(MediaQuery.of(context).size.width / 2, 70),
            playerController: controller,
            waveformType: WaveformType.long,
            // waveformType: widget.index?.isOdd ?? false
            //     ? WaveformType.fitWidth
            //     : WaveformType.long,
            playerWaveStyle: playerWaveStyle,
          ),
          // if (widget.isSender) const SizedBox(width: 10),
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
          /*boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.1),
              blurRadius: 16.0,
            ),
            // BoxShadow(
            //   color: Colors.black.withOpacity(0.4),
            //   offset: const Offset(6.0, 6.0),
            //   blurRadius: 16.0,
            // ),
          ],*/
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
      ),
    );
  }
}
