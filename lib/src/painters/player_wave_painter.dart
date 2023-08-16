import 'package:flutter/material.dart';

import '../base/utils.dart';

class PlayerWavePainter extends CustomPainter {
  final List<double> waveformData;
  final bool showTop;
  final bool showBottom;
  final double animValue;
  final double scaleFactor;
  final Color waveColor;
  final StrokeCap waveCap;
  final double waveThickness;
  final Shader? fixedWaveGradient;
  final Shader? liveWaveGradient;
  final double spacing;
  final Offset totalBackDistance;
  final Offset dragOffset;
  final double audioProgress;
  final Color liveWaveColor;
  final VoidCallback pushBack;
  final bool callPushback;
  final double emptySpace;
  final double scrollScale;
  final bool showSeekLine;
  final double seekLineThickness;
  final Color seekLineColor;
  final WaveformType waveformType;

  PlayerWavePainter({
    required this.waveformData,
    required this.showTop,
    required this.showBottom,
    required this.animValue,
    required this.scaleFactor,
    required this.waveColor,
    required this.waveCap,
    required this.waveThickness,
    required this.dragOffset,
    required this.totalBackDistance,
    required this.spacing,
    required this.audioProgress,
    required this.liveWaveColor,
    required this.pushBack,
    required this.callPushback,
    required this.scrollScale,
    required this.seekLineThickness,
    required this.seekLineColor,
    required this.showSeekLine,
    required this.waveformType,
    required this.cachedAudioProgress,
    this.liveWaveGradient,
    this.fixedWaveGradient,
  })  : fixedWavePaint = Paint()
          ..color = waveColor
          ..strokeWidth = waveThickness
          ..strokeCap = waveCap
          ..shader = fixedWaveGradient,
        liveWavePaint = Paint()
          ..color = liveWaveColor
          ..strokeWidth = waveThickness
          ..strokeCap = waveCap
          ..shader = liveWaveGradient,
        emptySpace = spacing,
        middleLinePaint = Paint()
          ..color = seekLineColor
          ..strokeWidth = seekLineThickness;

  Paint fixedWavePaint;
  Paint liveWavePaint;
  Paint middleLinePaint;
  double cachedAudioProgress;

  @override
  void paint(Canvas canvas, Size size) {
    _drawWave(size, canvas);
    if (showSeekLine && waveformType.isLong) _drawMiddleLine(size, canvas);
  }

  @override
  bool shouldRepaint(PlayerWavePainter oldDelegate) => true;

  void _drawMiddleLine(Size size, Canvas canvas) {
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      fixedWavePaint
        ..color = seekLineColor
        ..strokeWidth = seekLineThickness,
    );
  }

  void _drawWave(Size size, Canvas canvas) {
    final length = waveformData.length;
    final halfWidth = size.width / 2;
    final halfHeight = size.height / 2;
    if (cachedAudioProgress != audioProgress) {
      pushBack();
    }
    for (int i = 0; i < length; i++) {
      final currentDragPointer = dragOffset.dx - totalBackDistance.dx;
      final waveWidth = i * spacing;
      final dx = waveWidth +
          currentDragPointer +
          emptySpace +
          (waveformType.isFitWidth ? 0 : halfWidth);
      final waveHeight =
          (waveformData[i] * animValue) * scaleFactor * scrollScale;
      final bottomDy = halfHeight + (showBottom ? waveHeight : 0);
      final topDy = halfHeight + (showTop ? -waveHeight : 0);

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
