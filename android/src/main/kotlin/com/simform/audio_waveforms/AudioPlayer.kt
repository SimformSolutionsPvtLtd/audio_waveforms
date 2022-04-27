package com.simform.audio_waveforms

import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.annotation.RequiresApi
import com.google.android.exoplayer2.ExoPlayer
import com.google.android.exoplayer2.MediaItem
import com.google.android.exoplayer2.Player
import io.flutter.plugin.common.MethodChannel
import java.lang.Exception

class AudioPlayer(context: Context, channel: MethodChannel) {
    private val LOG_TAG = "AudioWaveforms"
    private var handler: Handler = Handler(Looper.getMainLooper())
    private var runnable = mutableMapOf<String, Runnable?>()
    private var methodChannel = channel
    private var appContext = context
    private var players = mutableMapOf<String, ExoPlayer?>()
    private var playerListeners = mutableMapOf<String, Player.Listener?>()
    private var preparedPlayers = mutableMapOf<String, Boolean>()
    private var seekToStart = true

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    fun preparePlayer(
        result: MethodChannel.Result,
        path: String?,
        volume: Float?,
        key: String?
    ) {

        //TODO: meta data of song
        if (key != null && path != null) {
            val mediaItem = MediaItem.fromUri(path)
            players[key] = ExoPlayer.Builder(appContext).build()
            players[key]?.addMediaItem(mediaItem)
            players[key]?.prepare()
            playerListeners[key] = object : Player.Listener {
                override fun onPlayerStateChanged(isReady: Boolean, state: Int) {
                    if (preparedPlayers[key] == false || preparedPlayers[key] == null) {
                        if (state == Player.STATE_READY) {
                            players[key]?.volume = volume ?: 1F
                            preparedPlayers[key] = true
                            result.success(true)
                        }
                    }
                    if (state == Player.STATE_ENDED && seekToStart) {
                        players[key]?.seekTo(0)
                        players[key]?.pause()
                    }
                }
            }
            players[key]?.addListener(playerListeners[key]!!)
        } else {
            result.error(LOG_TAG, "path to audio file or unique key can't be null", "")
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    fun seekToPosition(result: MethodChannel.Result, progress: Long?, key: String?) {
        if (progress != null && key != null) {
            players[key]?.seekTo(progress)
            result.success(true)
        } else {
            result.success(false)
        }
    }

    fun start(result: MethodChannel.Result, seekToStart: Boolean, key: String?) {
        try {
            this.seekToStart = seekToStart
            players[key]?.play()
            result.success(true)
            startListening(result, key)
        } catch (e: Exception) {
            result.error(LOG_TAG, "Can not start the player", e.toString())
        }
    }

    fun getDuration(result: MethodChannel.Result, durationType: DurationType, key: String?) {
        try {
            if (durationType == DurationType.Current) {
                val duration = players[key]?.currentPosition
                result.success(duration)
            } else {
                val duration = players[key]?.duration
                result.success(duration)
            }
        } catch (e: Exception) {
            result.error(LOG_TAG, "Can not get duration", e.toString())
        }
    }

    fun stop(result: MethodChannel.Result, key: String?) {
        if (key != null) {
            stopListening(key)
            if (playerListeners[key] != null) {
                players[key]?.removeListener(playerListeners[key]!!)
                playerListeners.remove(key)
            }
            preparedPlayers.remove(key)
            players[key]?.stop()
            players[key]?.release()
            result.success(true)
        }
    }


    fun pause(result: MethodChannel.Result, key: String?) {
        if (key != null) {
            try {
                stopListening(key)
                players[key]?.pause()
                result.success(true)
            } catch (e: Exception) {
                result.error(LOG_TAG, "Failed to pause the player", e.toString())
            }
        }

    }

    fun setVolume(volume: Float?, result: MethodChannel.Result, key: String?) {
        try {
            if (volume != null && key != null) {
                players[key]?.volume = volume
                result.success(true)
            } else {
                result.success(false)
            }
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun startListening(result: MethodChannel.Result, key: String?) {
        if (key != null) {
            runnable[key] = object : Runnable {
                override fun run() {
                    val currentPosition = players[key]?.currentPosition
                    if (currentPosition != null) {
                        val args: MutableMap<String, Any?> = HashMap()
                        args[Constants.current] = currentPosition
                        args[Constants.playerKey] = key
                        methodChannel.invokeMethod(Constants.onCurrentDuration, args)
                        handler.postDelayed(this, 200)
                    } else {
                        result.error(LOG_TAG, "Can't get current Position of player", "")
                    }
                }
            }
            handler.post(runnable[key]!!)
        }

    }

    private fun stopListening(key: String?) {
        runnable[key]?.let { handler.removeCallbacks(it) }
    }

    fun stopAllPlayers(result: MethodChannel.Result) {
        for ((key, _) in players) {
            players[key]?.stop()
            players[key] = null
        }
        for ((key, _) in runnable) {
            runnable[key]?.let { handler.removeCallbacks(it) }
            runnable[key] = null
        }
        result.success(true)
    }
}
