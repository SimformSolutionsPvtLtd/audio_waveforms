import '../base/utils.dart';

/// Class to configure encoder settings for iOS recordings.
class IosEncoderSetting {
  /// Constructor for IosEncoderSetting.
  ///
  /// [iosEncoder] - Defines the encoder type for iOS (default: MPEG4 AAC).
  /// [linearPCMBitDepth] - Specifies the bit depth per sample (optional).
  /// [linearPCMIsBigEndian] - Specifies byte order for PCM format (optional).
  /// [linearPCMIsFloat] - Determines if PCM format uses floating-point samples (optional).
  const IosEncoderSetting({
    this.iosEncoder = IosEncoder.kAudioFormatMPEG4AAC,
    this.linearPCMBitDepth,
    this.linearPCMIsBigEndian,
    this.linearPCMIsFloat,
  });

  /// Encoder type for iOS recordings.
  /// Default is MPEG4 AAC.
  final IosEncoder iosEncoder;

  /// Specifies the bit depth per sample.
  ///
  /// Higher values (e.g., 24 or 32) improve audio quality but increase file size.
  /// Supported values: 8, 16, 24, 32.
  /// Default value 16 bits.
  final int? linearPCMBitDepth;

  /// Specifies the byte order:
  ///   false: Little-endian (least significant byte first).
  ///   true: Big-endian (most significant byte first).
  /// Default value false.
  final bool? linearPCMIsBigEndian;

  /// Determines whether audio samples are stored as floating-point values:
  ///   false: Integer format.
  ///   true: Floating-point format, often used in scientific or high-precision audio processing.
  /// Default value false.
  final bool? linearPCMIsFloat;
}
