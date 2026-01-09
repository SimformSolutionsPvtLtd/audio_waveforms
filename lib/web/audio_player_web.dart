import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart';

import '../src/base/constants.dart';
import 'base/constants_web.dart';
import 'base/utils_web.dart';

/// Web implementation for audio player functionality
/// This class manages a single audio player instance
class AudioPlayerWeb {
  /// Constructor that requires callbacks and player key
  AudioPlayerWeb({
    required this.onDurationUpdate,
    required this.onCompletion,
  });

  /// Callback for sending duration updates
  final void Function(int currentTime) onDurationUpdate;

  /// Callback for sending completion events
  final void Function() onCompletion;

  /// The HTML audio element for this player
  HTMLAudioElement? _audioElement;

  /// Timer for sending duration updates
  Timer? _durationTimer;

  /// Update frequency in milliseconds
  int _updateFrequency = WebConstants.defaultUpdateFrequency;

  /// Track if the ended listener has been set up
  bool _hasEndedListener = false;

  /// Track if the player has been disposed
  bool _isDisposed = false;

  /// Check if the player is currently playing
  bool get isPlaying {
    if (_audioElement == null) return false;
    return !_audioElement!.paused && !_audioElement!.ended;
  }

  /// Prepares the audio player with the given path
  Future<bool> preparePlayer(Map<dynamic, dynamic> arguments) async {
    try {
      final dynamic rawPath = arguments[Constants.path];
      // Validate required parameters
      if (rawPath is! String || rawPath.isEmpty) {
        'Invalid or missing audio path'.error();
        return false;
      }
      final String path = rawPath;
      final int frequency = arguments[Constants.updateFrequency] ??
          WebConstants.defaultUpdateFrequency;
      final double? volume = arguments[Constants.volume];

      // Store update frequency
      _updateFrequency = frequency;

      // Create a new audio element
      final audioElement = HTMLAudioElement();
      audioElement.src = path;
      audioElement.preload = WebConstants.propertyPreload;

      // Set volume if provided
      if (volume != null) {
        audioElement.volume = volume.clamp(0.0, 1.0);
      }

      // Store the audio element
      _audioElement = audioElement;

      // Wait for metadata to load
      final completer = Completer<bool>();
      bool isCompleted = false;

      audioElement.addEventListener(
        WebConstants.eventLoadedMetadata,
        (Event event) {
          if (!isCompleted) {
            isCompleted = true;
            completer.complete(true);
          }
        }.toJS,
      );

      audioElement.addEventListener(
        WebConstants.eventError,
        (Event event) {
          if (!isCompleted) {
            isCompleted = true;
            completer.completeError('Failed to load audio file');
          }
        }.toJS,
      );

      // Load the audio
      audioElement.load();

      return await completer.future
          .timeout(
        const Duration(seconds: WebConstants.defaultLoadTimeout),
        onTimeout: () => false,
      )
          .catchError((e) {
        // Only return false if the completer wasn't already completed
        if (!isCompleted && !completer.isCompleted) {
          isCompleted = true;
          return false;
        }
        // If already completed, just swallow the error
        return false;
      });
    } catch (e) {
      'Error preparing player: $e'.error();
      return false;
    }
  }

  /// Starts playing the audio
  Future<bool> startPlayer() async {
    try {
      if (_isDisposed || _audioElement == null) {
        return false;
      }

      // Start playing and handle potential promise rejection
      final playPromise = _audioElement!.play();
      // Convert the JS promise to a Dart Future and attach an error handler
      // to avoid unhandled promise rejections in the browser.
      playPromise.toDart.catchError((dynamic err) {
        'Error starting playback: $err'.error();
        return null;
      });

      // Start duration update timer
      _startDurationTimer();

      // Setup ended listener for completion callback (only once per player)
      if (!_hasEndedListener) {
        _hasEndedListener = true;
        _audioElement!.addEventListener(
          WebConstants.eventEnded,
          (Event event) {
            _onAudioFinished();
          }.toJS,
        );
      }

      return true;
    } catch (e) {
      'Error starting player: $e'.error();
      return false;
    }
  }

  /// Pauses the currently playing audio
  Future<bool> pausePlayer() async {
    try {
      if (_isDisposed || _audioElement == null) {
        return false;
      }

      _audioElement!.pause();
      _stopDurationTimer();

      return true;
    } catch (e) {
      'Error pausing player: $e'.error();
      return false;
    }
  }

