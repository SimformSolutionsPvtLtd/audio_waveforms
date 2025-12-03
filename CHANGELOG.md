## 2.0.1

- Fixed [#452](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/452) - OnAmplitude continues to add data points when recording is paused on iOS
- Fixed [#453](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/453) - Recording with wav format never returns result
- Fixed [#433](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/433) - `extractWaveformData` doesn't return result on iOS
- Fixed [#455](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/pull/455) - On android resuming audio recording returns false instead of true - thanks [@yuanhoujun](https://github.com/yuanhoujun)

## 2.0.0

- Fixed [#350](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/350) - Left most visible wave is clipped in half when recording.
- Fixed [#397](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/397) - iOS crashes at `extractWaveform` instead provide error log
- Fixed [#390](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/390) - Setting continuousWaveform to false not working
- Feature [#415](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/pull/415) - Add stop extraction method and asynchronous extraction of waveform in ios
- Feature [#204](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/204) - Move play head position with waveform gesture `onTapDown`.
- Chore [#375](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/375) - Don't send error if already sent
- Chore [#376](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/376) - Preemptively account for invalid input buffer
- **BREAKING:** Fixed [#412](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/412) - Calling preparePlayer again does not cancel old waveform extraction.
- **BREAKING:** Feature [#416](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/pull/416) - Add waveform extraction controller.
- **BREAKING:** Rename `tapUpUpdateDetails` to `onTapUp`.
- **BREAKING:**
  - Remove duplicate parameters from RecorderController.
  - Add `RecorderSettings` model for all the recording settings.

## 1.3.0

- Fixed [#386](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/pull/386) - On permission denied isRecording flag changed
- Feat [#384](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/384) - Provide a callback of drag,tap,start and end details on user gesture
- Feat [#309](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/309) - Added support for Liner PCM codec in iOS
- Fixed [#291](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/291) - Codec issue while recording audio on android
- Fixed [#391](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/pull/391) - Wrong codec selection on the platform side on Android
- Fixed [#389](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/pull/389) - Wrong codec selection on the platform side on iOS
- Feat [#325](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/325) - Added feature to pause all player controller at once.
- Fixed [#373](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/373) - Getting error on dispose
- Fixed [#395](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/395) - Live wave gradient not getting applied

## 1.2.0

- Fixed [#350](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/350) - Waveform clipping at starting position
- Chore [#304](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/304) - Improved Documentation.
- Fixed [#349](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/349) - iOS audio plays without sound
- Fixed [#364](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/pull/364) - seekTo position issue where onDrag of waveform at initial position first wave outside the seekLine. 
- Fixed [#301](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/301) - Cannot catch error of preparePlayer
- Fixes [#228](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/228) - Added feature to setReleaseMode for player controller. 

## 1.1.1

- Downgrade flutter_lint version to support flutter version 3.10.x

## 1.1.0

- Update flutter and dart version
- Fixed [#256](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/256) - Default audio session config causing expected behavior for IOS.
- Fixed [#303](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/303) - All player has same instances -  thanks [@AlexV525](https://github.com/AlexV525)
- Fixed incorrect import for shortHash - thanks [@mattbajorek](https://github.com/mattbajorek)
- Fixed Auto start permission on iOS by waiting for response after user confirms or denies - thanks [@mattbajorek](https://github.com/mattbajorek)
- Fixed Dispose of instance if all playerKeys are removed - thanks [@mattbajorek](https://github.com/mattbajorek)

## 1.0.5

- Updated gradle file
- Fixed [#232](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/232) - Last wave flickering 
- Fixed [#252](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/252) - Android recording doesn't work the first time after granting permissions
- Fixed [#230](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/230) - Stop player should not be freed the resources
- Fixed [#165](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/165) - IOS recorder without path not working
- Fixed [#232](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/232) - Unnecessary rendering
- Added ability to change audio speed - thanks [@Zubii12](https://github.com/Zubii12) 
- Fixed stopping a recording immediately after starting it throws multiple exceptions on Android - thanks [@mschudt](https://github.com/mschudt) 
- Fixed waveform for audios under 1 second not being extractable on Android - thanks [@mschudt](https://github.com/mschudt) 
- Minor update to docs 

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
