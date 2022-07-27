## [0.1.3] - 26 July, 2022

- Fixed [#41](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/41) & [#49](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/49) - Upgrade Package with flutter 3.0.
- Fixed [#50](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/50) & [#57](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/57) & [#65](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/65) - android build error fixed


## [0.1.2] - 11 May, 2022

* Fixed ios resume recording issue
* Fixed player state not getting update when playing is finished by providing PlayerState stream.
* Added current duration stream for PlayerController.
* Breaking: Replaced `seekToStart` parameter from `startPlayer()` with `FinishMode` enum for
better controls when audio is finished
* Breaking: Renamed `disposeFunc()` to simpler `dispose()` for both controllers
* Internal native restructure.
* Minor documentation update

## [0.1.1] - 28 April, 2022

* Get current time with respect to scroll

## [0.1.0] - 26 April, 2022

* Added functionality to play audio file and generate waveform from it.
* Breaking: Renamed WaveController to RecorderController
* Updated metering level for ios to average power
* Fixed label would not clear after stopping the recorder. With this, exposed `reset()` function to remove labels
when `callReset` flag in `stop()` is set to false.
* Updated example app

## [0.0.4] - 11 April, 2022

* Separated encoder input for android and ios better support

## [0.0.3+2] - 23 March, 2022

* Fixed gif preview

## [0.0.3+1] - 22 March, 2022

* Updated gif preview url

## [0.0.3] - 22 March, 2022

* Updated preview urls

## [0.0.2] - 22 March, 2022

* Updated README.md

## [0.0.1] - 22 March, 2022

* Initial release
