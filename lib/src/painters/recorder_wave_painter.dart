import 'package:flutter/material.dart';

import '/src/base/label.dart';
import '../base/utils.dart';

///This will paint the waveform
///
///Addtional Information to play around
///
///this gives location of first wave from right to left when scrolling
///
///-totalBackDistance.dx + dragOffset.dx + (spacing * i)
///
///this gives location of first wave from left to right when scrolling
///
///-totalBackDistance.dx + dragOffset.dx
class RecorderWavePainter extends CustomPainter {
  RecorderWavePainter({
    required this.waveData,
    required this.waveColor,
    required this.showMiddleLine,
    required this.spacing,
    required this.initialPosition,
    required this.showTop,
    required this.showBottom,
    required this.bottomPadding,
    required this.waveCap,
    required this.middleLineColor,
    required this.middleLineThickness,
    required this.totalBackDistance,
    required this.dragOffset,
    required this.waveThickness,
    required this.pushBack,
    required this.callPushback,
    required this.extendWaveform,
    required this.showHourInDuration,
    required this.showDurationLabel,
    required this.durationStyle,
    required this.durationLinesColor,
    required this.durationTextPadding,
    required this.durationLinesHeight,
    required this.labelSpacing,
    required this.gradient,
    required this.shouldClearLabels,
    required this.revertClearLabelCall,
    required this.setCurrentPositionDuration,
    required this.shouldCalculateScrolledPosition,
    required this.scaleFactor,
    required this.currentlyRecordedDuration,
  })  : _wavePaint = Paint()
          ..color = waveColor
          ..strokeWidth = waveThickness
          ..strokeCap = waveCap,
        _linePaint = Paint()
          ..color = middleLineColor
          ..strokeWidth = middleLineThickness,
        _durationLinePaint = Paint()
          ..strokeWidth = 3
          ..color = durationLinesColor;

  final List<double> waveData;
  final Color waveColor;
  final bool showMiddleLine;
  final double spacing;
  final double initialPosition;
  final bool showTop;
  final bool showBottom;
  final double bottomPadding;
  final StrokeCap waveCap;
  final Color middleLineColor;
  final double middleLineThickness;
  final Offset totalBackDistance;
  final Offset dragOffset;
  final double waveThickness;
  final VoidCallback pushBack;
  final bool callPushback;
  final bool extendWaveform;
  final bool showDurationLabel;
  final bool showHourInDuration;
  final Paint _wavePaint;
  final Paint _linePaint;
  final Paint _durationLinePaint;
  final TextStyle durationStyle;
  final Color durationLinesColor;
  final double durationTextPadding;
  final double durationLinesHeight;
  final double labelSpacing;
  final Shader? gradient;
  final bool shouldClearLabels;
  final VoidCallback revertClearLabelCall;
  final Function(int) setCurrentPositionDuration;
  final bool shouldCalculateScrolledPosition;
  final double scaleFactor;
  final Duration currentlyRecordedDuration;
  var _labelPadding = 0.0;

  final List<Label> _labels = [];
  static const int durationBuffer = 5;

  @override
  void paint(Canvas canvas, Size size) {
    if (shouldClearLabels) {
      _labels.clear();
      pushBack();
      revertClearLabelCall();
    }

    // Wave gradient
    if (gradient != null) _waveGradient();

    for (var i = 0; i < waveData.length; i++) {
      if (((spacing * i) + dragOffset.dx + spacing >
              size.width / (extendWaveform ? 1 : 2) + totalBackDistance.dx) &&
          callPushback) {
        pushBack();
      }

      ///draws waves
      _drawWave(canvas, size, i);

      ///duration labels
      if (showDurationLabel) {
        _addLabel(canvas, i, size);
        _drawTextInRange(canvas, i, size);
      }
    }

    ///middle line
    if (showMiddleLine) _drawMiddleLine(canvas, size);

    ///calculates scrolled position with respect to duration
    if (shouldCalculateScrolledPosition) _setScrolledDuration(size);
  }

  @override
  bool shouldRepaint(RecorderWavePainter oldDelegate) => true;

  void _drawTextInRange(Canvas canvas, int i, Size size) {
    if (_labels.isNotEmpty && i < _labels.length) {
      final label = _labels[i];
      final content = label.content;
      final offset = label.offset;
      final halfWidth = size.width * 0.5;
      final textSpan = TextSpan(
        text: content,
        style: durationStyle,
      );

      // Text painting is performance intensive process so we will only render
      // labels whose position is greater then -halfWidth and triple of
      // halfWidth because it will be in visible viewport and it has extra
      // buffer so that bigger labels can be visible when they are extremely at
      // right or left.
      if (offset.dx > -halfWidth && offset.dx < halfWidth * 3) {
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(minWidth: 0, maxWidth: halfWidth * 2);
        textPainter.paint(canvas, offset);
      }
    }
  }

  void _addLabel(Canvas canvas, int i, Size size) {
    final labelDuration = Duration(seconds: i);
    final durationLineDx = _labelPadding + dragOffset.dx - totalBackDistance.dx;
    final height = size.height;
    final currentDuration =
        Duration(seconds: currentlyRecordedDuration.inSeconds + durationBuffer);
    if (labelDuration < currentDuration) {
      canvas.drawLine(
        Offset(durationLineDx, height),
        Offset(durationLineDx, height + durationLinesHeight),
        _durationLinePaint,
      );
      _labels.add(
        Label(
          content: showHourInDuration
              ? labelDuration.toHHMMSS()
              : labelDuration.inSeconds.toMMSS(),
          offset: Offset(
            durationLineDx - durationTextPadding,
            height + labelSpacing,
          ),
        ),
      );
    }
    _labelPadding += spacing;
  }

  void _drawMiddleLine(Canvas canvas, Size size) {
    final halfWidth = size.width * 0.5;
    canvas.drawLine(
      Offset(halfWidth, 0),
      Offset(halfWidth, size.height),
      _linePaint,
    );
  }

  void _drawWave(Canvas canvas, Size size, int i) {
    final height = size.height;
    final dx =
        -totalBackDistance.dx + dragOffset.dx + (spacing * i) - initialPosition;
    final scaledWaveHeight = waveData[i] * scaleFactor;
    final upperDy = height - (showTop ? scaledWaveHeight : 0) - bottomPadding;
    final lowerDy =
        height + (showBottom ? scaledWaveHeight : 0) - bottomPadding;

    // We will check here for starting position [dx]
    // to be grater than 0 and
    // the dx cannot be greater than canvas width
    // This condition will ensure that only visible
    // portions of waves are being drawn to user
    // and [dx > 0] will ensure only fully visible waves are drawn,
    // if any wave is half visible this will cut out that wave too.
    if (dx > 0 && dx < size.width) {
      canvas.drawLine(
        Offset(dx, upperDy),
        Offset(dx, lowerDy),
        _wavePaint,
      );
    }
  }

  void _waveGradient() {
    _wavePaint.shader = gradient;
  }

  void _setScrolledDuration(Size size) {
    setCurrentPositionDuration(
        (((-totalBackDistance.dx + dragOffset.dx - (size.width / 2)) /
                    spacing) *
                1000)
            .abs()
            .toInt());
  }
}
