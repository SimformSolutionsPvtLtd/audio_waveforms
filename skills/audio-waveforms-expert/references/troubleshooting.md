# Troubleshooting and known limitations

Rule numbers refer to `SKILL.md`. Issue and PR numbers describe the state when this package version shipped. Check the linked issue before telling a user a bug is still present.

## Known limitations and workarounds

Replay, recycled lists, remote audio, assets and the recorder-plus-bubbles freeze are covered by rules 2 and 4 to 6 in `SKILL.md`.

| Need | What happens | Workaround |
| --- | --- | --- |
| Bars clipped or tiny | Half-height = value × `scaleFactor` (player default 100) | `scaleFactor` ≈ height / 2 |
| Playable file while paused (#208) | Not possible | `stop()`, then record a new file |
| Live duration on Android (#476) | `onCurrentDuration`/`elapsedDuration` and duration labels run at 2× the real time | Halve it on Android, or use `recordedDuration` after stop |
| Stop while paused on iOS | The next recording gets no waves, chunks or duration until you pause it, and then gets them only while paused | Call `record()` to resume, then `stop()` |
| Live duration on macOS | `onCurrentDuration` never emits, `elapsedDuration` stays zero and duration labels never appear | Run your own timer; use `recordedDuration` after stop |
| Android `stop()` sometimes never returns (#470, #516) | File may be corrupt | `.timeout(...)` and show an error |
| Cross-OS playback of recordings (#113, #198) | Can fail | AAC `.m4a`; test both directions |
| Remote / HLS audio (#54, #443) | Not supported | Download to a file first |
| Web, Windows, Linux | `MissingPluginException` | Not supported |

## Symptom → fix

| Symptom / error | Fix |
| --- | --- |
| `waveThickness can't be greater than spacing` | `spacing` > `waveThickness` (defaults: recorder 8/3, player 5/3) |
| `Cannot provide both noOfSamples and noOfSamplesPerSecond` | Pass only one |
| `Cannot provide both a color and a decoration` (`AudioWaveforms`) | Put the colour in `decoration` and drop `backgroundColor` |
| `LateInitializationError: Field '_extractionProgressController…'` (or `_extractedWaveformDataController`) | Create a `PlayerController` first, or use `player.waveformExtraction` |
| `Cannot set the method call handler before the binary messenger has been initialized` | Create controllers after `runApp`; in tests call `TestWidgetsFlutterBinding.ensureInitialized()` |
| `PlatformException(AudioWaveforms, Failed to prepare player, …2003334207…)` | The path is not a readable local file (asset, URL, `#`/`?` in name) or the format is unsupported. Android reports the same cause as `PlatformException(AudioWaveforms, <ExoPlayer message>, Unable to load media source.)` |
| `Failed to start recording` / `Failed to initialize recorder` (Android: `Error initializing encoder: …`, `Error initializing AudioRecord: …`, `Invalid buffer size`) | Directory missing, or extension/encoder/sampleRate mismatch; Android `opus` needs Android 10 (a denied permission returns silently instead, rule 7) |
| `setFinishMode`/`getDuration` never completes | Called before `preparePlayer` or after `stopAllPlayers()` (on Android `preparePlayer` then hangs too) |
| Play does nothing the second time | Rule 2 |
| `AudioFileWaveforms` shows no bars | Rules 3–4 |
| Recorder waves froze | Rule 5 |
| No waves on iOS | `overrideAudioSession = false` without your own `.playAndRecord` session |
| `seekTo` ignored | Player stopped, or Android below 8.0 |
| `MissingPluginException` | Unsupported platform, or a test without the channel mock |
