import 'package:flutter/material.dart';

import '/src/base/label.dart';

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
    required this.totalCurrentBackDistance,
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
    required this.labels,
    required this.isRtl,
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

  /// This gives total current distance the waves have been pushed back
  final Offset totalCurrentBackDistance;
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
  final ValueSetter<int> setCurrentPositionDuration;
  final bool shouldCalculateScrolledPosition;
  final double scaleFactor;
  final Duration currentlyRecordedDuration;
  final List<Label> labels;
  final bool isRtl;

  static const int durationBuffer = 5;

  @override
  void paint(Canvas canvas, Size size) {
    if (shouldClearLabels) {
      pushBack();
      revertClearLabelCall();
    }

    // Wave gradient
    if (gradient != null) _waveGradient();

    if (isRtl) {
      // For RTL: call pushBack when refresh is triggered (e.g., after scrolling)
      if (callPushback) {
        pushBack();
      }

      for (var i = 0; i < waveData.length; i++) {
        _drawRtlWave(canvas, i, size);
      }
    } else {
      for (var i = 0; i < waveData.length; i++) {
        if (((spacing * i) + dragOffset.dx + spacing >
                size.width / (extendWaveform ? 1 : 2) +
                    totalCurrentBackDistance.dx) &&
            callPushback) {
          pushBack();
        }

        // draws waves
        _drawLtrWave(canvas, size, i);
      }
    }

    // duration labels
    if (showDurationLabel) {
      _drawTextInRange(canvas, size);
    }

    // middle line
    if (showMiddleLine) _drawMiddleLine(canvas, size);

    // calculates scrolled position with respect to duration
    if (shouldCalculateScrolledPosition) {
      if (isRtl) {
        _setScrolledDurationRtl(size);
      } else {
        _setScrolledDuration(size);
      }
    }
  }

  @override
  bool shouldRepaint(RecorderWavePainter oldDelegate) => true;

  void _drawTextInRange(Canvas canvas, Size size) {
    for (var i = 0; i < labels.length; i++) {
      final label = labels[i];
      final content = label.content;
      Offset offset;
      if (isRtl) {
        // For RTL: labels follow wave positions (from right edge)
        final currentWaveformWidth = spacing * waveData.length;
        final labelWaveformWidth = label.offset.dx;
        final distanceFromRight = currentWaveformWidth - labelWaveformWidth;
        final labelX = size.width - distanceFromRight + dragOffset.dx;
        offset = Offset(labelX, label.offset.dy);
      } else {
        offset = label.offset - totalCurrentBackDistance + dragOffset;
      }
      final halfWidth = size.width * 0.5;

      if (offset.dx > -halfWidth && offset.dx < halfWidth * 3) {
        canvas.drawLine(
          Offset(offset.dx + durationTextPadding, size.height),
          Offset(
            offset.dx + durationTextPadding,
            size.height + durationLinesHeight,
          ),
          _durationLinePaint,
        );

        final textSpan = TextSpan(
          text: content,
          style: durationStyle,
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(minWidth: 0, maxWidth: halfWidth * 2);
        textPainter.paint(canvas, offset);
      }
    }
  }

  void _drawMiddleLine(Canvas canvas, Size size) {
    final halfWidth = size.width * 0.5;
    canvas.drawLine(
      Offset(halfWidth, 0),
      Offset(halfWidth, size.height),
      _linePaint,
    );
  }

  /// Draw wave for LTR direction
  void _drawLtrWave(Canvas canvas, Size size, int i) {
    final height = size.height;
    final dx = -totalCurrentBackDistance.dx +
        dragOffset.dx +
        (spacing * i) -
        initialPosition;
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

  /// Draw wave for RTL direction
  void _drawRtlWave(Canvas canvas, int i, Size size) {
    final height = size.height;
    // For RTL: newest wave at right edge, older waves move left
    // Wave position: right edge minus offset based on wave index from the end
    final dx = size.width - (spacing * (waveData.length - i)) + dragOffset.dx;

    final scaledWaveHeight = waveData[i] * scaleFactor;
    final upperDy = height - (showTop ? scaledWaveHeight : 0) - bottomPadding;
    final lowerDy =
        height + (showBottom ? scaledWaveHeight : 0) - bottomPadding;

    // We will check here for starting position [dx]
    // to be less than size.width and
    // the dx cannot be less than 0
    // This condition will ensure that only visible
    // portions of waves are being drawn to user
    // and [dx < size.width] will ensure only fully visible waves are drawn,
    // if any wave is half visible this will cut out that wave too.
    if (dx < size.width && dx > 0) {
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
      (((-totalCurrentBackDistance.dx + dragOffset.dx - (size.width / 2)) /
                  spacing) *
              1000)
          .abs()
          .toInt(),
    );
  }

  /// Set scrolled duration for RTL mode
  void _setScrolledDurationRtl(Size size) {
    setCurrentPositionDuration(
      (((-dragOffset.dx + (size.width / 2)) / spacing) * 1000).abs().toInt(),
    );
  }
}
