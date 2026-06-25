import 'dart:io';

import 'player_identifier.dart';

//ignore_for_file: constant_identifier_names
extension DurationExtension on Duration {
  /// Converts duration to HH:MM:SS format
  String toHHMMSS() => toString().split('.').first.padLeft(8, "0");
}

extension IntExtension on int {
  /// Converts total seconds to MM:SS format
  String toMMSS() =>
      '${(this ~/ 60).toString().padLeft(2, '0')}:${(this % 60).toString().padLeft(2, '0')}';
}

/// State of recorder
enum RecorderState { initialized, recording, paused, stopped }

/// Android encoders.
///
/// Android and IOS are have been separated to better support
/// platform wise encoder and output formats.
///
/// Check [MediaRecorder.AudioEncoder](https://developer.android.com/reference/android/media/MediaRecorder.AudioEncoder)
/// for more info.
enum AndroidEncoder {
  wav,
  aacLc,
  aacHe,
  aacEld,
  amrNb,
  amrWb,
  opus;

  String toNativeFormat() {
    return switch (this) {
      AndroidEncoder.wav => 'WAV',
      AndroidEncoder.aacLc => 'AAC_LC',
      AndroidEncoder.aacHe => 'AAC_HE',
      AndroidEncoder.aacEld => 'AAC_ELD',
      AndroidEncoder.amrNb => 'AMR_NB',
      AndroidEncoder.amrWb => 'AMR_WB',
      AndroidEncoder.opus => 'OPUS',
    };
  }
}

/// IOS encoders.
///
/// Android and IOS are have been separated to better support
/// platform wise encoder and output formats.
///
/// Check [Audio Format Identifiers](https://developer.apple.com/documentation/coreaudiotypes/1572096-audio_format_identifiers)
/// for more info.
enum IosEncoder {
  /// Default
  kAudioFormatMPEG4AAC,
  kAudioFormatMPEGLayer1,
  kAudioFormatMPEGLayer2,
  kAudioFormatMPEGLayer3,
  kAudioFormatMPEG4AAC_ELD,
  kAudioFormatMPEG4AAC_HE,
  kAudioFormatOpus,
  kAudioFormatAMR,
  kAudioFormatAMR_WB,
  kAudioFormatLinearPCM,
  kAudioFormatAppleLossless,
  kAudioFormatMPEG4AAC_HE_V2
}

/// States of audio player
enum PlayerState {
  /// When player is [initialised]
  initialized,

  /// When player is playing the audio file
  playing,

  /// When player is paused.
  paused,

  /// when player is stopped. Default state of any player ([uninitialised]).
  stopped
}

/// There are two type duration which we can get while playing an audio.
///
/// 1. max -: Max duration is [full] duration of audio file
///
/// 2. current -: Current duration is how much audio has been played
enum DurationType {
  current,

  /// Default
  max
}

/// This extension filter playerKey from the stream and provides
/// only necessary generic type.
extension FilterForPlayer<T> on Stream<PlayerIdentifier<T>> {
  Stream<T> filter(String playerKey) {
    return where((identifier) => identifier.playerKey == playerKey)
        .map((identifier) => identifier.type);
  }
}

/// An enum to be used to change behaviour of player when audio
/// is finished playing.
enum FinishMode {
  ///Keeps the buffered data and plays again after completion, creating a loop.
  loop,

  ///Stop audio playback but keep all resources intact.
  ///Use this if you intend to play again later.
  pause,

  ///Stops player and disposes it(a PlayerController won't be disposed).
  stop,
}

/// An enum to decide which type of waveform to show.
enum WaveformType {
  /// Fits Waveform in provided width. Audio can be seeked with
  /// tap and drag gesture.
  ///
  /// **Important**-: Make sure to provide number of sample according to
  /// the width using `getSamplesForWidth` function from PlayerWaveStyle
  /// otherwise full waveform may get cut off.
  fitWidth,

  /// This waveform starts from middle. When audio progresses waveform is
  /// pushed back and a middle line shows current progress.
  ///
  /// This waveform only allows seek with drag.
  long
}

extension WaveformTypeExtension on WaveformType {
  /// Check WaveformType is equals to fitWidth or not.
  bool get isFitWidth => this == WaveformType.fitWidth;

  /// Check WaveformType is equals to long or not.
  bool get isLong => this == WaveformType.long;
}

extension PlayerStateExtension on PlayerState {
  bool get isPlaying => this == PlayerState.playing;

  bool get isStopped => this == PlayerState.stopped;

