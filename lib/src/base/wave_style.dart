import 'package:flutter/material.dart';

class WaveStyle {
  ///Color of the [Wave]
  final Color waveColor;

  ///Whether to show line in the middle defaults to true
  final bool showMiddleLine;

  ///Space between each wave
  final double spacing;

  ///Whether to show upper wave or not defaults to true
  final bool showTop;

  ///Whether to show bottom wave or not default to true
  final bool showBottom;

  ///Wave padding from bottom default is size.height/2
  final double? bottomPadding;

  ///The kind of finish to place on the end of lines drawn
  /// default to StrokeCap.round
  final StrokeCap waveCap;

  ///Color line in the middle
  final Color middleLineColor;

  ///Thickness of middle line.
  final double middleLineThickness;

  ///Width of each wave
  final double waveThickness;

  ///The background color of waveform box default is Black
  final Color backgroundColor;

  ///Extend the wave to the end of size.width, default is size.width/2
  final bool extendWaveform;

  ///Show duration labels. Default is false
  final bool showDurationLabel;

  ///Show duration label in HH:MM:SS format. Default is MM:SS
  final bool showHourInDuration;

  ///Text style for duration labels
  final TextStyle durationStyle;

  ///Color of duration lines
  final Color durationLinesColor;

  ///Height of duration lines
  final double durationLinesHeight;

  ///Space between duration labels and waveform square
  final double labelSpacing;

  ///It might happen that label text gets cut or have extra clipping.
  ///
  ///So use this to add or remove clipping
  final double? extraClipperHeight;

  ///Value > 0 will be padded right and value < 0 will be padded left
  final double durationTextPadding;

  ///Provide gradient to waveform using this. Use shader as shown in example.
  final Shader? gradient;

  ///This is applied to each wave while generating. Use this to [scale] the waves.
  /// Defaluts to 1.0.
  final double scaleFactor;

  ///A model class to provide style to the waveforms.
  const WaveStyle({
    this.waveColor = Colors.blueGrey,
    this.showMiddleLine = true,
    this.spacing = 8.0,
    this.showTop = true,
    this.showBottom = true,
    this.bottomPadding,
    this.waveCap = StrokeCap.round,
    this.middleLineColor = Colors.redAccent,
    this.middleLineThickness = 3.0,
    this.waveThickness = 3.0,
    this.showDurationLabel = false,
    this.extendWaveform = false,
    this.backgroundColor = Colors.black,
    this.showHourInDuration = false,
    this.durationLinesHeight = 16.0,
    this.durationStyle = const TextStyle(
      color: Colors.red,
      fontSize: 16.0,
    ),
    this.extraClipperHeight,
    this.labelSpacing = 16.0,
    this.durationTextPadding = 20.0,
    this.durationLinesColor = Colors.blueAccent,
    this.gradient,
    this.scaleFactor = 1.0,
  }) : assert(waveThickness < spacing,
            "waveThickness can't be greater than spacing");
}
