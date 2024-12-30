import '../../audio_waveforms.dart';

/// Class to specify encoder and output format settings for Android.
class AndroidEncoderSettings {
  /// Constructor for AndroidEncoderSettings.
  ///
  /// [androidEncoder] - Defines the encoder type for Android (default: AAC).
  /// [androidOutputFormat] - Specifies the output format for Android recordings (default: MPEG4).
  const AndroidEncoderSettings({
    this.androidEncoder = AndroidEncoder.aac,
    this.androidOutputFormat = AndroidOutputFormat.mpeg4,
  });

  /// Encoder type for Android recordings.
  /// Default is AAC.
  final AndroidEncoder androidEncoder;

  /// Output format for Android recordings.
  /// Default is MPEG4.
  final AndroidOutputFormat androidOutputFormat;
}
