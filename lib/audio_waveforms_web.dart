import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'web/audio_waveforms_plugin_web.dart';

/// Entry point for web platform
/// Delegates to AudioWaveformsPluginWeb for actual implementation
class AudioWaveformsPlugin {
  /// Registers this class as the web plugin implementation
  static void registerWith(Registrar registrar) {
    AudioWaveformsPluginWeb.registerWith(registrar);
  }
}
