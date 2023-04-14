## 1.0.4

- Fixed [#171](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/171) - Do not call `notifyListeners()` when disposed
- Add `UpdateFrequency` to update reporting rate of current duration. Fixes [#118](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/118) & [#145](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/145)
- Depreciated `normalizationFactor` as it is legacy normalization feature.

## 1.0.3

- Fixed [#163](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/163) - Failed to stop recording - thanks [@linchen00](https://github.com/linchen00)

## 1.0.2

- Now, calling `stopAllPlayers` is not mandatory for disposing streams and it will also not dispose controller. With last remaining player they will be disposed (Streams can be re-initialised by creating a new PlayerController).
- Added legacy normalization with this fixed [#144](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/144).
- Added `onRecorderStateChanged` stream to monitor Recorder state changes.
- Added `onCurrentDuration` stream to get latest recorded audio duration.
- Added `onRecordingEnded` stream to get recorded audio file duration. Fixes [#157](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/157).

## 1.0.1

- Added `onCompletion` stream to get event when audio is finished playing.
- Fixed [#145](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/145) - The visualization gets stuck incomplete.
- Fixed [#142](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/142) - File path with spaces doesn't show waveform
- Fixed extractor requires audio player to be initialised.
- Fixed infinite scroll in `WaveformType.long`.

## 1.0.0

- Reworked waveforms from audio file
  - **Breaking**: removed `readingComplete` PlayerState and `visualizerHeight`. With this, added `extractWaveforms` function to extract waveforms.
  - Added `WaveformType` enum for selecting longer or shorter type of waveform.
  - Added `onCurrentExtractedWaveformData` and `onExtractionProgress` to monitor progress and currently extracted waveform data.
  - improved drawing of waveforms.
  - Added function to calculate no of waveform bars which will fit in provided width and spacing.
  - Added `scrollScale` parameter to scale waves when waves are scrolled
- Fixed [#101](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/101) - Fixed setting volume for android throws error
- Fixed zero duration would cause waveforms not to expand
- Fixed `postFrameCallback` error for flutter version below 3.0.0
- **BREAKING**: Replaced `normalizationFactor` with `scaleFactor`and with this fixed [#43](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/43) 
- Updated default values for bitRate and sampleRate
- Encoders, sample rate and bit rate can now Directly be set from `record` function.
- Bitrate is now nullable and default audio extension is now `m4a`. 
- Updated example app

## 0.1.5+1

- Added missing import.

## 0.1.5

- Added bitRate feature for Android & IOS (Default to 64kbps) - thanks [@abhay-s-rawat](https://github.com/abhay-s-rawat).
- Fixed [#86](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/86) - thanks [@rlee1990](https://github.com/rlee1990)
- Updated docs and fixed docs,variable name,function names typos

## 0.1.4

- Fixed [#71](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/71) - Bump compileSdkVersion/gradle/kotlin to match flutter 3.0 - thanks [@yohom](https://github.com/yohom)
- Fixed [#74](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/74) - Fixed push back distance wouldn't reset when recording again

## 0.1.3

- Fixed [#41](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/41) & [#49](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/49) - Upgrade Package with flutter 3.0.
- Fixed [#50](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/50) & [#57](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/57) & [#65](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/65) - android build error fixed
- Fixed ios resume recording issue
- Fixed player state not getting update when playing is finished by providing PlayerState stream.
- Added current duration stream for PlayerController.
- **BREAKING**: Replaced `seekToStart` parameter from `startPlayer()` with `FinishMode` enum for
better controls when audio is finished
- **BREAKING**: Renamed `disposeFunc()` to simpler `dispose()` for both controllers
- Internal native restructure.
- Minor documentation update.

## 0.1.1

- Get current time with respect to scroll

## 0.1.0

- Added functionality to play audio file and generate waveform from it.
- **BREAKING**: Renamed WaveController to RecorderController
- Updated metering level for ios to average power
- Fixed label would not clear after stopping the recorder. With this, exposed `reset()` function to remove labels
when `callReset` flag in `stop()` is set to false.
- Updated example app

## 0.0.4

- Separated encoder input for android and ios better support

## 0.0.3+2

- Fixed gif preview

## 0.0.3+1

- Updated gif preview url

## 0.0.3

- Updated preview urls

## 0.0.2

- Updated README.md

## 0.0.1

- Initial release
