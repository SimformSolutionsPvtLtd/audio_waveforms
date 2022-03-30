import 'package:flutter/material.dart';
import '/audio_waveforms.dart';
import 'painters/recorder_wave_painter.dart';
import 'base/wave_clipper.dart';

class AudioWaveforms extends StatefulWidget {
  final Size size;
  final RecorderController waveController;
  final WaveStyle waveStyle;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BoxDecoration? decoration;
  final Color? backgroundColor;
  final bool enableGesture;

  const AudioWaveforms({
    Key? key,
    required this.size,
    required this.waveController,
    this.waveStyle = const WaveStyle(),
    this.enableGesture = false,
    this.padding,
    this.margin,
    this.decoration,
    this.backgroundColor,
  }) : super(key: key);

  @override
  _AudioWaveformsState createState() => _AudioWaveformsState();
}

class _AudioWaveformsState extends State<AudioWaveforms> {
  bool _isScrolled = false;

  Offset _totalBackDistance = Offset.zero;
  Offset _dragOffset = Offset.zero;

  double _initialOffsetPosition = 0.0;
  double _initialPosition = 0.0;

  @override
  void initState() {
    super.initState();
    widget.waveController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    widget.waveController.removeListener(() {});
    super.dispose();
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
                waveData: widget.waveController.waveData,
                callPushback: widget.waveController.shouldRefresh,
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
                    widget.waveController.updateFrequency.inMilliseconds,
                durationTextPadding: widget.waveStyle.durationTextPadding,
                durationLinesHeight: widget.waveStyle.durationLinesHeight,
                labelSpacing: widget.waveStyle.labelSpacing,
                gradient: widget.waveStyle.gradient,
                shouldClearLabels: widget.waveController.shouldClearLabels,
                revertClearlabelCall:
                    widget.waveController.revertClearlabelCall,
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
    widget.waveController.setRefresh(false);
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
                    widget.waveController.waveData.length) +
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
          widget.waveStyle.spacing * widget.waveController.waveData.length -
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
}
