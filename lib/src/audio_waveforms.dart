import 'dart:async';

import 'package:flutter/material.dart';

import '/audio_waveforms.dart';
import 'base/wave_clipper.dart';
import 'painters/recorder_wave_painter.dart';

class AudioWaveforms extends StatefulWidget {
  const AudioWaveforms({
    super.key,
    required this.size,
    required this.recorderController,
    this.waveStyle = const WaveStyle(),
    this.enableGesture = false,
    this.padding,
    this.margin,
    this.decoration,
    this.backgroundColor,
    this.shouldCalculateScrolledPosition = false,
  });

  final Size size;
  final RecorderController recorderController;
  final WaveStyle waveStyle;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BoxDecoration? decoration;
  final Color? backgroundColor;
  final bool enableGesture;
  final bool shouldCalculateScrolledPosition;

  @override
  State<AudioWaveforms> createState() => _AudioWaveformsState();
}

class _AudioWaveformsState extends State<AudioWaveforms> {
  bool _isScrolled = false;

  Offset _totalBackDistance = Offset.zero;
  Offset _dragOffset = Offset.zero;

  double _initialOffsetPosition = 0.0;
  late double _initialPosition;
  Duration currentlyRecordedDuration = Duration.zero;
  late StreamSubscription<Duration> streamSubscription;

  late final bool _isRtl = widget.waveStyle.waveformRenderMode.isRtl;

  @override
  void initState() {
    super.initState();
    // For RTL, initial position starts at 0 (waves grow from right edge)
    // For LTR, initial position starts at negative half thickness
    _initialPosition = _isRtl ? 0.0 : -(widget.waveStyle.waveThickness / 2);
    widget.recorderController.addListener(_recorderControllerListener);
    streamSubscription =
        widget.recorderController.onCurrentDuration.listen((duration) {
      currentlyRecordedDuration = duration;
    });
  }

  @override
  void dispose() {
    widget.recorderController.removeListener(_recorderControllerListener);
    streamSubscription.cancel();
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
          clipper: WaveClipper(
            extraClipperHeight: _extraClipperHeight,
            waveWidth: _waveWidth,
          ),
          child: RepaintBoundary(
            child: CustomPaint(
              size: widget.size,
              painter: RecorderWavePainter(
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
                durationTextPadding: widget.waveStyle.durationTextPadding,
                durationLinesHeight: widget.waveStyle.durationLinesHeight,
                labelSpacing: widget.waveStyle.labelSpacing,
                gradient: widget.waveStyle.gradient,
                shouldClearLabels: widget.recorderController.shouldClearLabels,
                revertClearLabelCall:
                    widget.recorderController.revertClearLabelCall,
                setCurrentPositionDuration:
                    widget.recorderController.setScrolledPositionDuration,
                shouldCalculateScrolledPosition:
                    widget.shouldCalculateScrolledPosition,
                scaleFactor: widget.waveStyle.scaleFactor,
                currentlyRecordedDuration: currentlyRecordedDuration,
                isRtl: _isRtl,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Gets width of a single wave including space between two waves.
  double get _waveWidth =>
      widget.waveStyle.waveThickness + widget.waveStyle.spacing;

  /// Provides extra clipping if needed.
  double get _extraClipperHeight {
    if (widget.waveStyle.showDurationLabel) {
      // If duration labels are enabled and for some reason labels are getting
      // cut or effecting other widget cut. This will help to reduce or add
      // clipping.
      if (widget.waveStyle.extraClipperHeight != null) {
        return widget.waveStyle.extraClipperHeight!;
      }
      // Default clipping. Calculated from duration line.
      return widget.waveStyle.durationLinesHeight +
          (widget.waveStyle.durationStyle.fontSize ??
              widget.waveStyle.durationLinesHeight);
    } else {
      // If labels are disabled then there is no need to add/remove extra
      // clipping.
      return 0;
    }
  }

  ///This handles scrolling of the wave
  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    widget.recorderController.setRefresh(false);
    _isScrolled = true;

    switch (widget.waveStyle.waveformRenderMode) {
      case WaveformRenderMode.ltr:
        _handleScrollLtr(details);
      case WaveformRenderMode.rtl:
        _handleScrollRtl(details);
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
    if (_isRtl) {
      // For RTL: handle refresh after scrolling
      if (widget.recorderController.shouldRefresh && _isScrolled) {
        _initialOffsetPosition = 0.0;
        _dragOffset = Offset.zero;
        _isScrolled = false;
        // Reset shouldRefresh flag and trigger rebuild with new values
        WidgetsBinding.instance.addPostFrameCallback(
          (_) {
            widget.recorderController.setRefresh(false);
          },
        );
      }
    } else {
      if (_isScrolled) {
        _initialPosition = widget.waveStyle.spacing *
                widget.recorderController.waveData.length -
            widget.size.width / 2;
        _totalBackDistance =
            _totalBackDistance + Offset(widget.waveStyle.spacing, 0.0);
        _isScrolled = false;
      } else {
        _initialPosition = 0.0;
        _totalBackDistance =
            _totalBackDistance + Offset(widget.waveStyle.spacing, 0.0);
      }
      if (widget.recorderController.shouldClearLabels) {
        _initialOffsetPosition = 0.0;
        _totalBackDistance = Offset.zero;
        _dragOffset = Offset.zero;
      }
    }
  }

  void _recorderControllerListener() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Handles scrolling for LTR waveform
  void _handleScrollLtr(DragUpdateDetails details) {
    var direction = details.globalPosition.dx - _initialOffsetPosition;
    final delta = details.delta;
    final deltaDx = details.delta.dx;
    final dragOffset = _dragOffset.dx;
    final totalBackDistanceDx = -_totalBackDistance.dx;
    final halfWidth = widget.size.width / 2;
    final waveformWidth =
        widget.waveStyle.spacing * widget.recorderController.waveData.length;

    ///left to right
    if (-totalBackDistanceDx + dragOffset + deltaDx < halfWidth &&
        direction > 0) {
      setState(() => _dragOffset += delta);
    }

    ///right to left
    else if (-totalBackDistanceDx + dragOffset + waveformWidth + deltaDx >
            halfWidth &&
        direction < 0) {
      setState(() => _dragOffset += delta);
    }
  }

  /// Handles scrolling for RTL waveform
  void _handleScrollRtl(DragUpdateDetails details) {
    var direction = details.globalPosition.dx - _initialOffsetPosition;
    final delta = details.delta;
    final dragOffsetDx = _dragOffset.dx;

    final waveformWidth =
        widget.waveStyle.spacing * widget.recorderController.waveData.length;

    final halfWidth = widget.size.width / 2;

    /// right to left
    if (direction < 0 && dragOffsetDx > -halfWidth) {
      setState(() => _dragOffset += delta);
    }

    /// left to right
    else if (direction > 0 && dragOffsetDx < waveformWidth - halfWidth) {
      setState(() => _dragOffset += delta);
    }
  }
}
