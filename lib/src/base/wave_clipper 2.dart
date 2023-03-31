import 'package:flutter/material.dart';

///This clipper clips left and right side of waveform square so that waves
///doesn't get outside of the bounds
///
/// This clipper also allows extra clipping height to label so that they can be
/// visible.
class WaveClipper extends CustomClipper<Path> {
  final double extraClipperHeight;

  WaveClipper(this.extraClipperHeight);

  @override
  getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height + extraClipperHeight)
      ..lineTo(size.width, size.height + extraClipperHeight)
      ..lineTo(size.width, 0);
    return path;
  }

  @override
  bool shouldReclip(WaveClipper oldClipper) => false;
}
