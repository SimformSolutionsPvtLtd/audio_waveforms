import 'package:audio_waveforms/src/base/player_identifier.dart';

//ignore_for_file: constant_identifier_names
extension DurationExtension on Duration {
  /// Converts duration to HH:MM:SS format
  String toHHMMSS() => toString().split('.').first.padLeft(8, "0");
}

extension IntExtension on int {
  /// Converts total seconds to MM:SS format
  String toMMSS() =>
      '${(this ~/ 60).toString().padLeft(2, '0')}:${(this % 60).toString().padLeft(2, '0')}';
}

/// State of recorder
enum RecorderState { initialized, recording, paused, stopped }

/// Android encoders.
///
/// Android and IOS are have been separated to better support
/// platform wise encoder and output formats.
///
/// Check https://developer.android.com/reference/android/media/MediaRecorder.AudioEncoder
/// for more info.
enum AndroidEncoder {
  /// Default
  aac,
  aac_eld,
  he_aac,
  amr_nb,
  amr_wb,

  /// This encoder requires android Q.
  /// For android < Q, aac will be used
  opus,

  /// requires android Lollipop.
  /// For android < Lollipop, aac will be used
  vorbis
}

/// Android output format.
///
/// Android and IOS are have been separated to better support
/// platform wise encoder and output formats.
///
/// Check https://developer.android.com/reference/android/media/MediaRecorder.OutputFormat
/// for more info.
enum AndroidOutputFormat {
  /// Default
  mpeg4,
  three_gpp,

  /// This Output format requires android Q.
  /// For android < Q, mpeg4 will be used
  ogg,
  amr_wb,
  amr_nb,

  /// This Output format requires android Q.
  /// For android < Q, mpeg4 will be used
  webm,

  /// This Output format requires android O.
  /// For android < O, mpeg4 will be used
  mpeg_2_ts,
  aac_adts,
}

/// IOS encoders.
///
/// Android and IOS are have been separated to better support
/// platform wise encoder and output formats.
///
/// Check https://developer.apple.com/documentation/coreaudiotypes/1572096-audio_format_identifiers
/// for more info.
enum IosEncoder {
  /// Default
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

/// States of audio player
enum PlayerState {
  /// When reading of an audio file is completed
  readingComplete,

  /// When player is [initialised]
  initialized,

  /// When player is playing the audio file
  playing,

  /// When player is paused.
  paused,

  /// when player is stopped. Default state of any player ([uninitialised]).
  stopped
}

/// There are two type duration which we can get while playing an audio.
///
/// 1. max -: Max duration is [full] duration of audio file
///
/// 2. current -: Current duration is how much audio has been played
enum DurationType {
  current,

  /// Default
  max
}

/// This extension filter playerKey from the stream and provides
/// only necessary generic type.
extension FilterForPlayer<T> on Stream<PlayerIdentifier<T>> {
  Stream<T> filter(String playerKey) {
    return where((identifier) => identifier.playerKey == playerKey)
        .map((identifier) => identifier.type);
  }
}

/// An enum to be used to change behaviour of player when audio
/// is finished playing.
enum FinishMode {
  ///Loops the audio.
  loop,

  ///Pause the audio, playing again will start from [0] milliseconds.
  pause,

  ///Stops player and disposes it(a PlayerController won't be disposed).
  stop
}
