import '../../audio_waveforms.dart';

/// Class to specify encoder and output format settings for Android.
class AndroidEncoderSettings {
  /// Constructor for AndroidEncoderSettings.
  ///
  /// [androidEncoder] - Defines the encoder type for Android (default: AAC).
  /// [audioSource] - Input source used for capture (default: [AndroidAudioSource.mic]).
  /// [useNoiseSuppressor] - Enable noise suppression when supported (default: false).
  /// [useEchoCanceler] - Enable acoustic echo cancellation when supported (default: false).
  /// [useAutoGainControl] - Enable automatic gain control when supported (default: false).
  const AndroidEncoderSettings({
    this.androidEncoder = AndroidEncoder.aacLc,
    this.audioSource = AndroidAudioSource.mic,
    this.useNoiseSuppressor = false,
    this.useEchoCanceler = false,
    this.useAutoGainControl = false,
  });

  /// Encoder type for Android recordings.
  /// Default is aacLc.
  final AndroidEncoder androidEncoder;

  /// Audio input source used for capture.
  ///
  /// Defaults to [AndroidAudioSource.mic] (raw microphone). For voice apps
  /// that want device-level noise suppression and echo cancellation,
  /// [AndroidAudioSource.voiceCommunication] is usually the best choice.
  final AndroidAudioSource audioSource;

  /// Attaches an `android.media.audiofx.NoiseSuppressor` to the recording
  /// session when the device supports it. Default is false.
  final bool useNoiseSuppressor;

  /// Attaches an `android.media.audiofx.AcousticEchoCanceler` to the recording
  /// session when the device supports it. Default is false.
  ///
  /// Echo cancellation is most effective with
  /// [AndroidAudioSource.voiceCommunication].
  final bool useEchoCanceler;

  /// Attaches an `android.media.audiofx.AutomaticGainControl` to the recording
  /// session when the device supports it. Default is false.
  ///
  /// Note: gain control alters the captured amplitude and therefore the
  /// rendered waveform. Avoid for music or level-sensitive recording.
  final bool useAutoGainControl;
}
