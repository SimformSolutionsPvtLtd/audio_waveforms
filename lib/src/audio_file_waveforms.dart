import 'dart:math';

import 'package:audio_waveforms/src/base/platform_streams.dart';
import 'package:audio_waveforms/src/painters/player_wave_painter.dart';
import 'package:flutter/material.dart';

import '../audio_waveforms.dart';
import 'base/constants.dart';

class AudioFileWaveforms extends StatefulWidget {
  ///Height and width of waveform.
  final Size size;

  ///Use this control the waveform.
  final PlayerController playerController;

  ///Use this to style the waveform.
  final PlayerWaveStyle playerWaveStyle;

  ///Use this to give padding around waveform.
  final EdgeInsets? padding;

  ///Use this to give margin around waveform.
  final EdgeInsets? margin;

  ///Use this to decorate background of waveforms
  final BoxDecoration? decoration;

  ///background color of waveform. if decoration is used then use color in it.
  final Color? backgroundColor;

  ///Enable/Disable seeking using gestures. Defaults to true.
  final bool enableSeekGesture;

  ///Duration for animation. Defaults to 500 milliseconds.
  final Duration animationDuration;

  ///Curve for animation. Defaults to Curves.bounceOut
  final Curve animationCurve;

  ///Density of the display. Providing accurate density is not neccesary, if desired looking
  ///waveforms are needed.
  ///
  /// Lower the density higher number of bar and smaller in size will be in the waveform.
  /// To scale them use [scaleFactor].
  final double density;

  ///To clip the waves.
  final Clip clipBehavior;

  ///Generate waveforms from audio file. You play those audio file using [PlayerController].
  ///When you play the audio file, another waveform
  /// will drawn on top of it to show
  /// how much audio has been played and how much is left.
  ///
  /// With seeking gesture enabled, playing audio can be seeked to any postion using
  /// gestures.
  ///
  /// Waveforms are dependent on provided width. If dynamic width is provided,
  ///
  /// eg. MediaQueary.of(context).size.width then  it may vary from device to device.
  const AudioFileWaveforms({
    Key? key,
    required this.size,
    required this.playerController,
    this.playerWaveStyle = const PlayerWaveStyle(),
    this.enableSeekGesture = true,
    this.padding,
    this.margin,
    this.decoration,
    this.backgroundColor,
    this.animationDuration = const Duration(milliseconds: 500),
    this.animationCurve = Curves.ease,
    this.density = 2,
    this.clipBehavior = Clip.none,
  }) : super(key: key);

  @override
  State<AudioFileWaveforms> createState() => _AudioFileWaveformsState();
}

