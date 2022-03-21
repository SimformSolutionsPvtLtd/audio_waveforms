import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'dart:ui' as ui show Gradient;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Audio Waveforms',
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final WaveController waveController;

  @override
  void initState() {
    super.initState();
    waveController = WaveController()
      ..encoder = Encoder.aac
      ..sampleRate = 16000;
  }

  @override
  void dispose() {
    waveController.disposeFunc();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF394253),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AudioWaveforms(
            enableGesture: true,
            size: Size(MediaQuery.of(context).size.width, 100.0),
            waveController: waveController,
            margin: const EdgeInsets.all(20.0),
            waveStyle: WaveStyle(
              waveColor: Colors.white,
              middleLineColor: Colors.white,
              durationLinesColor: Colors.white,
              durationLinesHeight: 8.0,
              extendWaveform: true,
              showMiddleLine: false,
              labelSpacing: 8.0,
              durationStyle: const TextStyle(
                color: Colors.white,
                fontSize: 18.0,
              ),
              gradient: ui.Gradient.linear(
                const Offset(70, 50),
                Offset(MediaQuery.of(context).size.width / 2, 0),
                [Colors.red, Colors.green],
              ),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.0),
              gradient: const LinearGradient(
                colors: <Color>[
                  Color(0xFF615766),
                  Color(0xFF394253),
                  Color(0xFF412B4F),
                ],
                begin: Alignment.bottomLeft,
                stops: <double>[0.2, 0.45, 0.8],
              ),
            ),
          ),
          const SizedBox(height: 40),
          Container(
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xff2D3548), Color(0xff151922)],
                    stops: [0.1, 0.45],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter),
                borderRadius: BorderRadius.circular(12.0)),
            padding: const EdgeInsets.all(12.0),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Center(
                  child: CircleAvatar(
                    backgroundColor: Colors.black45,
                    child: IconButton(
                      onPressed: waveController.record,
                      color: Colors.white,
                      icon: const Icon(Icons.mic),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Center(
                  child: CircleAvatar(
                    backgroundColor: Colors.black45,
                    child: IconButton(
                      onPressed: waveController.pause,
                      color: Colors.white,
                      icon: const Icon(Icons.pause),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Center(
                  child: CircleAvatar(
                    backgroundColor: Colors.black45,
                    child: IconButton(
                      onPressed: waveController.stop,
                      color: Colors.white,
                      icon: const Icon(Icons.stop),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Center(
                  child: CircleAvatar(
                    backgroundColor: Colors.black45,
                    child: IconButton(
                      onPressed: waveController.refresh,
                      color: Colors.white,
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          )
        ],
      ),
    );
  }
}
