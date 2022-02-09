import 'package:flutter/material.dart';
import 'package:audio_wave/audio_wave.dart';
import 'dart:ui' as ui show Gradient;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Audio Wave',
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
  Duration updateFrequency = const Duration(milliseconds: 100);
  late final WaveController waveController;

  @override
  void initState() {
    super.initState();
    waveController = WaveController();
  }

  @override
  void dispose() {
    waveController.disposeFunc();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Audio Wave Example"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 200),
          AudioWave(
            size: Size(MediaQuery.of(context).size.width, 100.0),
            updateFrequency: updateFrequency,
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
                color: Colors.black
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: CircleAvatar(
                  backgroundColor: Colors.black,
                  child: IconButton(
                    onPressed: waveController.record,
                    color: Colors.white,
                    icon: const Icon(Icons.play_arrow),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Center(
                child: CircleAvatar(
                  backgroundColor: Colors.black,
                  child: IconButton(
                    onPressed: waveController.pause,
                    color: Colors.white,
                    icon: const Icon(Icons.pause),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Center(
                child: CircleAvatar(
                  backgroundColor: Colors.black,
                  child: IconButton(
                    onPressed: waveController.refresh,
                    color: Colors.white,
                    icon: const Icon(Icons.refresh),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
