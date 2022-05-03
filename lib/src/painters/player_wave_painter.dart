import 'package:flutter/material.dart';

///Referenced from https://stackoverflow.com/questions/38744579/show-waveform-of-audio
class FileWaveformsPainter extends CustomPainter {
  List<Offset> waveform;
  double waveThickness;
  double density;
  double currentSeekPostion;
  bool showSeeker;
  double scaleFactor;
  Color seekLineColor;
  Shader? liveWaveGradient;
  double seekLineThickness;
  bool showTop;
  bool showBottom;
  double visualizerHeight;
  StrokeCap waveCap;
  Color liveWaveColor;
  double denseness;
  double audioProgress;
  double positionalPadding;

  FileWaveformsPainter({
    required this.waveform,
    required this.waveThickness,
    required this.density,
    required this.currentSeekPostion,
    required this.showSeeker,
    required this.scaleFactor,
    required this.seekLineColor,
    required this.seekLineThickness,
    required this.showTop,
    required this.showBottom,
    required this.visualizerHeight,
    required this.waveCap,
    required this.liveWaveColor,
    required this.denseness,
    required this.audioProgress,
    required this.positionalPadding,
    this.liveWaveGradient,
  })  : liveWavePaint = Paint()
          ..color = liveWaveColor
          ..strokeWidth = waveThickness
          ..strokeCap = waveCap,
        seeklinePaint = Paint()
          ..color = seekLineColor
          ..strokeWidth = seekLineThickness
          ..strokeCap = waveCap;

  Paint liveWavePaint;
  Paint seeklinePaint;

  @override
  void paint(Canvas canvas, Size size) {
    _drawLiveWave(size, canvas);
    if (showSeeker) _drawSeekLine(size, canvas);
  }

  @override
  bool shouldRepaint(FileWaveformsPainter oldDelegate) => true;

  void _drawSeekLine(Size size, Canvas canvas) {
    var progress = waveform.last.dx * audioProgress;
    canvas.drawLine(
      Offset(progress + liveWavePaint.strokeWidth * 2, 0),
      Offset(progress + liveWavePaint.strokeWidth * 2, size.height),
      seeklinePaint,
    );
  }

  void _drawLiveWave(Size size, Canvas canvas) {
    if (liveWaveGradient != null) liveWavePaint.shader = liveWaveGradient;
    for (int i = 0; i < waveform.length; i++) {
      int x = i * _dp(3);
      if (x < size.width) {
        if (x < denseness && x + _dp(2) < denseness) {
          if (showBottom) {
            canvas.drawLine(
                Offset(waveform[i].dx, size.height / 2 + positionalPadding),
                Offset(
                    waveform[i].dx,
                    size.height / 2 +
                        waveform[i].dy * scaleFactor +
                        positionalPadding),
                liveWavePaint);
          }
          if (showTop) {
            canvas.drawLine(
                Offset(waveform[i].dx, size.height / 2),
                Offset(
                    waveform[i].dx,
                    size.height / 2 +
                        (-waveform[i].dy * scaleFactor + positionalPadding)),
                liveWavePaint);
          }
        } else {
          if (x < denseness) {
            if (showTop) {
              canvas.drawLine(
                  Offset(waveform[i].dx, size.height / 2),
                  Offset(
                      waveform[i].dx,
                      size.height / 2 +
                          (-waveform[i].dy * scaleFactor + positionalPadding)),
                  liveWavePaint);
            }
            if (showBottom) {
              canvas.drawLine(
                  Offset(waveform[i].dx, size.height / 2),
                  Offset(
                      waveform[i].dx,
                      size.height / 2 +
                          waveform[i].dy * scaleFactor +
                          positionalPadding),
                  liveWavePaint);
            }
          }
        }
      }
    }
  }

  int _dp(double value) {
    if (value == 0) return 0;
    return (density * value).ceil();
  }
}

class FixedWavePainter extends CustomPainter {
  List<Offset> waveform;
  bool showTop;
  bool showBottom;
  double animValue;
  double scaleFactor;
  Color waveColor;
  StrokeCap waveCap;
  double waveThickness;
  Shader? fixedWaveGradient;
  double positionalPadding;

  FixedWavePainter({
    required this.waveform,
    required this.showTop,
    required this.showBottom,
    required this.animValue,
    required this.scaleFactor,
    required this.waveColor,
    required this.waveCap,
    required this.waveThickness,
    required this.positionalPadding,
    this.fixedWaveGradient,
  }) : wavePaint = Paint()
          ..color = waveColor
          ..strokeWidth = waveThickness
          ..strokeCap = waveCap;

  Paint wavePaint;

  @override
  void paint(Canvas canvas, Size size) {
    _drawFixedWave(size, canvas);
  }

  @override
  bool shouldRepaint(FixedWavePainter oldDelegate) => false;

  void _drawFixedWave(Size size, Canvas canvas) {
    if (fixedWaveGradient != null) wavePaint.shader = fixedWaveGradient;

    for (int i = 0; i < waveform.length; i++) {
      if (showTop) {
        canvas.drawLine(
            Offset(waveform[i].dx, size.height / 2 + positionalPadding),
            Offset(
                waveform[i].dx,
                size.height / 2 +
                    ((waveform[i].dy * animValue) == 0
                            ? 1
                            : (waveform[i].dy * animValue)) *
                        scaleFactor +
                    positionalPadding),
            wavePaint);
      }
      if (showBottom) {
        canvas.drawLine(
            Offset(waveform[i].dx, size.height / 2 + positionalPadding),
            Offset(
                waveform[i].dx,
                size.height / 2 +
                    -((waveform[i].dy * animValue) == 0
                            ? 1
                            : (waveform[i].dy * animValue)) *
                        scaleFactor +
                    positionalPadding),
            wavePaint);
      }
    }
  }
}
