import '../base/constants.dart';
import 'android_encoder_settings.dart';
import 'ios_encoder_setting.dart';

/// Class to configure audio recording settings for Android and iOS.
class RecorderSettings {
  /// Constructor for RecorderSettings.
  ///
  /// [androidEncoderSettings] - Specifies encoder settings for Android devices.
  /// [iosEncoderSettings] - Specifies encoder settings for iOS devices.
  /// [sampleRate] - Defines the sampling rate for audio recording (default: 44100 Hz).
  /// [bitRate] - Specifies the bit rate for encoding audio (optional).
  const RecorderSettings({
    this.androidEncoderSettings = const AndroidEncoderSettings(),
    this.iosEncoderSettings = const IosEncoderSetting(),
    this.sampleRate = 44100,
    this.bitRate = 128000,
  });

  /// Encoder settings for Android devices.
  final AndroidEncoderSettings androidEncoderSettings;

  /// Encoder settings for iOS devices.
  final IosEncoderSetting iosEncoderSettings;

  /// Sampling rate for audio recording in Hertz (Hz).
  /// Default is 44100 Hz.
  final int sampleRate;

  /// Bit rate for encoding audio in bits per second (bps).
  /// Higher values provide better quality but larger file sizes.
  final int bitRate;

  /// Converts the RecorderSettings instance to a JSON map for iOS.
  Map<String, dynamic> iosToJson({
    String? path,
    bool useLegacyNormalization = false,
    bool overrideAudioSession = true,
  }) =>
      {
        Constants.path: path,
        Constants.encoder: iosEncoderSettings.iosEncoder.index,
        Constants.sampleRate: sampleRate,
        Constants.bitRate: bitRate,
        Constants.useLegacyNormalization: useLegacyNormalization,
        Constants.overrideAudioSession: overrideAudioSession,
        Constants.linearPCMBitDepth: iosEncoderSettings.linearPCMBitDepth,
        Constants.linearPCMIsBigEndian: iosEncoderSettings.linearPCMIsBigEndian,
        Constants.linearPCMIsFloat: iosEncoderSettings.linearPCMIsFloat,
      };

  /// Converts the RecorderSettings instance to a JSON map for Android.
  Map<String, dynamic> androidToJson({String? path}) => {
        Constants.path: path,
        Constants.encoder: androidEncoderSettings.androidEncoder.nativeFormat,
        Constants.sampleRate: sampleRate,
        Constants.bitRate: bitRate,
      };
}
