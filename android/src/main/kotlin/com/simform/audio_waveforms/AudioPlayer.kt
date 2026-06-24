package com.simform.audio_waveforms

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import com.google.android.exoplayer2.ExoPlayer
import com.google.android.exoplayer2.MediaItem
import com.google.android.exoplayer2.PlaybackException
import com.google.android.exoplayer2.Player
import io.flutter.plugin.common.MethodChannel

class AudioPlayer(
        context: Context,
        channel: MethodChannel,
        playerKey: String
) {
    private var handler: Handler = Handler(Looper.getMainLooper())
    private var runnable: Runnable? = null
    private var methodChannel = channel
    private var appContext = context
    private var player: ExoPlayer? = null
    private var playerListener: Player.Listener? = null
    private var isPlayerPrepared: Boolean = false
    // Guards the prepare result so it is delivered exactly once (success or error).
    private var hasReplied: Boolean = false
    private var finishMode = FinishMode.Stop
    private var key = playerKey
    private var updateFrequency: Long = 200

    // Auto-resume across transient network drops.
    // Re-prepare attempts used since the last successful prepare; reset on STATE_READY.
    private var networkRetryCount = 0
    // Max re-prepare attempts before giving up and tearing down.
    private val maxNetworkRetries = 5
    // Delay between re-prepare attempts.
    private val networkRetryDelayMs = 3000L
    // Pending delayed re-prepare; cancelled in stop().
    private var retryRunnable: Runnable? = null

    fun preparePlayer(
            result: MethodChannel.Result,
            path: String?,
            volume: Float?,
            frequency: Long?,
    ) {
        if (path != null) {
            frequency?.let {
                updateFrequency = it
            }
            val uri = Uri.parse(path)
            val mediaItem = MediaItem.fromUri(uri)
            hasReplied = false
            networkRetryCount = 0
            stop()
            player?.clearMediaItems()
            player = ExoPlayer.Builder(appContext).build()
            player?.setMediaItem(mediaItem)
            player?.prepare()
            playerListener = object : Player.Listener {

                override fun onPlayerError(error: PlaybackException) {
                    super.onPlayerError(error)
                    if (!isPlayerPrepared) {
                        if (!hasReplied) {
                            hasReplied = true
                            result.error(Constants.LOG_TAG, error.message, "Unable to load media source.")
                        }
                    } else if (isRecoverableNetworkError(error) && networkRetryCount < maxNetworkRetries) {
                        // Transient network drop: keep the player and re-prepare. ExoPlayer retains the
                        // playback position, so it resumes once connectivity returns. Bounded retries +
                        // delay let permanent loss fall through to the teardown branch below.
                        networkRetryCount++
                        retryRunnable?.let { handler.removeCallbacks(it) }
                        // ExoPlayer retains playWhenReady across a re-prepare, so the user's current
                        // play/pause intent is honored even if they paused during the retry window.
                        // Don't snapshot it at error time — that would override a pause issued mid-wait.
                        retryRunnable = Runnable {
                            player?.prepare()
                        }
                        handler.postDelayed(retryRunnable!!, networkRetryDelayMs)
                    } else {
                        val args: MutableMap<String, Any?> = HashMap()
                        args[Constants.playerKey] = key
                        args[Constants.finishType] = 2
                        // Route through stop() so the listener and any pending retry are cleaned up too.
                        stop()
                        player?.release()
                        player = null
                        methodChannel.invokeMethod(Constants.onDidFinishPlayingAudio, args)
                    }
                }

                override fun onPlayerStateChanged(isReady: Boolean, state: Int) {
                    // Note: networkRetryCount is intentionally NOT reset here. Resetting on every
                    // STATE_READY lets a flapping connection (ready->drop->ready->drop) refill the
                    // budget endlessly, so maxNetworkRetries never bounds total retries. It is reset
                    // once per preparePlayer() call, making the cap a real per-prepare ceiling.
                    if (!isPlayerPrepared) {
                        if (state == Player.STATE_READY) {
                            player?.volume = volume ?: 1F
                            isPlayerPrepared = true
                            if (!hasReplied) {
                                hasReplied = true
                                result.success(true)
                            }
                        }
                    }
                    if (state == Player.STATE_ENDED) {
                        val args: MutableMap<String, Any?> = HashMap()
                        when (finishMode) {
                            FinishMode.Stop -> {
                                player?.stop()
                                player?.release()
                                player = null
                                stopListening()
                                args[Constants.finishType] = 2
                            }

                            FinishMode.Loop -> {
                                player?.seekTo(0)
                                player?.play()
                                args[Constants.finishType] = 0
                            }

                            FinishMode.Pause -> {
                                player?.seekTo(0)
                                player?.playWhenReady = false
                                stopListening()
                                args[Constants.finishType] = 1
                            }
                        }
                        args[Constants.playerKey] = key
                        methodChannel.invokeMethod(
                                Constants.onDidFinishPlayingAudio,
                                args
                        )
                    }
                }
            }
            player?.addListener(playerListener!!)
        } else {
            result.error(Constants.LOG_TAG, "path to audio file or unique key can't be null", "")
        }
    }

    fun seekToPosition(result: MethodChannel.Result, progress: Long?) {
        if (progress != null) {
            player?.seekTo(progress)
            sendCurrentDuration()
            result.success(true)
        } else {
            result.success(false)
        }
    }

    fun start(result: MethodChannel.Result) {
        try {
            player?.playWhenReady = true
            player?.play()
            result.success(true)
            startListening(result)
        } catch (e: Exception) {
            result.error(Constants.LOG_TAG, "Can not start the player", e.toString())
        }
    }

    fun getDuration(result: MethodChannel.Result, durationType: DurationType) {
        try {
            if (durationType == DurationType.Current) {
                val duration = player?.currentPosition
                result.success(duration)
            } else {
                val duration = player?.duration
                result.success(duration)
            }
        } catch (e: Exception) {
            result.error(Constants.LOG_TAG, "Can not get duration", e.toString())
        }
    }

    fun stop() {
        retryRunnable?.let { handler.removeCallbacks(it) }
        retryRunnable = null
        stopListening()
        if (playerListener != null) {
            player?.removeListener(playerListener!!)
        }
        isPlayerPrepared = false
        player?.stop()
    }

    /**
     * Network/HTTP IO errors that are worth retrying. ExoPlayer keeps the playback position across
     * a re-prepare, so these recover seamlessly once connectivity is restored.
     */
    private fun isRecoverableNetworkError(error: PlaybackException): Boolean {
        return when (error.errorCode) {
            PlaybackException.ERROR_CODE_IO_UNSPECIFIED,
            PlaybackException.ERROR_CODE_IO_NETWORK_CONNECTION_FAILED,
            PlaybackException.ERROR_CODE_IO_NETWORK_CONNECTION_TIMEOUT -> true
            else -> false
        }
    }


    fun pause() {
        stopListening()
        player?.pause()
    }

    fun release(result: MethodChannel.Result) {
        try {
            // Route through stop() first so the listener and any pending re-prepare retry are
            // cancelled; otherwise a delayed retryRunnable could call prepare() on a released
            // player and crash with IllegalStateException.
            stop()
            player?.release()
            player = null
            result.success(true)
        } catch (e: Exception) {
            result.error(Constants.LOG_TAG, "Failed to release player resource", e.toString())
        }

    }

    fun setVolume(volume: Float?, result: MethodChannel.Result) {
        try {
            if (volume != null) {
                player?.volume = volume
                result.success(true)
            } else {
                result.success(false)
            }
        } catch (e: Exception) {
            result.success(false)
        }
    }

    fun setRate(rate: Float?, result: MethodChannel.Result) {
        try {
            if (rate != null) {
                player?.setPlaybackSpeed(rate)
                result.success(true)
            } else {
                result.success(false)
            }
        } catch (e: Exception) {
            result.success(false)
        }
    }

    fun setFinishMode(result: MethodChannel.Result, releaseModeType: Int?) {
        try {
            when (releaseModeType) {
                0 -> {
                    this.finishMode = FinishMode.Loop
                }

                1 -> {
                    this.finishMode = FinishMode.Pause
                }

                2 -> {
                    this.finishMode = FinishMode.Stop
                }

                null -> {
                    throw Exception("Release mode is null")
                }

                else -> {
                    throw Exception("Invalid Finish mode")
                }
            }
            result.success(null)
        } catch (e: Exception) {
            result.error(Constants.LOG_TAG, "Can not set the release mode", e.toString())
        }
    }

    private fun startListening(result: MethodChannel.Result) {
        runnable = object : Runnable {
            override fun run() {
                sendCurrentDuration()
                handler.postDelayed(this, updateFrequency)
            }
        }
        handler.post(runnable!!)

    }

    private fun stopListening() {
        runnable?.let { handler.removeCallbacks(it) }
        sendCurrentDuration()
    }

    private fun sendCurrentDuration() {
        val currentPosition = player?.currentPosition ?: 0
        val args: MutableMap<String, Any?> = HashMap()
        args[Constants.current] = currentPosition
        args[Constants.playerKey] = key
        methodChannel.invokeMethod(Constants.onCurrentDuration, args)
    }


}