  /// Stops the audio playback
  Future<bool> stopPlayer() async {
    try {
      if (_isDisposed || _audioElement == null) {
        return false;
      }

      _audioElement!.pause();
      _audioElement!.currentTime = 0;
      _stopDurationTimer();

      return true;
    } catch (e) {
      'Error stopping player: $e'.error();
      return false;
    }
  }

  /// Releases resources associated with the player
  Future<bool> release() async {
    try {
      if (_isDisposed) return true;

      // Stop the player if it's currently playing
      if (isPlaying) {
        await stopPlayer();
      }

      if (_audioElement != null) {
        _stopDurationTimer();
        _audioElement!.pause();
        _audioElement!.src = '';
        _audioElement = null;
      }

      _hasEndedListener = false;

      return true;
    } catch (e) {
      'Error releasing player: $e'.error();
      return false;
    }
  }

  /// Gets the duration of the audio
  Future<int?> getDuration(int durationType) async {
    try {
      if (_isDisposed || _audioElement == null) {
        return -1;
      }

      // durationType: 0 = current, 1 = max
      if (durationType == 0) {
        return (_audioElement!.currentTime * 1000).round();
      } else {
        final duration = _audioElement!.duration;
        if (duration.isNaN || duration.isInfinite) {
          return -1;
        }
        return (duration * 1000).round();
      }
    } catch (e) {
      'Error getting duration: $e'.error();
      return -1;
    }
  }

  /// Seeks to a specific position in the audio
  Future<bool> seekTo(int progress) async {
    try {
      if (_isDisposed || _audioElement == null) {
        return false;
      }

      _audioElement!.currentTime = progress / 1000;
      return true;
    } catch (e) {
      'Error seeking: $e'.error();
      return false;
    }
  }

  /// Sets the volume for the player
  Future<bool> setVolume(double volume) async {
    try {
      if (_isDisposed || _audioElement == null) {
        return false;
      }

      _audioElement!.volume = volume.clamp(0.0, 1.0);
      return true;
    } catch (e) {
      'Error setting volume: $e'.error();
      return false;
    }
  }

  /// Sets the playback rate
  Future<bool> setRate(double rate) async {
    try {
      if (_isDisposed || _audioElement == null) {
        return false;
      }

      _audioElement!.playbackRate = rate;
      return true;
    } catch (e) {
      'Error setting rate: $e'.error();
      return false;
    }
  }

  /// Sets the finish mode for when audio completes
  Future<void> setFinishMode(int? finishType) async {
    // TODO(vasu): Handle proper finish mode
  }

  /// Starts a timer to periodically send duration updates
  void _startDurationTimer() {
    _stopDurationTimer();

    _durationTimer = Timer.periodic(
      Duration(milliseconds: _updateFrequency),
      (timer) {
        if (_audioElement == null) {
          // The audio element has been removed or released; stop this timer.
          timer.cancel();
          return;
        }
        final currentTime = (_audioElement!.currentTime * 1000).round();
        _sendDurationUpdate(currentTime);
      },
    );
  }

  /// Sends duration update through callback
  void _sendDurationUpdate(int currentTime) {
    onDurationUpdate(currentTime);
  }

  /// Stops the duration update timer
  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  /// Called when audio finishes playing
  void _onAudioFinished() {
    _stopDurationTimer();
    _sendCompletionEvent();
  }

  /// Sends a completion event through callback.
  ///
  /// Note:
  /// - On web, finish modes configured via `setFinishMode` (e.g. loop, pause)
  ///   are not applied. The web implementation always reports the finish type
  ///   as `2` (stopped) when playback ends.
  /// - This differs from native platforms, where `setFinishMode` controls the
  ///   value of [Constants.finishType].
  void _sendCompletionEvent() {
    onCompletion();
  }

  /// Dispose all resources
  /// Follows the pattern: stop player → release resources → cleanup → mark as disposed
  Future<void> dispose() async {
    if (_isDisposed) return;

    // Stop the player if it's currently playing
    if (isPlaying) {
      await stopPlayer();
    }

    // Release all resources
    await release();

    _isDisposed = true;
  }
}
