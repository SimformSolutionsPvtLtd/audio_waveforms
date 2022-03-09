import 'package:audio_wave/audio_wave.dart';
import 'package:audio_wave/src/base/wave_style.dart';
import 'package:audio_wave/src/wave_painter.dart';
import 'package:flutter/material.dart';
import './base/wave_controller.dart';

class AudioWave extends StatefulWidget {
  final Size size;
  final Duration updateFrequency;
  final WaveController waveController;
  final WaveStyle waveStyle;

  const AudioWave({
    Key? key,
    required this.size,
    required this.updateFrequency,
    required this.waveController,
    this.waveStyle = const WaveStyle(),
  }) : super(key: key);

  @override
  _AudioWaveState createState() => _AudioWaveState();
}

class _AudioWaveState extends State<AudioWave> {
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
    return GestureDetector(
      onHorizontalDragUpdate: _handleHorizontalDragUpdate,
      onHorizontalDragStart: _handleHorizontalDragStart,
      child: ColoredBox(
        color: widget.waveStyle.backgroundColor,
        child: RepaintBoundary(
          child: CustomPaint(
            size: widget.size,
            isComplex: false,
            willChange: true,
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
              showDurationLine: widget.waveStyle.showDurationLine,
              durationLinesColor: widget.waveStyle.durationLinesColor,
              durationStyle: widget.waveStyle.durationStyle,
              updateFrequecy: const Duration(seconds: 1).inMilliseconds /
                  widget.waveController.updateFrequency.inMilliseconds,
              durationTextPadding: widget.waveStyle.durationTextPadding,
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
  ///given size.width
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
