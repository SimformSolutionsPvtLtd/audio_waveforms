import 'dart:async';

import 'package:audio_waveforms/src/base/wave_clipper.dart';
import 'package:audio_waveforms/src/painters/player_wave_painter.dart';
import 'package:flutter/material.dart';

import '../audio_waveforms.dart';

class AudioFileWaveforms extends StatefulWidget {
  /// A size to define height and width of waveform.
  final Size size;

  /// A PlayerController having different controls for audio player.
  final PlayerController playerController;

  /// Directly draws waveforms from this data. Extracted waveform data
  /// is ignored if waveform data is provided from this parameter.
  final List<double> waveformData;

  /// When this flag is set to true, new waves are drawn as soon as new
  /// waveform data is available from [onCurrentExtractedWaveformData].
  /// If this flag is set to false then waveforms will be drawn after waveform
  /// extraction is fully completed.
  ///
  /// This flag is ignored if [waveformData] is directly provided.
  ///
  /// See documentation of extractWaveformData in [PlayerController] to
  /// determine which value to choose.
  ///
  /// Defaults to true.
  final bool continuousWaveform;

  /// A PlayerWaveStyle instance controls how waveforms should look.
  final PlayerWaveStyle playerWaveStyle;

  /// Provides padding around waveform.
  final EdgeInsets? padding;

  /// Provides margin around waveform.
  final EdgeInsets? margin;

  /// Provides box decoration to the container having waveforms.
  final BoxDecoration? decoration;

  /// Color which is applied in to background of the waveform.
  /// If decoration is used then use color in it.
  final Color? backgroundColor;

  /// Duration for animation. Defaults to 500 milliseconds.
  final Duration animationDuration;

  /// Curve for animation. Defaults to Curves.easeIn
  final Curve animationCurve;

  /// A clipping behaviour which is applied to container having waveforms.
  final Clip clipBehavior;

  /// Draws waveform bases on selected option. For more info, see
  /// [WaveformType] documentation.
  final WaveformType waveformType;

  /// Allow seeking with gestures when turned on.
  final bool enableSeekGesture;

  /// Generate waveforms from audio file. You play those audio file using
  /// [PlayerController].
  ///
  /// When you play the audio file, waves change their color according to
  /// how much audio has been played and how much is left.
  ///
  /// With seeking gesture enabled, playing audio can be seeked to
  /// any position using gestures.
  const AudioFileWaveforms({
    Key? key,
    required this.size,
    required this.playerController,
    this.waveformData = const [],
    this.continuousWaveform = true,
    this.playerWaveStyle = const PlayerWaveStyle(),
    this.padding,
    this.margin,
    this.decoration,
    this.backgroundColor,
    this.animationDuration = const Duration(milliseconds: 500),
    this.animationCurve = Curves.easeIn,
    this.clipBehavior = Clip.none,
    this.waveformType = WaveformType.long,
    this.enableSeekGesture = true,
  }) : super(key: key);

  @override
  State<AudioFileWaveforms> createState() => _AudioFileWaveformsState();
}

