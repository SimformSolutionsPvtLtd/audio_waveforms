class Constants {
  Constants._();

  static const String methodChannelName =
      'simform_audio_waveforms_plugin/methods';
  static const String initRecorder = 'initRecorder';
  static const String startRecording = 'startRecording';
  static const String stopRecording = 'stopRecording';
  static const String pauseRecording = 'pauseRecording';
  static const String resumeRecording = 'resumeRecording';
  static const String getDecibel = 'getDecibel';
  static const String checkPermission = 'checkPermission';
  static const String path = 'path';
  static const String encoder = 'encoder';
  static const String outputFormat = 'outputFormat';
  static const String sampleRate = 'sampleRate';
  static const String bitRate = 'bitRate';
  static const String readAudioFile = 'readAudioFile';
  static const String convertToBytes = 'convertToBytes';
  static const String preparePlayer = "preparePlayer";
  static const String startPlayer = "startPlayer";
  static const String stopPlayer = "stopPlayer";
  static const String releasePlayer = "releasePlayer";
  static const String pausePlayer = "pausePlayer";
  static const String seekTo = "seekTo";
  static const String progress = "progress";
  static const String setVolume = "setVolume";
  static const String volume = "volume";
  static const String finishMode = "finishMode";
  static const String finishType = "finishType";
  static const String setRate = "setRate";
  static const String rate = "rate";
  static const String rightVolume = "rightVolume";
  static const String getDuration = "getDuration";
  static const String durationType = "durationType";
  static const String seekToStart = "seekToStart";
  static const String durationEventChannel = "durationEventChannel";
  static const String playerKey = "playerKey";
  static const String current = "current";
  static const String onCurrentDuration = "onCurrentDuration";
  static const String stopAllPlayers = "stopAllPlayers";
  static const String pauseAllPlayers = "pauseAllPlayers";
  static const String onDidFinishPlayingAudio = "onDidFinishPlayingAudio";
  static const String extractWaveformData = "extractWaveformData";
  static const String noOfSamples = "noOfSamples";
  static const String waveformData = "waveformData";
  static const String onCurrentExtractedWaveformData =
      "onCurrentExtractedWaveformData";
  static const String stopExtraction = "stopExtraction";
  static const String updateFrequency = "updateFrequency";
  static const String overrideAudioSession = "overrideAudioSession";
  static const String resultFilePath = "resultFilePath";
  static const String resultDuration = "resultDuration";
  static const String linearPCMBitDepth = 'linearPCMBitDepth';
  static const String linearPCMIsBigEndian = 'linearPCMIsBigEndian';
  static const String linearPCMIsFloat = 'linearPCMIsFloat';
  static const String onAudioChunk = 'onAudioChunk';
  static const String normalisedRms = 'normalisedRms';
  static const String bytes = 'bytes';
  static const String recordedDuration = 'recordedDuration';

  // Error codes
  static const String audioWaveforms = 'audio_waveforms';
  static const String unsupported = 'UNSUPPORTED';
  static const String unimplemented = 'Unimplemented';

  // Error messages
  static const String cannotPreparePlayer = 'Cannot prepare player';
  static const String cannotStartPlayer = 'Cannot start player';
  static const String cannotPausePlayer = 'Cannot pause player';
  static const String cannotStopPlayer = 'Cannot stop player';
  static const String cannotReleasePlayer = 'Cannot release player';
  static const String cannotGetDuration = 'Cannot get duration';
  static const String cannotSeekToPosition = 'Cannot seek to position';
  static const String cannotSetVolume = 'Cannot set volume';
  static const String cannotSetRate = 'Cannot set rate';
  static const String cannotSetFinishMode = 'Cannot set finish mode';
  static const String playerKeyIsNull = 'Player key is null';
  static const String playerKeyOrDurationTypeIsNull =
      'Player key or duration type is null';
  static const String playerKeyOrProgressIsNull =
      'Player key or progress is null';
  static const String playerKeyOrVolumeIsNull = 'Player key or volume is null';
  static const String playerKeyOrRateIsNull = 'Player key or rate is null';
  static const String recordingNotSupportedOnWeb =
      'Audio recording is not supported on web platform';
  static const String methodNotAvailableForWeb =
      'is not available for web. Recording functionality is only available on mobile platforms (iOS/Android).';
  static const String methodNotImplementedOnWeb =
      'is not implemented on web platform';
  static const String audioWaveformsDoesNotImplement =
      'audio_waveforms for web doesn\'t implement';
}
