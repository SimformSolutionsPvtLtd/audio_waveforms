import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isSender;

  const ChatBubble({
    Key? key,
    required this.text,
    this.isSender = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 10, right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isSender) const Spacer(),
              Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isSender
                        ? const Color(0xFF276bfd)
                        : const Color(0xFF343145)),
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

class WaveBubble extends StatelessWidget {
  final PlayerController playerController;
  final VoidCallback onTap;
  final bool isSender;
  final bool isPlaying;

  const WaveBubble({
    Key? key,
    required this.playerController,
    required this.onTap,
    required this.isPlaying,
    this.isSender = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.only(
          bottom: 6,
          right: isSender ? 0 : 10,
          top: 6,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isSender ? const Color(0xFF276bfd) : const Color(0xFF343145),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onTap,
              icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
              color: Colors.white,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            AudioFileWaveforms(
              size: Size(MediaQuery.of(context).size.width / 2, 70),
              playerController: playerController,
              density: 1.5,
              playerWaveStyle: const PlayerWaveStyle(
                scaleFactor: 0.8,
                fixedWaveColor: Colors.white30,
                liveWaveColor: Colors.white,
                waveCap: StrokeCap.butt,
              ),
            ),
            if (isSender) const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}
