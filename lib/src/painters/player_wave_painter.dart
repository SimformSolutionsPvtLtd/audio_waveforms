import 'package:flutter/material.dart';

///Referenced from https://stackoverflow.com/questions/38744579/show-waveform-of-audio
class FileWaveformsPainter extends CustomPainter {
  List<double> waveformData;
  List<double> waveformXPostion;
  double waveThickness;
  double density;
  double currentSeekPostion;
  bool showSeekLine;
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

  FileWaveformsPainter({
    required this.waveThickness,
    required this.density,
    required this.currentSeekPostion,
    required this.showSeekLine,
    required this.scaleFactor,
    required this.seekLineColor,
    required this.seekLineThickness,
    required this.showTop,
    required this.showBottom,
    required this.visualizerHeight,
    required this.waveCap,
    required this.liveWaveColor,
    required this.waveformData,
    required this.waveformXPostion,
    required this.denseness,
    required this.audioProgress,
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

  // double _seekerXPosition = 0.0;

  @override
  void paint(Canvas canvas, Size size) {
    _drawLiveWave(size, canvas);
  }

  @override
  bool shouldRepaint(FileWaveformsPainter oldDelegate) => true;

  //TODO: fix seek line
  // void _drawSeekLine(Size size, Canvas canvas) {
  //   if (audioProgress == 1.0) {
  //     canvas.drawLine(
  //       Offset(_seekerXPosition + liveWavePaint.strokeWidth * 3, 0),
  //       Offset(_seekerXPosition + liveWavePaint.strokeWidth * 3, size.height),
  //       seeklinePaint,
  //     );
  //   } else {
  //     canvas.drawLine(
  //       Offset(
  //           waveformXPostion.last * audioProgress + liveWavePaint.strokeWidth,
  //           0),
  //       Offset(
  //           waveformXPostion.last * audioProgress + liveWavePaint.strokeWidth,
  //           size.height),
  //       seeklinePaint,
  //     );
  //   }
  // }

  void _drawLiveWave(Size size, Canvas canvas) {
    if (liveWaveGradient != null) liveWavePaint.shader = liveWaveGradient;
    for (int i = 0; i < waveformData.length; i++) {
      int x = i * _dp(3);
      if (x < size.width) {
        if (x < denseness && x + _dp(2) < denseness) {
          //_seekerXPosition = x.toDouble();
          if (showBottom) {
            canvas.drawLine(
                Offset(waveformXPostion[i], size.height / 2),
                Offset(waveformXPostion[i],
                    size.height / 2 + waveformData[i] * scaleFactor),
                liveWavePaint);
          }
          if (showTop) {
            canvas.drawLine(
                Offset(waveformXPostion[i], size.height / 2),
                Offset(waveformXPostion[i],
                    size.height / 2 + (-waveformData[i] * scaleFactor)),
                liveWavePaint);
          }
        } else {
          if (x < denseness) {
            if (showTop) {
              canvas.drawLine(
                  Offset(waveformXPostion[i], size.height / 2),
                  Offset(waveformXPostion[i],
                      size.height / 2 + (-waveformData[i] * scaleFactor)),
                  liveWavePaint);
            }
            if (showBottom) {
              canvas.drawLine(
                  Offset(waveformXPostion[i], size.height / 2),
                  Offset(waveformXPostion[i],
                      size.height / 2 + waveformData[i] * scaleFactor),
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
  List<double> waveformData;
  List<double> waveformXPostion;
  bool showTop;
  bool showBottom;
  double animValue;
  double scaleFactor;
  Color waveColor;
  StrokeCap waveCap;
  double waveThickness;
  Shader? fixedWaveGradient;

  FixedWavePainter({
    required this.waveformData,
    required this.waveformXPostion,
    required this.showTop,
    required this.showBottom,
    required this.animValue,
    required this.scaleFactor,
    required this.waveColor,
    required this.waveCap,
    required this.waveThickness,
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

    for (int i = 0; i < waveformData.length; i++) {
      if (showTop) {
        canvas.drawLine(
            Offset(waveformXPostion[i], size.height / 2),
            Offset(
                waveformXPostion[i],
                size.height / 2 +
                    ((waveformData[i] * animValue) == 0
                            ? 1
                            : (waveformData[i] * animValue)) *
                        scaleFactor),
            wavePaint);
      }
      if (showBottom) {
        canvas.drawLine(
            Offset(waveformXPostion[i], size.height / 2),
            Offset(
                waveformXPostion[i],
                size.height / 2 +
                    -((waveformData[i] * animValue) == 0
                            ? 1
                            : (waveformData[i] * animValue)) *
                        scaleFactor),
            wavePaint);
      }
    }
  }
}
