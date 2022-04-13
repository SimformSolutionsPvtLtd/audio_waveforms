import 'package:audio_waveforms/src/base/player_wave_style.dart';
import 'package:audio_waveforms/src/painters/player_wave_painter.dart';
import 'package:flutter/material.dart';
import '../audio_waveforms.dart';

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
  ///When you play the audio file, another waveforms will drawn on top of it show
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
    this.animationCurve = Curves.bounceOut,
    this.density = 2,
    this.clipBehavior = Clip.none,
  }) : super(key: key);

  @override
  State<AudioFileWaveforms> createState() => _AudioFileWaveformsState();
}

class _AudioFileWaveformsState extends State<AudioFileWaveforms>
    with SingleTickerProviderStateMixin {
  int _currentDuration = 0;

  late AnimationController animationController;
  late Animation<double> animation;
  double _progress = 0.0;

  //TODO: update this in PR
  bool showSeekLine = false;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    animation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: animationController, curve: widget.animationCurve))
      ..addListener(() {
        setState(() {
          _progress = animation.value;
        });
      });
    widget.playerController.addListener(() {
      if (widget.playerController.playerState == PlayerState.playing) {
        animationController.forward();
        if (!widget.playerController.durationStreamController.hasListener) {
          widget.playerController.durationStreamController.stream
              .listen((event) {
            _currentDuration = event;
            showSeekLine = widget.playerWaveStyle.showSeeker;
            if (mounted) setState(() {});
          });
        }
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    animation.removeListener(() {});
    animationController.dispose();
    widget.playerController.removeListener(() {});
    super.dispose();
  }

  final double _multiplier = 1.0;
  double _currentSeekPositon = 0.0;

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
          child: CustomPaint(
            isComplex: true,
            painter: FileWaveformsPainter(
              waveData: widget.playerController.bufferData!.toList(),
              multiplier: _multiplier,
              density: widget.density,
              maxDuration: widget.playerController.maxDuration,
              currentDuration: _currentDuration,
              animValue: _progress,
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
              staleWaveGradient: widget.playerWaveStyle.staleWavegradient,
              waveCap: widget.playerWaveStyle.waveCap,
              waveColor: widget.playerWaveStyle.waveColor,
              liveWaveColor: widget.playerWaveStyle.liveWaveColor,
            ),
            size: widget.size,
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
}
