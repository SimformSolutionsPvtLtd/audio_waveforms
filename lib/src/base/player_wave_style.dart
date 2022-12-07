import 'package:flutter/material.dart';

class PlayerWaveStyle {
  ///Color of the [wave] which is behind the live wave.
  final Color fixedWaveColor;

  ///Color of the [live] wave which indicates currently played part.
  final Color liveWaveColor;

  /// Space between two waves.
  final double spacing;

  ///Whether to show upper wave or not defaults to true
  final bool showTop;

  ///Whether to show bottom wave or not default to true
  final bool showBottom;

  /// The kind of finish to place on the end of lines drawn.
  /// Default to StrokeCap.round
  final StrokeCap waveCap;

  /// Color line in the middle
  final Color seekLineColor;

  /// Thickness of seek line. For microphone recording this line
  /// is in the middle.
  final double seekLineThickness;

  /// Width of each wave
  final double waveThickness;

  /// The background color of waveform box default is Black
  final Color backgroundColor;

  /// Provide gradient to waves which is behind the live wave.
  /// Use shader as shown in example.
  final Shader? fixedWaveGradient;

  /// This is applied to each wave while generating.
  /// Use this to scale the waves. Defaults to 100.0.
  final double scaleFactor;

  /// This gradient is applied to waves which indicates currently played part.
  final Shader? liveWaveGradient;

  /// Scales the wave when waveforms are seeked. The scaled waves returns back
  /// to original scale when gesture ends. To get result set value greater then
  /// 1.
  final double scrollScale;

  /// Shows seek line in the middle when enabled.
  final bool showSeekLine;

  const PlayerWaveStyle({
    this.fixedWaveColor = Colors.white54,
    this.liveWaveColor = Colors.white,
    this.showTop = true,
    this.showBottom = true,
    this.showSeekLine = true,
    this.waveCap = StrokeCap.round,
    this.seekLineColor = Colors.white,
    this.seekLineThickness = 2.0,
    this.waveThickness = 3.0,
    this.backgroundColor = Colors.black,
    this.fixedWaveGradient,
    this.scaleFactor = 100.0,
    this.liveWaveGradient,
    this.spacing = 5,
    this.scrollScale = 1.0,
  })  : assert(spacing >= 0),
        assert(waveThickness < spacing,
            "waveThickness can't be greater than spacing");

  /// Determines number of samples which will fit in provided width.
  /// Returned number of samples are also dependent on [spacing] set for
  /// this constructor.
  int getSamplesForWidth(double width) {
    return width ~/ spacing;
  }
}
