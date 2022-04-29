import 'package:audio_waveforms/src/base/wave.dart';
import 'package:flutter/material.dart';

import '/audio_waveforms.dart';
import 'base/wave_clipper.dart';
import 'painters/recorder_wave_painter.dart';

class AudioWaveforms extends StatefulWidget {
  final Size size;
  final RecorderController recorderController;
  final WaveStyle waveStyle;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BoxDecoration? decoration;
  final Color? backgroundColor;
  final bool enableGesture;
  final Duration waveAnimationDuration;
  final Curve waveAnimationCurve;

  const AudioWaveforms({
    Key? key,
    required this.size,
    required this.recorderController,
    this.waveStyle = const WaveStyle(),
    this.enableGesture = false,
    this.waveAnimationDuration = const Duration(milliseconds: 300),
    this.waveAnimationCurve = Curves.easeIn,
    this.padding,
    this.margin,
    this.decoration,
    this.backgroundColor,
  }) : super(key: key);

  @override
  _AudioWaveformsState createState() => _AudioWaveformsState();
}

class _AudioWaveformsState extends State<AudioWaveforms>
    with TickerProviderStateMixin {
  bool _isScrolled = false;

  Offset _totalBackDistance = Offset.zero;
  Offset _dragOffset = Offset.zero;

  double _initialOffsetPosition = 0.0;
  double _initialPosition = 0.0;

  final List<Wave> _waves = [];

  @override
  void initState() {
    super.initState();
    widget.recorderController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    widget.recorderController.removeListener(() {});
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (var i = _waves.length - 1; i >= 0; i--) {
      if (_waves[i].isDisposed) {
        break;
      }
      _waves[i].animationController.dispose();
      _waves[i].animation.removeListener(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding,
      margin: widget.margin,
      color: widget.backgroundColor,
      decoration: widget.decoration,
      child: GestureDetector(
        onHorizontalDragUpdate:
            widget.enableGesture ? _handleHorizontalDragUpdate : null,
        onHorizontalDragStart:
            widget.enableGesture ? _handleHorizontalDragStart : null,
        child: ClipPath(
          clipper: WaveClipper(!widget.waveStyle.showDurationLabel
              ? 0.0
              : widget.waveStyle.extraClipperHeight ??
                  (widget.waveStyle.durationLinesHeight +
                      (widget.waveStyle.durationStyle.fontSize ??
                          widget.waveStyle.durationLinesHeight))),
          child: RepaintBoundary(
            child: CustomPaint(
              size: widget.size,
              painter: WavePainter(
                waveThickness: widget.waveStyle.waveThickness,
                middleLineThickness: widget.waveStyle.middleLineThickness,
                middleLineColor: widget.waveStyle.middleLineColor,
                waveData: widget.recorderController.waveData,
                callPushback: widget.recorderController.shouldRefresh,
                bottomPadding:
                    widget.waveStyle.bottomPadding ?? widget.size.height / 2,
                spacing: widget.waveStyle.spacing,
                waveCap: widget.waveStyle.waveCap,
                showBottom: widget.waveStyle.showBottom,
                showTop: widget.waveStyle.showTop,
                waveColor: widget.waveStyle.waveColor,
                showMiddleLine: widget.waveStyle.showMiddleLine,
                totalBackDistance: _totalBackDistance,
                dragOffset: _dragOffset,
                pushBack: _pushBackWave,
                initialPosition: _initialPosition,
                extendWaveform: widget.waveStyle.extendWaveform,
                showHourInDuration: widget.waveStyle.showHourInDuration,
                showDurationLabel: widget.waveStyle.showDurationLabel,
                durationLinesColor: widget.waveStyle.durationLinesColor,
                durationStyle: widget.waveStyle.durationStyle,
                updateFrequecy: const Duration(seconds: 1).inMilliseconds /
                    widget.recorderController.updateFrequency.inMilliseconds,
                durationTextPadding: widget.waveStyle.durationTextPadding,
                durationLinesHeight: widget.waveStyle.durationLinesHeight,
                labelSpacing: widget.waveStyle.labelSpacing,
                gradient: widget.waveStyle.gradient,
                shouldClearLabels: widget.recorderController.shouldClearLabels,
                revertClearlabelCall:
                    widget.recorderController.revertClearlabelCall,
                addUpperAnimatedWaves: _addAnimatedWave,
                animatedWaves: _waves,
              ),
            ),
          ),
        ),
      ),
    );
  }

  ///This handles scrolling of the wave
  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    var direction = details.globalPosition.dx - _initialOffsetPosition;
    widget.recorderController.setRefresh(false);
    _isScrolled = true;

    ///left to right
    if (-_totalBackDistance.dx + _dragOffset.dx + details.delta.dx <
            (widget.waveStyle.extendWaveform
                ? widget.size.width
                : widget.size.width / 2) &&
        direction > 0) {
      setState(() => _dragOffset += details.delta);
    }

    ///right to left
    else if (-_totalBackDistance.dx +
                _dragOffset.dx +
                (widget.waveStyle.spacing *
                    widget.recorderController.waveData.length) +
                details.delta.dx >
            (widget.waveStyle.extendWaveform
                ? widget.size.width
                : widget.size.width / 2) &&
        direction < 0) {
      setState(() => _dragOffset += details.delta);
    }
  }

  ///This will help-out to determine to get direction of the scroll
  void _handleHorizontalDragStart(DragStartDetails details) {
    _initialOffsetPosition = details.globalPosition.dx;
  }

  ///This will handle pushing back the wave when it reaches to middle/end of the
  ///given size.width.
  ///
  ///This will also handle refreshing the wave after scrolled
  void _pushBackWave() {
    if (_isScrolled) {
      _initialPosition =
          widget.waveStyle.spacing * widget.recorderController.waveData.length -
              widget.size.width / 2;
      _totalBackDistance =
          _totalBackDistance + Offset(widget.waveStyle.spacing, 0.0);
      _isScrolled = false;
    } else {
      _initialPosition = 0.0;
      _totalBackDistance =
          _totalBackDistance + Offset(widget.waveStyle.spacing, 0.0);
    }
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      setState(() {});
    });
  }

  void _addAnimatedWave(int i) {
    if (_waves.isEmpty) {
      _addWave();
    } else {
      if (_waves.length > i) {
        _addWave();
      }
      _waves[i].animationController.forward();
      _waves[i].animation.addListener(() {
        if (mounted) setState(() {});
      });
      _waves[i].animationController.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _waves[i].animationController.dispose();
          _waves[i].animation.removeListener(() {});
          _waves[i].isDisposed = true;
        }
      });
    }
  }

  void _addWave() {
    var controller = AnimationController(
      vsync: this,
      duration: widget.waveAnimationDuration,
    );
    _waves.add(
      Wave(
        animationController: controller,
        animation: Tween(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: controller,
            curve: widget.waveAnimationCurve,
          ),
        ),
      ),
    );
  }
}
