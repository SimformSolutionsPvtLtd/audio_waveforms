import 'dart:math';
import 'package:audio_waveforms/src/base/constants.dart';
import 'package:flutter/material.dart';

///Referenced from https://stackoverflow.com/questions/38744579/show-waveform-of-audio
class FileWaveformsPainter extends CustomPainter {
  List<int> waveData;
  double waveThickness;
  double multiplier;
  double density;
  int maxDuration, currentDuration;
  double animValue;
  double currentSeekPostion;
  bool showSeekLine;
  double scaleFactor;
  Color seekLineColor;
  Shader? liveWaveGradient;
  double seekLineThickness;
  bool showTop;
  bool showBottom;
  double visualizerHeight;
  Shader? staleWaveGradient;
  StrokeCap waveCap;

  FileWaveformsPainter({
    required this.waveData,
    required this.waveThickness,
    required this.multiplier,
    required this.density,
    required this.maxDuration,
    required this.currentDuration,
    required this.animValue,
    required this.currentSeekPostion,
    required this.showSeekLine,
    required this.scaleFactor,
    required this.seekLineColor,
    required this.seekLineThickness,
    required this.showTop,
    required this.showBottom,
    required this.visualizerHeight,
    required this.staleWaveGradient,
    required this.waveCap,
    this.liveWaveGradient,
  })  : wavePaint = Paint()
          ..color = Colors.white
          ..strokeWidth = waveThickness
          ..strokeCap = waveCap,
        liveAudioPaint = Paint()
          ..color = Colors.deepOrange
          ..strokeWidth = waveThickness
          ..strokeCap = waveCap,
        seeklinePaint = Paint()
          ..color = seekLineColor
          ..strokeWidth = seekLineThickness
          ..strokeCap = waveCap;

  Paint wavePaint;
  Paint liveAudioPaint;
  Paint seeklinePaint;

  double _denseness = 1.0;
  double _seekerXPosition = 0.0;

  @override
  void paint(Canvas canvas, Size size) {
    _updatePlayerPercent(size);
    _drawWave(size, canvas);
    if (showSeekLine) _drawSeekLine(size, canvas);
  }

  @override
  bool shouldRepaint(FileWaveformsPainter oldDelegate) => true;

  void _drawSeekLine(Size size, Canvas canvas) {
    if (scrubberProgress() == 1.0) {
      canvas.drawLine(
        Offset(_seekerXPosition + liveAudioPaint.strokeWidth, 0),
        Offset(_seekerXPosition + liveAudioPaint.strokeWidth, size.height),
        seeklinePaint,
      );
    } else {
      canvas.drawLine(
        Offset(_seekerXPosition, 0),
        Offset(_seekerXPosition, size.height),
        seeklinePaint,
      );
    }
  }

  void _drawWave(Size size, Canvas canvas) {
    if (liveWaveGradient != null) liveAudioPaint.shader = liveWaveGradient;
    if (staleWaveGradient != null) wavePaint.shader = staleWaveGradient;
    double totalBarsCount = size.width / dp(3);
    if (totalBarsCount <= 0.1) return;
    int samplesCount = waveData.length * 8 ~/ 5;
    double samplesPerBar = samplesCount / totalBarsCount;
    double barCounter = 0;
    int nextBarNum = 0;
    int y = (size.height - dp(visualizerHeight.toDouble())) ~/ 2;
    int barNum = 0;
    int lastBarNum;
    int drawBarCount;
    int byte;
    for (int i = 0; i < samplesCount; i++) {
      if (i != nextBarNum) {
        continue;
      }
      drawBarCount = 0;
      lastBarNum = nextBarNum;

      while (lastBarNum == nextBarNum) {
        barCounter += samplesPerBar;
        nextBarNum = barCounter.toInt();
        drawBarCount++;
      }
      int bitPointer = i * 5;
      double byteNum = bitPointer / Constants.byteSize;
      double byteBitOffset = bitPointer - byteNum * Constants.byteSize;
      int currentByteCount = (Constants.byteSize - byteBitOffset).toInt();
      int nextByteRest = 5 - currentByteCount;
      byte = (waveData[byteNum.toInt()] >> byteBitOffset.toInt() &
          ((2 << min(5, currentByteCount) - 1)) - 1);
      if (nextByteRest > 0) {
        byte <<= nextByteRest;
        byte |= waveData[byteNum.toInt() + 1] & ((2 << (nextByteRest - 1)) - 1);
      }
      for (int j = 0; j < drawBarCount; j++) {
        int x = barNum * dp(3);
        double left = x.toDouble();
        double top = y.toDouble() +
            dp(visualizerHeight - max(1, visualizerHeight * byte / 31));
        double bottom = y.toDouble() + dp(visualizerHeight).toDouble();
        if (x < size.width) {
          if (x < _denseness && x + dp(2) < _denseness) {
            _seekerXPosition = left;
            if (showBottom) {
              canvas.drawLine(
                  Offset(left, size.height / 2),
                  Offset(left, size.height / 2 + (bottom - top) * scaleFactor),
                  liveAudioPaint);
            }
            if (showTop) {
              canvas.drawLine(
                  Offset(left, size.height / 2),
                  Offset(left, size.height / 2 + (top - bottom) * scaleFactor),
                  liveAudioPaint);
            }
          } else {
            if (showBottom) {
              canvas.drawLine(
                  Offset(left, size.height / 2),
                  Offset(
                      left,
                      size.height / 2 +
                          ((bottom - top) * animValue) * scaleFactor),
                  wavePaint);
            }
            if (showTop) {
              canvas.drawLine(
                  Offset(left, size.height / 2),
                  Offset(
                      left,
                      size.height / 2 +
                          ((top - bottom) * animValue) * scaleFactor),
                  wavePaint);
            }
            if (x < _denseness) {
              _seekerXPosition = left;
              if (showBottom) {
                canvas.drawLine(
                    Offset(left, size.height / 2),
                    Offset(
                        left, size.height / 2 + (bottom - top) * scaleFactor),
                    liveAudioPaint);
              }
              if (showTop) {
                canvas.drawLine(
                    Offset(left, size.height / 2),
                    Offset(
                        left, size.height / 2 + (top - bottom) * scaleFactor),
                    liveAudioPaint);
              }
            }
          }
        }

        barNum++;
      }
    }
  }

  void _updatePlayerPercent(Size size) {
    _denseness = (size.width * scrubberProgress()).ceilToDouble();
    if (_denseness < 0) {
      _denseness = 0;
    } else if (_denseness > size.width) {
      _denseness = size.width;
    }
  }

  int dp(double value) {
    if (value == 0) return 0;
    return (density * value).ceil();
  }

  double scrubberProgress() {
    if (currentDuration / maxDuration > 0.99) {
      return 1.0;
    }
    if (maxDuration == 0) return 0;
    return currentDuration / maxDuration;
  }
}
