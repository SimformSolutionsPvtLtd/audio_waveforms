import '../../audio_waveforms.dart';

/// Class to specify encoder and output format settings for Android.
class AndroidEncoderSettings {
  /// Constructor for AndroidEncoderSettings.
  ///
  /// [androidEncoder] - Defines the encoder type for Android (default: AAC).
  /// [androidOutputFormat] - Specifies the output format for Android recordings (default: MPEG4).
  /// [stopTimeoutMs] - On some devices, the encoder can fail to naturally
  /// signal that it's finished stopping, which would otherwise hang
  /// stopRecording() forever. If stopping doesn't complete naturally within
  /// this many milliseconds, it's forced instead. Default is 500ms; raise
  /// this if you see stopRecording() forcing a stop on your target devices
  /// sooner than expected (which can slightly truncate the very end of a
  /// recording).
  const AndroidEncoderSettings({
    this.androidEncoder = AndroidEncoder.aacLc,
    this.stopTimeoutMs = 500,
  });

  /// Encoder type for Android recordings.
  /// Default is aacLc.
  final AndroidEncoder androidEncoder;

  /// Grace period, in milliseconds, to wait for the encoder to stop
  /// naturally before forcing it. See the constructor doc for details.
  final int stopTimeoutMs;
}
