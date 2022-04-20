import 'package:flutter/material.dart';

class PlayerWaveStyle {
  ///Color of the [wave] which is behind the live wave.
  final Color fixedWaveColor;

  ///Color of the [live] wave which idicates currenly played part.
  final Color liveWaveColor;

  ///Whether to show seeker or not
  //TODO: fix seek line
  // final bool showSeeker;

  ///Whether to show upper wave or not defaults to true
  final bool showTop;

  ///Whether to show bottom wave or not default to true
  final bool showBottom;

  ///The kind of finish to place on the end of lines drawn
  /// default to StrokeCap.round
  final StrokeCap waveCap;

  ///Color line in the middle
  final Color seekLineColor;

  ///Thickness of seek line. For microphone recording this line is in the middle
  final double seekLineThickness;

  ///Width of each wave
  final double waveThickness;

  ///The background color of waveform box default is Black
  final Color backgroundColor;

  ///Provide gradient to waves which is behind the live wave. Use shader as shown in example.
  final Shader? fixedWavegradient;

  ///This is applied to each wave while generating. Use this to [scale] the waves.
  /// Defaluts to 1.0.
  final double scaleFactor;

  ///This gradient is applied to waves which idicates currenly played part.
  final Shader? liveWaveGradient;

  ///Constant height the wave bar. Height is also dependent on scaleFactor and density.
  final double visualizerHeight;

  const PlayerWaveStyle({
    this.fixedWaveColor = Colors.white,
    this.liveWaveColor = Colors.deepOrange,
    this.showTop = true,
    this.showBottom = true,
    this.waveCap = StrokeCap.round,
    this.seekLineColor = Colors.orange,
    this.seekLineThickness = 3.0,
    this.waveThickness = 3.0,
    this.backgroundColor = Colors.black,
    this.fixedWavegradient,
    this.scaleFactor = 1.0,
    this.liveWaveGradient,
    this.visualizerHeight = 28.0,
  });
}
