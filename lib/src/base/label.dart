import 'package:flutter/material.dart';

///Duration labels for AudioWaveform widget.
class Label {
  Label({
    required this.content,
    required this.offset,
  });

  /// Fixed label content for a single instance.
  final String content;

  /// An offset for labels which get new position everytime waveforms are
  /// scrolled.
  Offset offset;
}
