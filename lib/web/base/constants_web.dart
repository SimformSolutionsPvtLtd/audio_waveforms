/// Web-specific constants for audio waveforms plugin
class WebConstants {
  WebConstants._();

  /// Default update frequency for duration updates in milliseconds
  static const int defaultUpdateFrequency = 200;

  /// Default timeout for loading audio in seconds
  static const int defaultLoadTimeout = 10;

  /// Default number of samples for waveform extraction
  static const int defaultNoOfSamples = 100;

  /// Audio element events
  static const String eventLoadedMetadata = 'loadedmetadata';
  static const String eventError = 'error';
  static const String eventEnded = 'ended';

  /// Audio element properties
  static const String propertyPreload = 'auto';
}
