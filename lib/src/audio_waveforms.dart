import 'dart:async';

import 'package:flutter/material.dart';

import '/audio_waveforms.dart';
import 'base/label.dart';
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

  /// Tracks the total horizontal offset applied when the waveform is shifted backward.
  Offset _totalBackDistance = Offset.zero;
  Offset _dragOffset = Offset.zero;

  double _initialOffsetPosition = 0.0;
  late double _initialPosition;
  Duration currentlyRecordedDuration = Duration.zero;
  late StreamSubscription<Duration> streamSubscription;

  late final Size _size;
  late final WaveStyle _waveStyle;
  late final RecorderController _recorderController;
  late final bool _isRtl = widget.waveStyle.waveformRenderMode.isRtl;

  /// Duration timestamp labels shown on the waveform, added every second during recording.
  final List<Label> _labels = [];

  @override
  void initState() {
    super.initState();
    _size = widget.size;
    _waveStyle = widget.waveStyle;
    _recorderController = widget.recorderController;
    // For RTL, initial position starts at 0 (waves grow from right edge)
    // For LTR, initial position starts at negative half thickness
    _initialPosition = _isRtl ? 0.0 : -(_waveStyle.waveThickness / 2);
    _recorderController.addListener(_recorderControllerListener);
    streamSubscription =
        _recorderController.onCurrentDuration.listen((duration) {
      currentlyRecordedDuration = duration;
      final currentSeconds = currentlyRecordedDuration.inSeconds;
      if (currentSeconds > 0 && _labels.length < currentSeconds) {
        _labels.add(
          Label(
            content: _waveStyle.showHourInDuration
                ? Duration(seconds: currentSeconds).toHHMMSS()
                : currentSeconds.toMMSS(),
            // Calculate label position based on current waveform length
            // X-axis: Position label at the end of the waveform
            //         (spacing × number of wave bars = total waveform width)
            // Y-axis: Position below the waveform container
            //         (container height + line height = below the waveform)
            offset: Offset(
              _waveStyle.spacing * _recorderController.waveData.length,
              _size.height + _waveStyle.durationLinesHeight,
            ),
          ),
        );
        // Only trigger UI rebuild if widget is still in the tree
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _recorderController.removeListener(_recorderControllerListener);
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
              size: _size,
              painter: RecorderWavePainter(
                labels: _labels,
                waveThickness: _waveStyle.waveThickness,
                middleLineThickness: _waveStyle.middleLineThickness,
                middleLineColor: _waveStyle.middleLineColor,
                waveData: _recorderController.waveData,
                callPushback: _recorderController.shouldRefresh,
                bottomPadding: _waveStyle.bottomPadding ?? _size.height / 2,
                spacing: _waveStyle.spacing,
                waveCap: _waveStyle.waveCap,
                showBottom: _waveStyle.showBottom,
                showTop: _waveStyle.showTop,
                waveColor: _waveStyle.waveColor,
                showMiddleLine: _waveStyle.showMiddleLine,
                totalCurrentBackDistance: _totalBackDistance,
                dragOffset: _dragOffset,
                pushBack: _pushBackWave,
                initialPosition: _initialPosition,
                extendWaveform: _waveStyle.extendWaveform,
                showHourInDuration: _waveStyle.showHourInDuration,
                showDurationLabel: _waveStyle.showDurationLabel,
                durationLinesColor: _waveStyle.durationLinesColor,
                durationStyle: _waveStyle.durationStyle,
                durationTextPadding: _waveStyle.durationTextPadding,
                durationLinesHeight: _waveStyle.durationLinesHeight,
                labelSpacing: _waveStyle.labelSpacing,
                gradient: _waveStyle.gradient,
                shouldClearLabels: _recorderController.shouldClearLabels,
                revertClearLabelCall: _recorderController.revertClearLabelCall,
                setCurrentPositionDuration:
                    _recorderController.setScrolledPositionDuration,
                shouldCalculateScrolledPosition:
                    widget.shouldCalculateScrolledPosition,
                scaleFactor: _waveStyle.scaleFactor,
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
  double get _waveWidth => _waveStyle.waveThickness + _waveStyle.spacing;

  /// Provides extra clipping if needed.
  double get _extraClipperHeight {
    if (_waveStyle.showDurationLabel) {
      // If duration labels are enabled and for some reason labels are getting
      // cut or effecting other widget cut. This will help to reduce or add
      // clipping.
      if (_waveStyle.extraClipperHeight != null) {
        return _waveStyle.extraClipperHeight!;
      }
      // Default clipping. Calculated from duration line.
      return _waveStyle.durationLinesHeight +
          (_waveStyle.durationStyle.fontSize ?? _waveStyle.durationLinesHeight);
    } else {
      // If labels are disabled then there is no need to add/remove extra
      // clipping.
      return 0;
    }
  }

  ///This handles scrolling of the wave
  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    _recorderController.setRefresh(false);
    _isScrolled = true;

    switch (_waveStyle.waveformRenderMode) {
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
      if (!_isScrolled) {
        _totalBackDistance =
            _totalBackDistance + Offset(_waveStyle.spacing, 0.0);
      }

      // For RTL: handle refresh after scrolling
      if (_recorderController.shouldRefresh && _isScrolled) {
        _initialOffsetPosition = 0.0;
        _dragOffset = Offset.zero;
        _isScrolled = false;
        // Reset shouldRefresh flag and trigger rebuild with new values
        WidgetsBinding.instance.addPostFrameCallback(
          (_) {
            _recorderController.setRefresh(false);
          },
        );
      }
    } else {
      if (_isScrolled) {
        _initialPosition =
            _waveStyle.spacing * _recorderController.waveData.length -
                _size.width / 2;
        _totalBackDistance =
            _totalBackDistance + Offset(_waveStyle.spacing, 0.0);
        _isScrolled = false;
      } else {
        _initialPosition = 0.0;
        _totalBackDistance =
            _totalBackDistance + Offset(_waveStyle.spacing, 0.0);
      }
    }
    if (_recorderController.shouldClearLabels) {
      _initialOffsetPosition = 0.0;
      _totalBackDistance = Offset.zero;
      _dragOffset = Offset.zero;
    }
  }

  void _recorderControllerListener() {
    if (!mounted) return;

    // Only call setState if labels actually need to be cleared
    setState(() {
      if (_recorderController.shouldClearLabels) {
        _labels.clear();
      }
    });
  }

  /// Handles scrolling for LTR waveform
  void _handleScrollLtr(DragUpdateDetails details) {
    var direction = details.globalPosition.dx - _initialOffsetPosition;
    final delta = details.delta;
    final deltaDx = details.delta.dx;
    final dragOffset = _dragOffset.dx;
    final totalBackDistanceDx = -_totalBackDistance.dx;
    final halfWidth = _size.width / 2;
    final waveformWidth =
        _waveStyle.spacing * _recorderController.waveData.length;

    ///left to right
    if (totalBackDistanceDx + dragOffset + deltaDx < halfWidth &&
        direction > 0) {
      setState(() => _dragOffset += delta);
    }

    ///right to left
    else if (totalBackDistanceDx + dragOffset + waveformWidth + deltaDx >
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
        _waveStyle.spacing * _recorderController.waveData.length;

    final halfWidth = _size.width / 2;

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