class _AudioFileWaveformsState extends State<AudioFileWaveforms>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> animation;
  double _animProgress = 0.0;
  final ValueNotifier<int> _seekProgress = ValueNotifier(0);
  bool showSeekLine = false;
  late List<int> _waveData;
  late EdgeInsets? margin;
  late EdgeInsets? padding;
  late BoxDecoration? decoration;
  late Color? backgroundColor;
  late Duration? animationDuration;
  late Curve? animationCurve;
  late double? density;
  late Clip? clipBehavior;
  late PlayerWaveStyle? playerWaveStyle;

  @override
  void initState() {
    super.initState();
    _initialiseVariables();
    _calculateWaveform().whenComplete(() {
      animationController.forward();
      animation.addListener(() {
        if (mounted) {
          setState(() {
            _animProgress = animation.value;
          });
        }
      });
    });
    animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    animation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: animationController, curve: widget.animationCurve));
    PlatformStreams.instance.onDurationChanged.listen((event) {
      if (widget.playerController.playerKey == event.playerKey) {
        _seekProgress.value = event.type;
        _updatePlayerPercent(widget.size);
      }
    });
  }

  @override
  void dispose() {
    animation.removeListener(() {});
    animationController.dispose();
    super.dispose();
  }

  double _currentSeekPositon = 0.0;
  double _denseness = 0.0;
  double _audioProgress = 0.0;

  final List<double> _waveformData = [];
  final List<double> _waveformXPositions = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding,
      margin: widget.margin,
      decoration: widget.decoration,
      color: widget.backgroundColor,
      clipBehavior: widget.clipBehavior,
      child: GestureDetector(
        onHorizontalDragUpdate:
            widget.enableSeekGesture ? _handleScrubberSeekUpdate : null,
        onHorizontalDragStart:
            widget.enableSeekGesture ? _handleScrubberSeekStart : null,
        child: RepaintBoundary(
          child: ValueListenableBuilder<int>(
            builder: (context, _, __) {
              return CustomPaint(
                isComplex: true,
                foregroundPainter: FileWaveformsPainter(
                  density: widget.density,
                  currentSeekPostion: _currentSeekPositon,
                  showSeekLine: showSeekLine,
                  scaleFactor: widget.playerWaveStyle.scaleFactor,
                  seekLineColor: widget.playerWaveStyle.seekLineColor,
                  liveWaveGradient: widget.playerWaveStyle.liveWaveGradient,
                  waveThickness: widget.playerWaveStyle.waveThickness,
                  seekLineThickness: widget.playerWaveStyle.seekLineThickness,
                  showBottom: widget.playerWaveStyle.showBottom,
                  showTop: widget.playerWaveStyle.showTop,
                  visualizerHeight: widget.playerWaveStyle.visualizerHeight,
                  waveCap: widget.playerWaveStyle.waveCap,
                  liveWaveColor: widget.playerWaveStyle.liveWaveColor,
                  waveformData: _waveformData,
                  waveformXPostion: _waveformXPositions,
                  denseness: _denseness,
                  audioProgress: _audioProgress,
                ),
                painter: FixedWavePainter(
                  waveformData: _waveformData,
                  waveformXPostion: _waveformXPositions,
                  waveColor: widget.playerWaveStyle.fixedWaveColor,
                  fixedWaveGradient: widget.playerWaveStyle.fixedWavegradient,
                  scaleFactor: widget.playerWaveStyle.scaleFactor,
                  waveCap: widget.playerWaveStyle.waveCap,
                  showBottom: widget.playerWaveStyle.showBottom,
                  showTop: widget.playerWaveStyle.showTop,
                  waveThickness: widget.playerWaveStyle.waveThickness,
                  animValue: _animProgress,
                ),
                size: widget.size,
              );
            },
            valueListenable: _seekProgress,
          ),
        ),
      ),
    );
  }

  ///This handles continues seek gesture
  void _handleScrubberSeekUpdate(DragUpdateDetails details) {
    var proportion = details.localPosition.dx / widget.size.width;
    var seekPostion = widget.playerController.maxDuration * proportion;
    widget.playerController.seekTo(seekPostion.toInt());
    _currentSeekPositon = details.globalPosition.dx;
    setState(() {});
  }

  ///This handles tap seek gesture
  void _handleScrubberSeekStart(DragStartDetails details) {
    var proportion = details.localPosition.dx / widget.size.width;
    var seekPostion = widget.playerController.maxDuration * proportion;
    widget.playerController.seekTo(seekPostion.toInt());
    _currentSeekPositon = details.globalPosition.dx;
    setState(() {});
  }

  ///This initialises variable in [initState] so that everytime current duration
  ///gets updated it doesn't re assign them to same values.
  void _initialiseVariables() {
    _waveData = widget.playerController.bufferData?.toList() ?? [];
    showSeekLine = false;
    margin = widget.margin;
    padding = widget.padding;
    decoration = widget.decoration;
    backgroundColor = widget.backgroundColor;
    animationDuration = widget.animationDuration;
    animationCurve = widget.animationCurve;
    density = widget.density;
    clipBehavior = widget.clipBehavior;
    playerWaveStyle = widget.playerWaveStyle;
  }

  ///This funtion pre-calculates waveforms
  Future<void> _calculateWaveform() async {
    double totalBarsCount = widget.size.width / _dp(3);
    if (totalBarsCount <= 0.1) return;
    int samplesCount = _waveData.length * 8 ~/ 5;
    double samplesPerBar = samplesCount / totalBarsCount;
    double barCounter = 0;
    int nextBarNum = 0;
    int y =
        (widget.size.height - _dp(widget.playerWaveStyle.visualizerHeight)) ~/
            2;
    int barNum = 0;
    late int lastBarNum;
    late int drawBarCount;
    late int byte;
    for (int i = 0; i < samplesCount; i++) {
      if (i != nextBarNum) {
        continue;
      }
      drawBarCount = 0;
      lastBarNum = nextBarNum;
      while (lastBarNum == nextBarNum) {
        barCounter += samplesPerBar;
        nextBarNum = barCounter.toInt();
        drawBarCount++;
      }
      int bitPointer = i * 5;
      double byteNum = bitPointer / Constants.byteSize;
      double byteBitOffset = bitPointer - byteNum * Constants.byteSize;
      int currentByteCount = (Constants.byteSize - byteBitOffset).toInt();
      int nextByteRest = 5 - currentByteCount;
      byte = (_waveData[byteNum.toInt()] >> byteBitOffset.toInt() &
          ((2 << min(5, currentByteCount) - 1)) - 1);
      if (nextByteRest > 0) {
        byte <<= nextByteRest;
        byte |=
            _waveData[byteNum.toInt() + 1] & ((2 << (nextByteRest - 1)) - 1);
      }
      for (int j = 0; j < drawBarCount; j++) {
        int x = barNum * _dp(3);
        double top = y.toDouble() +
            _dp(widget.playerWaveStyle.visualizerHeight -
                max(1, widget.playerWaveStyle.visualizerHeight * byte / 31));
        double bottom = y.toDouble() +
            _dp(widget.playerWaveStyle.visualizerHeight).toDouble();
        if (x < widget.size.width) {
          if (x > _denseness && x + _dp(2) > _denseness) {
            _waveformXPositions.add((barNum * _dp(3)).toDouble());
            _waveformData.add(top - bottom);
          }
        }
        barNum++;
      }
    }
  }

  ///calculates values according to user provided density
  int _dp(double value) {
    if (value == 0) return 0;
    return (widget.density * value).ceil();
  }

  ///calculates densness according to width and seek progress
  void _updatePlayerPercent(Size size) {
    _audioProgress = _scrubberProgress();
    _denseness = (size.width * _audioProgress).ceilToDouble();
    if (_denseness < 0) {
      _denseness = 0;
    } else if (_denseness > size.width) {
      _denseness = size.width;
    }
  }

  ///This returns current progress of seek
  double _scrubberProgress() {
    if (widget.playerController.maxDuration == 0) return 0;
    return _seekProgress.value / widget.playerController.maxDuration;
  }
}
