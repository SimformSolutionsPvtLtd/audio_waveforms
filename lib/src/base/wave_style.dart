import 'package:flutter/material.dart';

import '../../audio_waveforms.dart';

class WaveStyle {
  /// A model class to provide style to the waveforms.
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
    this.scaleFactor = 20.0,
    this.waveformRenderMode = WaveformRenderMode.ltr,
  }) : assert(
          waveThickness < spacing,
          "waveThickness can't be greater than spacing",
        );

  /// Color of the [Wave].
  final Color waveColor;

  /// Whether to show line in the middle defaults to true
  final bool showMiddleLine;

  /// Space between each wave
  final double spacing;

  /// Whether to show upper wave or not defaults to true
  final bool showTop;

  /// Whether to show bottom wave or not default to true
  final bool showBottom;

  /// Wave padding from bottom. Default to size.height/2.
  final double? bottomPadding;

  /// The kind of finish to place on the end of lines drawn
  ///  default to StrokeCap.round
  final StrokeCap waveCap;

  /// Color line in the middle
  final Color middleLineColor;

  /// Thickness of middle line.
  final double middleLineThickness;

  /// Width of each wave
  final double waveThickness;

  /// The background color of waveform box default is Black
  final Color backgroundColor;

  /// Extend the wave to the end of size.width, default is size.width/2.
  /// Can only be used with [WaveformRenderMode.ltr] mode.
  /// For [WaveformRenderMode.rtl], this will be ignored.
  final bool extendWaveform;

  /// Show duration labels. Default is false
  final bool showDurationLabel;

  /// Show duration label in HH:MM:SS format. Default is MM:SS
  final bool showHourInDuration;

  /// Text style for duration labels
  final TextStyle durationStyle;

  /// Color of duration lines
  final Color durationLinesColor;

  /// Height of duration lines
  final double durationLinesHeight;

  /// Space between duration labels and waveform square
  final double labelSpacing;

  /// It might happen that label text gets cut or have extra clipping.
  ///
  /// So provided +Ve value add more clipping and -Ve will reduce
  /// the clipping.
  final double? extraClipperHeight;

  /// Value > 0 will be padded right and value < 0 will be padded left.
  final double durationTextPadding;

  /// Applies this gradient to waveforms.
  ///
  /// **Use as below**
  ///
  /// ```dart
  ///      import 'dart:ui' as ui show Gradient;
  ///
  ///      ...
  ///
  ///      ui.Gradient.linear(
  ///                      const Offset(70, 50),
  ///                      Offset(MediaQuery.of(context).size.width / 2, 0),
  ///                      [Colors.red, Colors.green],
  ///                    ),
  /// ```dart
  final Shader? gradient;

  /// Default normalised amplitude/power we have are between 0.0 and 1.0.
  /// So scale them, [scaleFactor] can be used. Defaults to 20.0.
  final double scaleFactor;

  /// Defines the rendering direction of the waveform. By default, it is set to
  /// [WaveformRenderMode.ltr]. Which means the waveform will render from left
  /// to right. Once rendered waveforms reaches the end of the available width,
  /// it will start pushing the previous waves to left to make space for new
  /// waves.
  ///
  /// If set to [WaveformRenderMode.rtl], the waveform will render from right
  /// to left. Older waves will be pushed to the left to make space for new
  /// waves.
  final WaveformRenderMode waveformRenderMode;
}
