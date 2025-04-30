enum WaveformExtractionType {
  /// No waveform extraction will be performed.
  noExtraction,

  /// Extract waveform data asynchronously without waiting for the result.
  extractAsync,

  /// Extract waveform data and wait until it's completed before continuing.
  extractSync,
}
