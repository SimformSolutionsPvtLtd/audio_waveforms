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
  her_aac,
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

  ///This Output format requires android Q.
  ///For android < Q, mpeg4 will be used
  webm,

  ///This Output format requires android O.
  ///For android < O, mpeg4 will be used
  mpeg_2_ts,
  aac_adts,
  amr_wb,
  amr_nb,
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
