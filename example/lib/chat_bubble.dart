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
  late PlayerController controller;
  late StreamSubscription<PlayerState> playerStateSubscription;

  final playerWaveStyle = const PlayerWaveStyle(
    fixedWaveColor: Colors.white54,
    liveWaveColor: Colors.white,
    spacing: 6,
  );

  int audioTimeInSecond = 0;
  bool isAudioPlay = false;
  bool test = false;
  FinishMode finishMode = FinishMode.loop;
  ExpansionTileController? expansionTileController;

  @override
  void initState() {
    super.initState();
    expansionTileController = ExpansionTileController();
    controller = PlayerController();
    _preparePlayer();
    playerStateSubscription = controller.onPlayerStateChanged.listen((_) {
      setState(() {});
    });
  }

  void _preparePlayer() async {
    // Prepare player with extracting waveform if index is even.
    await controller.preparePlayer(
      path: widget.path,
      noOfSamples: playerWaveStyle.getSamplesForWidth(800),
    );

    audioTimeInSecond =
        Duration(milliseconds: await controller.getDuration()).inSeconds;
    setState(() {});
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
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.2),
            offset: const Offset(-1.0, -1.0),
            blurRadius: 6,
          ),
        ],
        color: const Color(0xFF292D32),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ExpansionTile(
        dense: true,
        controller: expansionTileController,
        shape: const Border(),
        maintainState: true,
        trailing: const SizedBox.shrink(),
        enabled: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!controller.playerState.isStopped)
              _getPlayAndPauseButtonWidget(
                icon: controller.playerState.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
                color:
                    controller.playerState.isPlaying ? Colors.red : Colors.blue,
                function: () async {
                  if (finishMode == FinishMode.pause &&
                      controller.playerState.isPaused) {
                    isAudioPlay = true;
                    expansionTileController?.expand();
                  } else {
                    var te = !isAudioPlay;
                    if (te) {
                      expansionTileController?.expand();
                    } else {
                      expansionTileController?.collapse();
                    }

                    await Future.delayed(Duration(milliseconds: 600));
                    isAudioPlay = !isAudioPlay;
                    setState(() {});
                  }

                  controller.playerState.isPlaying
                      ? await controller.pausePlayer()
                      : await controller.startPlayer();
                  controller.setFinishMode(finishMode: finishMode);
                },
              ),
            Expanded(
              child: ListTile(
                title: Text(
                  widget.path.split('/').last,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                  formattedTime(timeInSecond: audioTimeInSecond),
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        childrenPadding: EdgeInsets.zero,
        children: [
          Visibility(
            visible: isAudioPlay,
            child: AudioFileWaveforms(
              key: ValueKey(controller.hashCode),
              size: Size(MediaQuery.of(context).size.width / 1, 60),
              playerController: controller,
              waveformType: audioTimeInSecond > 30
                  ? WaveformType.fitWidth
                  : WaveformType.long,
              playerWaveStyle: playerWaveStyle,
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _getPlayAndPauseButtonWidget(
                icon: Icons.loop,
                backgroundColor:
                    finishMode == FinishMode.loop ? Colors.white : null,
                color:
                    controller.playerState.isPlaying ? Colors.red : Colors.blue,
                function: () async {
                  updateFinishMode(FinishMode.loop);
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                child: _getPlayAndPauseButtonWidget(
                  icon: Icons.pause,
                  backgroundColor:
                      finishMode == FinishMode.pause ? Colors.white : null,
                  color: controller.playerState.isPlaying
                      ? Colors.red
                      : Colors.blue,
                  function: () async {
                    updateFinishMode(FinishMode.pause);
                  },
                ),
              ),
              _getPlayAndPauseButtonWidget(
                icon: Icons.stop,
                backgroundColor:
                    finishMode == FinishMode.stop ? Colors.white : null,
                color:
                    controller.playerState.isPlaying ? Colors.red : Colors.blue,
                function: () async {
                  updateFinishMode(FinishMode.stop);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void updateFinishMode(FinishMode finishMode) {
    controller.setFinishMode(finishMode: finishMode);
    setState(() {
      this.finishMode = finishMode;
    });
  }

  Widget _getPlayAndPauseButtonWidget({
    required IconData icon,
    required Color color,
    required VoidCallback function,
    Color? backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xff222326),
        shape: BoxShape.circle,
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

  formattedTime({required int timeInSecond}) {
    int sec = timeInSecond % 60;
    int min = (timeInSecond / 60).floor();
    String minute = min.toString().length <= 1 ? "0$min" : "$min";
    String second = sec.toString().length <= 1 ? "0$sec" : "$sec";
    return "$minute : $second";
  }
}
