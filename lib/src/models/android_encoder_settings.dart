import '../../audio_waveforms.dart';

/// Class to specify encoder and output format settings for Android.
class AndroidEncoderSettings {
  /// Constructor for AndroidEncoderSettings.
  ///
  /// [androidEncoder] - Defines the encoder type for Android (default: AAC).
  /// [androidOutputFormat] - Specifies the output format for Android recordings (default: MPEG4).
  const AndroidEncoderSettings({
    this.androidEncoder = AndroidEncoder.aacLc,
  });

  /// Encoder type for Android recordings.
  /// Default is aacLc.
  final AndroidEncoder androidEncoder;
}
