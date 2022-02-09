import 'package:audio_wave/src/wave_painter.dart';
import 'package:flutter/material.dart';

class AudioWave extends StatefulWidget {
  final List<double> waveData;
  final Size size;
  final Color waveColor;
  final bool showMiddleLine;
  final double spacing;
  final bool showTop;
  final bool showBottom;
  final double scaleFactor;
  final double? bottomPadding;
  final StrokeCap waveCap;
  final Color middleLineColor;
  final double middleLineThickness;
  final double waveThickness;
  //TODO: improve logic for getting flag from user for pushBack function
  //final bool? callPushback;
  final bool extendWaveform;

  const AudioWave({
    Key? key,
    required this.waveData,
    required this.size,
    this.waveColor = Colors.blueGrey,
    this.showMiddleLine = true,
    this.spacing = 5.0,
    this.showTop = true,
    this.showBottom = true,
    this.scaleFactor = 1.0,
    this.bottomPadding,
    this.waveCap = StrokeCap.round,
    this.middleLineColor = Colors.redAccent,
    this.middleLineThickness = 3.0,
    this.waveThickness = 3.0,
    //this.callPushback,
    this.extendWaveform = false,
  })  : assert(waveThickness < spacing,
            "waveThickness can't be greater than spacing"),
        super(key: key);

  @override
  _AudioWaveState createState() => _AudioWaveState();
}

class _AudioWaveState extends State<AudioWave> {
  bool shouldCallPushBack = true;
  bool isScrolled = false;
  Offset _totalBackDistance = Offset.zero;
  Offset dragOffset = Offset.zero;
  double _initialOffsetPosition = 0.0;
  double _initialPosition = 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _handleHorizontalDragUpdate,
      onHorizontalDragStart: _handleHorizontalDragStart,
      child: CustomPaint(
        size: widget.size,
        painter: WavePainter(
          waveThickness: widget.waveThickness,
          middleLineThickness: widget.middleLineThickness,
          middleLineColor: widget.middleLineColor,
          scaleFactor: widget.scaleFactor,
          waveData: widget.waveData,
          shouldCallPushBack: /*widget.callPushback ??*/ shouldCallPushBack,
          bottomPadding: widget.bottomPadding ?? widget.size.height / 2,
          spacing: widget.spacing,
          waveCap: widget.waveCap,
          showBottom: widget.showBottom,
          showTop: widget.showTop,
          waveColor: widget.waveColor,
          showMiddleLine: widget.showMiddleLine,
          totalBackDistance: _totalBackDistance,
          dragOffset: dragOffset,
          pushBack: _pushBackWave,
          initialPosition: _initialPosition,
          extendWaveform: widget.extendWaveform,
        ),
      ),
    );
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    var direction = details.globalPosition.dx - _initialOffsetPosition;
    shouldCallPushBack = false;
    isScrolled = true;
    if (-_totalBackDistance.dx + dragOffset.dx - widget.spacing <
            widget.size.width / 2 &&
        direction > 0) {
      setState(() => dragOffset += details.delta);
    } else if (-_totalBackDistance.dx +
                dragOffset.dx +
                (widget.spacing * widget.waveData.length) -
                widget.spacing >
            widget.size.width / 2 &&
        direction < 0) {
      setState(() => dragOffset += details.delta);
    }
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    _initialOffsetPosition = details.globalPosition.dx;
  }

  void _pushBackWave() {
    if (isScrolled) {
      _initialPosition =
          widget.spacing * widget.waveData.length - widget.size.width / 2;
      isScrolled = false;
    } else {
      _initialPosition = 0.0;
      _totalBackDistance = _totalBackDistance + const Offset(5.0, 0.0);
    }
  }
}
