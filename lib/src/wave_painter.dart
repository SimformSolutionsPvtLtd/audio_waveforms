import '/src/base/label.dart';
import 'package:flutter/material.dart';
import 'base/utils.dart';

///This will paint the waveform
///Addtional Information
///this gives location of first wave from right to left
///-totalBackDistance.dx + dragOffset.dx + (spacing * i)
///this gives location of first wave from left to right
///-totalBackDistance.dx + dragOffset.dx
class WavePainter extends CustomPainter {
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
  final double updateFrequecy;
  final Paint _wavePaint;
  final Paint _linePaint;
  final Paint _durationLinePaint;
  final TextStyle durationStyle;
  final Color durationLinesColor;
  final double durationTextPadding;
  final double durationLinesHeight;
  final double labelSpacing;
  final Shader? gradient;

  WavePainter({
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
    required this.updateFrequecy,
    required this.showHourInDuration,
    required this.showDurationLabel,
    required this.durationStyle,
    required this.durationLinesColor,
    required this.durationTextPadding,
    required this.durationLinesHeight,
    required this.labelSpacing,
    required this.gradient,
  })  : _wavePaint = Paint()
          ..color = waveColor
          ..strokeWidth = waveThickness
          ..strokeCap = waveCap,
        _linePaint = Paint()
          ..color = middleLineColor
          ..strokeWidth = middleLineThickness,
        _durationLinePaint = Paint()
          ..strokeWidth = 2
          ..color = durationLinesColor;
  var _labelPadding = 0.0;

  final List<Label> _labels = [];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < waveData.length; i++) {
      ///wave gradient
      if (gradient != null) _waveGradient();

      if (((spacing * i) + dragOffset.dx + spacing >
              size.width / (extendWaveform ? 1 : 2) + totalBackDistance.dx) &&
          callPushback) {
        pushBack();
      }

      ///upper wave
      if (showTop) _drawUpperWave(canvas, size, i);

      ///lower wave
      if (showBottom) _drawLowerWave(canvas, size, i);

      ///duration labels
      if (showDurationLabel) {
        _addLabel(canvas, i, size);
        _drawTextInRange(canvas, i, size);
      }
    }

    ///middle line
    if (showMiddleLine) _drawMiddleLine(canvas, size);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return true;
  }

  void _drawTextInRange(Canvas canvas, int i, Size size) {
    if (_labels.isNotEmpty) {
      final textSpan = TextSpan(
        text: _labels[i].content,
        style: durationStyle,
      );

      if (_labels[i].offset.dx > -size.width / 2 &&
          _labels[i].offset.dx < size.width + size.width / 2) {
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout(minWidth: 0, maxWidth: size.width);
        textPainter.paint(
          canvas,
          _labels[i].offset,
        );
      }
    }
  }

  void _addLabel(Canvas canvas, int i, Size size) {
    canvas.drawLine(
        Offset(
            _labelPadding + dragOffset.dx - totalBackDistance.dx, size.height),
        Offset(_labelPadding + dragOffset.dx - totalBackDistance.dx,
            size.height + durationLinesHeight),
        _durationLinePaint);
    _labels.add(
      Label(
        content: showHourInDuration
            ? Duration(seconds: i).toHHMMSS()
            : Duration(seconds: i).inSeconds.toMMSS(),
        offset: Offset(
            _labelPadding +
                dragOffset.dx -
                totalBackDistance.dx -
                durationTextPadding,
            size.height + labelSpacing),
      ),
    );
    _labelPadding += spacing * updateFrequecy;
  }

  void _drawMiddleLine(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      _linePaint,
    );
  }

  void _drawUpperWave(Canvas canvas, Size size, int i) {
    canvas.drawLine(
        Offset(
            -totalBackDistance.dx +
                dragOffset.dx +
                (spacing * i) -
                initialPosition,
            size.height - bottomPadding),
        Offset(
            -totalBackDistance.dx +
                dragOffset.dx +
                (spacing * i) -
                initialPosition,
            -waveData[i] + size.height - bottomPadding),
        _wavePaint);
  }

  void _drawLowerWave(Canvas canvas, Size size, int i) {
    canvas.drawLine(
        Offset(
            -totalBackDistance.dx +
                dragOffset.dx +
                (spacing * i) -
                initialPosition,
            size.height - bottomPadding),
        Offset(
            -totalBackDistance.dx +
                dragOffset.dx +
                (spacing * i) -
                initialPosition,
            waveData[i] + size.height - bottomPadding),
        _wavePaint);
  }

  void _waveGradient() {
    _wavePaint.shader = gradient;
  }
}
