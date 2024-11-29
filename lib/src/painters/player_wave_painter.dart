import 'package:flutter/material.dart';

import '../../audio_waveforms.dart';

class PlayerWavePainter extends CustomPainter {
  final List<double> waveformData;
  final double animValue;
  final Offset totalBackDistance;
  final Offset dragOffset;
  final double audioProgress;
  final VoidCallback pushBack;
  final bool callPushback;
  final double emptySpace;
  final double scrollScale;
  final WaveformType waveformType;

  final PlayerWaveStyle playerWaveStyle;

  PlayerWavePainter({
    required this.waveformData,
    required this.animValue,
    required this.dragOffset,
    required this.totalBackDistance,
    required this.audioProgress,
    required this.pushBack,
    required this.callPushback,
    required this.scrollScale,
    required this.waveformType,
    required this.cachedAudioProgress,
    required this.playerWaveStyle,
  })  : fixedWavePaint = Paint()
          ..color = playerWaveStyle.fixedWaveColor
          ..strokeWidth = playerWaveStyle.waveThickness
          ..strokeCap = playerWaveStyle.waveCap
          ..shader = playerWaveStyle.fixedWaveGradient,
        liveWavePaint = Paint()
          ..color = playerWaveStyle.liveWaveColor
          ..strokeWidth = playerWaveStyle.waveThickness
          ..strokeCap = playerWaveStyle.waveCap
          ..shader = playerWaveStyle.fixedWaveGradient,
        emptySpace = playerWaveStyle.spacing,
        middleLinePaint = Paint()
          ..color = playerWaveStyle.seekLineColor
          ..strokeWidth = playerWaveStyle.seekLineThickness;

  Paint fixedWavePaint;
  Paint liveWavePaint;
  Paint middleLinePaint;
  double cachedAudioProgress;

  @override
  void paint(Canvas canvas, Size size) {
    _drawWave(size, canvas);
    if (playerWaveStyle.showSeekLine && waveformType.isLong) {
      _drawMiddleLine(size, canvas);
    }
  }

  @override
  bool shouldRepaint(PlayerWavePainter oldDelegate) => true;

  void _drawMiddleLine(Size size, Canvas canvas) {
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      fixedWavePaint
        ..color = playerWaveStyle.seekLineColor
        ..strokeWidth = playerWaveStyle.seekLineThickness,
    );
  }

  void _drawWave(Size size, Canvas canvas) {
    final length = waveformData.length;
    final halfWidth = size.width * 0.5;
    final halfHeight = size.height * 0.5;
    if (cachedAudioProgress != audioProgress) {
      pushBack();
    }
    for (int i = 0; i < length; i++) {
      final currentDragPointer = dragOffset.dx - totalBackDistance.dx;
      final waveWidth = i * playerWaveStyle.spacing;
      final dx = waveWidth +
          currentDragPointer +
          emptySpace +
          (waveformType.isFitWidth ? 0 : halfWidth);
      final waveHeight = (waveformData[i] * animValue) *
          playerWaveStyle.scaleFactor *
          scrollScale;
      final bottomDy =
          halfHeight + (playerWaveStyle.showBottom ? waveHeight : 0);
      final topDy = halfHeight + (playerWaveStyle.showTop ? -waveHeight : 0);

      // Only draw waves which are in visible viewport.
      if (dx > 0 && dx < halfWidth * 2) {
        canvas.drawLine(
          Offset(dx, bottomDy),
          Offset(dx, topDy),
          i < audioProgress * length ? liveWavePaint : fixedWavePaint,
        );
      }
    }
  }
}