  bool get isInitialised => this == PlayerState.initialized;

  bool get isPaused => this == PlayerState.paused;
}

extension RecorderStateExtension on RecorderState {
  bool get isRecording => this == RecorderState.recording;

  bool get isInitialized => this == RecorderState.initialized;

  bool get isPaused => this == RecorderState.paused;

  bool get isStopped => this == RecorderState.stopped;
}

/// Rate of updating the reported current duration.
enum UpdateFrequency {
  /// Reports duration at every 50 milliseconds.
  high(50),

  /// Reports duration at every 100 milliseconds.
  medium(100),

  /// Reports duration at every 200 milliseconds.
  low(200);

  const UpdateFrequency(this.value);

  final int value;
}

/// An enum to decide waveform rendering mode.
enum WaveformRenderMode {
  /// Normal mode where waveform starts from left to right.
  ///
  /// The waveform will render from left to right. Once rendered waveforms
  /// reaches the end of the available width, it will start pushing the
  /// previous waves to left to make space for new waves.
  ltr,

  /// RTL mode where waveform starts from right to left.
  ///
  /// The waveform will render from right to left. Older waves will be pushed
  /// to the left to make space for new waves.
  rtl;

  /// Check WaveformRenderMode is equals to ltr or not.
  bool get isLtr => this == WaveformRenderMode.ltr;

  /// Check WaveformRenderMode is equals to rtl or not.
  bool get isRtl => this == WaveformRenderMode.rtl;
}

/// Checks if the current platform is iOS or macOS.
bool get isIosOrMacOS => Platform.isIOS || Platform.isMacOS;

/// Sniffs an audio file's container from its leading magic bytes and returns
/// the file extension AVFoundation needs to pick the right parser, or `null`
/// when the container isn't recognised.
Future<String?> sniffAudioExtension(String path) async {
  RandomAccessFile? raf;
  try {
    raf = await File(path).open();
    final b = await raf.read(12);
    if (b.length < 4) return null;
    String ascii(int start, int end) =>
        end <= b.length ? String.fromCharCodes(b.sublist(start, end)) : '';
    // MP4 / M4A container: bytes 4..8 == "ftyp" (covers AAC-in-MP4).
    if (ascii(4, 8) == 'ftyp') return 'm4a';
    if (ascii(0, 4) == 'RIFF' && ascii(8, 12) == 'WAVE') return 'wav';
    if (ascii(0, 4) == 'fLaC') return 'flac';
    if (ascii(0, 4) == 'OggS') return 'ogg';
    if (ascii(0, 3) == 'ID3') return 'mp3';
    // Raw frame sync: 0xFFFx = ADTS AAC, 0xFFEx = MP3.
    if (b[0] == 0xFF) {
      if ((b[1] & 0xF6) == 0xF0) return 'aac';
      if ((b[1] & 0xE0) == 0xE0) return 'mp3';
    }
    return null;
  } catch (_) {
    return null;
  } finally {
    await raf?.close();
  }
}

/// On iOS/macOS, AVFoundation routes strictly by file extension. Android can
/// record AAC-in-MP4 yet name the file `.mp3`/`.aac` (issue #113), which then
/// fails to load or silently mis-parses (e.g. an 8ms bogus duration). When the
/// extension disagrees with the container sniffed from magic bytes, this returns
/// a temp symlink carrying the correct extension so the right parser is chosen;
/// otherwise it returns [path] unchanged. No-op on other platforms.
Future<String> normalizedAudioPath(String path) async {
  if (!isIosOrMacOS) return path;
  final ext = await sniffAudioExtension(path);
  if (ext == null) return path;
  final dot = path.lastIndexOf('.');
  final currentExt = dot == -1 ? '' : path.substring(dot + 1).toLowerCase();
  if (currentExt == ext) return path;
  try {
    final link =
        Link('${Directory.systemTemp.path}/awf_sniff_${path.hashCode}.$ext');
    final type = await FileSystemEntity.type(link.path);
    if (type == FileSystemEntityType.link) {
      // Reuse only when it already targets this exact file; otherwise the
      // name collided with another path, so re-point it.
      if (await link.target() == path) return link.path;
      await link.delete();
    } else if (type != FileSystemEntityType.notFound) {
      // A stale regular file/dir is squatting on the name; clear it so the
      // link can be created instead of silently disabling the fix.
      await File(link.path).delete();
    }
    await link.create(path);
    return link.path;
  } catch (_) {
    return path;
  }
}
