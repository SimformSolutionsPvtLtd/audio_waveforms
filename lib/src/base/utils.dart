import 'package:audio_waveforms/src/base/player_indentifier.dart';

extension DurationExtension on Duration {
  ///converts duration to HH:MM:SS format
  String toHHMMSS() => toString().split('.').first.padLeft(8, "0");
}

extension IntExtension on int {
  ///converts total seconds to MM:SS format
  String toMMSS() =>
      '${(this ~/ 60).toString().padLeft(2, '0')}:${(this % 60).toString().padLeft(2, '0')}';
}

///state of recorer
enum RecorderState { initialized, recording, paused, stopped }

///Android encoders.
///
///Android and IOS are have been separated for better support
///encoder and output formats
enum AndroidEncoder {
  ///Default
  aac,
  aac_eld,
  he_aac,
  amr_nb,
  amr_wb,

  ///This encoder requires android Q.
  ///For android < Q, aac will be used
  opus,

  ///requires android Lollipop or ios 11.
  ///For android < Lollipop, aac will be used
  vorbis
}

///Android output format.
///
///Android and IOS are have been separated for better support
///encoder and output formats
enum AndroidOutputFormat {
  ///Default
  mpeg4,
  three_gpp,

  ///This Output format requires android Q.
  ///For android < Q, mpeg4 will be used
  ogg,
  amr_wb,
  amr_nb,

  ///This Output format requires android Q.
  ///For android < Q, mpeg4 will be used
  webm,

  ///This Output format requires android O.
  ///For android < O, mpeg4 will be used
  mpeg_2_ts,
  aac_adts,
}

///IOS encoders.
///
///Android and IOS are have been separated for better support
///encoder and output formats
enum IosEncoder {
  ///Default
  kAudioFormatMPEG4AAC,
  kAudioFormatMPEGLayer1,
  kAudioFormatMPEGLayer2,
  kAudioFormatMPEGLayer3,
  kAudioFormatMPEG4AAC_ELD,
  kAudioFormatMPEG4AAC_HE,
  kAudioFormatOpus,
  kAudioFormatAMR,
  kAudioFormatAMR_WB,
  kAudioFormatLinearPCM,
  kAudioFormatAppleLossless,
  kAudioFormatMPEG4AAC_HE_V2
}

///States of audio player
enum PlayerState {
  ///When reading of audio file is completed
  readingComplete,

  ///When player is [initialised]
  initialized,

  ///When player is playing the audio file
  playing,

  ///When player is paused.
  paused,

  ///when player is stopped. Default state of any player ([uninitialised]).
  stopped
}

///There are two type duration which we can get.
///
/// 1. Max duration is [full] duration of audio file
///
/// 2. Current duration is how much audio has been played
enum DurationType {
  current,

  ///Default
  max
}

///This extention filter playerKey from the stream and provides
///only necessary generic type.
extension FilterForPlayer<T> on Stream<PlayerIdentifier<T>> {
  Stream<T> filter(String playerKey) {
    return where((identifier) => identifier.playerKey == playerKey)
        .map((identifier) => identifier.type);
  }
}

///This enum is used to change behaviour of player
///when audio is finished playing.
enum FinishMode {
  ///Loops the audio.
  loop,

  ///Pause the audio, playing again will start from [0] milliseconds.
  pause,

  ///Stops player and disposes it(a PlayerController won't be disposed).
  stop
}
