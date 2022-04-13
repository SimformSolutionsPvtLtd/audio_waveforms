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

  const WaveBubble({
    Key? key,
    required this.playerController,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 10, right: 20),
      child: Row(
        children: [
          AudioFileWaveforms(
            size: Size(MediaQuery.of(context).size.width / 2, 70),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFF343145)),
            padding: const EdgeInsets.only(
                bottom: 9, top: 8, left: 14, right: 12),
            clipBehavior: Clip.hardEdge,
            playerController: playerController,
            density: 1.5,
            playerWaveStyle: const PlayerWaveStyle(
              showSeeker: false,
              scaleFactor: 0.8,
              waveColor: Colors.white,
              liveWaveColor: Color.fromARGB(221, 59, 50, 173)
            ),
          ),
          IconButton(
            onPressed: onTap,
            icon: const Icon(Icons.play_arrow),
            color: Colors.white,
          )
        ],
      ),
    );
  }
}
