import 'package:flutter/material.dart';

class Wave {
  AnimationController animationController;
  Animation<double> animation;
  bool isDisposed;

  Wave({
    required this.animationController,
    required this.animation,
    this.isDisposed = false,
  });
}
