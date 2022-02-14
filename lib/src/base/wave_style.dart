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

  ///Thickness of middle line
  final double middleLineThickness;

  ///Width of each wave
  final double waveThickness;

  ///The background color of waveform box default is Black
  final Color backgroundColor;

  ///Extend the wave to the end of size.width, default is size.width/2
  final bool extendWaveform;

  ///Has no effect
  ///[Reseaon] -> laying out text is expensive task so for now not included
  final bool showDurationLine;

  ///Has no effect
  final bool showHourInDuration;

  ///Has no effect
  final TextStyle durationStyle;

  ///Has no effect
  final Color durationLinesColor;

  ///Has no effect
  ///value > 0 will be padded right and value < 0 will be padded left
  final double durationTextPadding;

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
    this.showDurationLine = true,
    this.extendWaveform = false,
    this.backgroundColor = Colors.black,
    this.showHourInDuration = false,
    this.durationStyle = const TextStyle(
      color: Colors.red,
      fontSize: 16.0,
    ),
    this.durationTextPadding = 20.0,
    this.durationLinesColor = Colors.blueAccent,
  }) : assert(waveThickness < spacing,
            "waveThickness can't be greater than spacing");
}