class _AudioFileWaveformsState extends State<AudioFileWaveforms>
    with SingleTickerProviderStateMixin {
  late AnimationController _growingWaveController;
  late Animation<double> _growAnimation;

  double _growAnimationProgress = 0.0;
  final ValueNotifier<int> _seekProgress = ValueNotifier(0);
  bool showSeekLine = false;

  late EdgeInsets? margin;
  late EdgeInsets? padding;
  late BoxDecoration? decoration;
  late Color? backgroundColor;
  late Duration? animationDuration;
  late Curve? animationCurve;
  late Clip? clipBehavior;
  late PlayerWaveStyle? playerWaveStyle;
  late StreamSubscription<int> onCurrentDurationSubscription;
  late StreamSubscription<void> onCompletionSubscription;
  StreamSubscription<List<double>>? onCurrentExtractedWaveformData;

  @override
  void initState() {
    super.initState();
    _initialiseVariables();
    _growingWaveController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _growAnimation = CurvedAnimation(
      parent: _growingWaveController,
      curve: widget.animationCurve,
    );

    _growingWaveController
      ..forward()
      ..addListener(_updateGrowAnimationProgress);
    onCurrentDurationSubscription =
        widget.playerController.onCurrentDurationChanged.listen((event) {
      _seekProgress.value = event;
      _updatePlayerPercent(widget.size);
    });

    onCompletionSubscription =
        widget.playerController.onCompletion.listen((event) {
      _seekProgress.value = widget.playerController.maxDuration;
      _updatePlayerPercent(widget.size);
    });
    if (widget.waveformData.isNotEmpty) {
      _addWaveformData(widget.waveformData);
    } else {
      if (widget.playerController.waveformData.isNotEmpty) {
        _addWaveformData(widget.playerController.waveformData);
      }
      if (!widget.continuousWaveform) {
        widget.playerController.addListener(_addWaveformDataFromController);
      } else {
        onCurrentExtractedWaveformData = widget
            .playerController.onCurrentExtractedWaveformData
            .listen(_addWaveformData);
      }
    }
  }

  @override
  void dispose() {
    onCurrentDurationSubscription.cancel();
    onCurrentExtractedWaveformData?.cancel();
    onCompletionSubscription.cancel();
    widget.playerController.removeListener(_addWaveformDataFromController);
    _growingWaveController.dispose();
    super.dispose();
  }

  double _audioProgress = 0.0;
  double _cachedAudioProgress = 0.0;

  Offset _totalBackDistance = Offset.zero;
  Offset _dragOffset = Offset.zero;

  double _initialDragPosition = 0.0;
  double _scrollDirection = 0.0;

  bool _isScrolled = false;
  double scrollScale = 1.0;
  double _proportion = 0.0;

  final List<double> _waveformData = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding,
      margin: widget.margin,
      decoration: widget.decoration,
      clipBehavior: widget.clipBehavior,
      child: GestureDetector(
        onHorizontalDragUpdate:
            widget.enableSeekGesture ? _handleDragGestures : null,
        onTapUp: widget.enableSeekGesture ? _handleScrubberSeekStart : null,
        onHorizontalDragStart:
            widget.enableSeekGesture ? _handleHorizontalDragStart : null,
        onHorizontalDragEnd:
            widget.enableSeekGesture ? (_) => _handleOnDragEnd() : null,
        child: ClipPath(
          // TODO: Update extraClipperHeight when duration labels are added
          clipper: WaveClipper(extraClipperHeight: 0),
          child: RepaintBoundary(
            child: ValueListenableBuilder<int>(
              builder: (_, __, ___) {
                return CustomPaint(
                  isComplex: true,
                  painter: PlayerWavePainter(
                    waveformData: _waveformData,
                    spacing: widget.playerWaveStyle.spacing,
                    waveColor: widget.playerWaveStyle.fixedWaveColor,
                    fixedWaveGradient: widget.playerWaveStyle.fixedWaveGradient,
                    scaleFactor: widget.playerWaveStyle.scaleFactor,
                    waveCap: widget.playerWaveStyle.waveCap,
                    showBottom: widget.playerWaveStyle.showBottom,
                    showTop: widget.playerWaveStyle.showTop,
                    waveThickness: widget.playerWaveStyle.waveThickness,
                    animValue: _growAnimationProgress,
                    totalBackDistance: _totalBackDistance,
                    dragOffset: _dragOffset,
                    audioProgress: _audioProgress,
                    liveWaveColor: widget.playerWaveStyle.liveWaveColor,
                    liveWaveGradient: widget.playerWaveStyle.liveWaveGradient,
                    callPushback: !_isScrolled,
                    pushBack: _pushBackWave,
                    scrollScale: scrollScale,
                    seekLineColor: widget.playerWaveStyle.seekLineColor,
                    seekLineThickness: widget.playerWaveStyle.seekLineThickness,
                    showSeekLine: widget.playerWaveStyle.showSeekLine,
                    waveformType: widget.waveformType,
                    cachedAudioProgress: _cachedAudioProgress,
                  ),
                  size: widget.size,
                );
              },
              valueListenable: _seekProgress,
            ),
          ),
        ),
      ),
    );
  }

  void _addWaveformDataFromController() =>
      _addWaveformData(widget.playerController.waveformData);

  void _updateGrowAnimationProgress() {
    if (mounted) {
      setState(() {
        _growAnimationProgress = _growAnimation.value;
      });
    }
  }

  void _handleOnDragEnd() {
    _isScrolled = false;
    scrollScale = 1.0;
    if (mounted) setState(() {});

    if (widget.waveformType.isLong) {
      widget.playerController.seekTo(
        (widget.playerController.maxDuration * _proportion).toInt(),
      );
    }
  }

  void _addWaveformData(List<double> data) {
    _waveformData
      ..clear()
      ..addAll(data);
    if (mounted) setState(() {});
  }

  void _handleDragGestures(DragUpdateDetails details) {
    switch (widget.waveformType) {
      case WaveformType.fitWidth:
        _handleScrubberSeekUpdate(details);
        break;
      case WaveformType.long:
        _handleScrollUpdate(details);
        break;
    }
  }

  /// This method handles continues seek gesture
  void _handleScrubberSeekUpdate(DragUpdateDetails details) {
    _proportion = details.localPosition.dx / widget.size.width;
    var seekPosition = widget.playerController.maxDuration * _proportion;

    widget.playerController.seekTo(seekPosition.toInt());
  }

  /// This method handles tap seek gesture
  void _handleScrubberSeekStart(TapUpDetails details) {
    _proportion = details.localPosition.dx / widget.size.width;
    var seekPosition = widget.playerController.maxDuration * _proportion;

    widget.playerController.seekTo(seekPosition.toInt());
  }

  ///This method handles horizontal scrolling of the wave
  void _handleScrollUpdate(DragUpdateDetails details) {
    // Direction of the scroll. Negative value indicates scroll left to right
    // and positive value indicates scroll right to left
    _scrollDirection = details.localPosition.dx - _initialDragPosition;
    widget.playerController.setRefresh(false);
    _isScrolled = true;

    scrollScale = widget.playerWaveStyle.scrollScale;

    // left to right
    if (-_totalBackDistance.dx +
                _dragOffset.dx +
                details.delta.dx +
                (widget.playerWaveStyle.spacing) <
            widget.playerWaveStyle.spacing / 2 &&
        _scrollDirection > 0) {
      _dragOffset += details.delta;
    }

    // right to left
    else if (-_totalBackDistance.dx +
                _dragOffset.dx +
                (widget.playerWaveStyle.spacing * _waveformData.length) +
                details.delta.dx >
            -widget.playerWaveStyle.spacing / 2 &&
        _scrollDirection < 0) {
      _dragOffset += details.delta;
    }

    // Indicates location of first wave
    var start = -_totalBackDistance.dx +
        _dragOffset.dx -
        (widget.playerWaveStyle.spacing / 2);

    if (_scrollDirection < 0) {
      _proportion = (start.abs() + details.delta.dx) /
          (_waveformData.length * widget.playerWaveStyle.spacing);
    } else {
      _proportion = (details.delta.dx - start) /
          (_waveformData.length * widget.playerWaveStyle.spacing);
    }
    if (mounted) setState(() {});
  }

  ///This will help-out to determine direction of the scroll
  void _handleHorizontalDragStart(DragStartDetails details) =>
      _initialDragPosition = details.localPosition.dx;

  /// This initialises variable in [initState] so that everytime current duration
  /// gets updated it doesn't re assign them to same values.
  void _initialiseVariables() {
    if (widget.playerController.waveformData.isEmpty) {
      widget.playerController.waveformData.addAll(widget.waveformData);
    }
    showSeekLine = false;
    margin = widget.margin;
    padding = widget.padding;
    decoration = widget.decoration;
    backgroundColor = widget.backgroundColor;
    animationDuration = widget.animationDuration;
    animationCurve = widget.animationCurve;
    clipBehavior = widget.clipBehavior;
    playerWaveStyle = widget.playerWaveStyle;
  }

  /// calculates seek progress
  void _updatePlayerPercent(Size size) {
    if (widget.playerController.maxDuration == 0) return;
    _audioProgress = _seekProgress.value / widget.playerController.maxDuration;
  }

  ///This will handle pushing back the wave when it reaches to middle/end of the
  ///given size.width.
  ///
  ///This will also handle refreshing the wave after scrolled
  void _pushBackWave() {
    if (!_isScrolled && widget.waveformType.isLong) {
      _totalBackDistance = Offset(
          (widget.playerWaveStyle.spacing *
                  _audioProgress *
                  _waveformData.length) +
              widget.playerWaveStyle.spacing +
              _dragOffset.dx,
          0.0);
    }
    if (widget.playerController.shouldClearLabels) {
      _initialDragPosition = 0.0;
      _totalBackDistance = Offset.zero;
      _dragOffset = Offset.zero;
    }
    _cachedAudioProgress = _audioProgress;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }
}
