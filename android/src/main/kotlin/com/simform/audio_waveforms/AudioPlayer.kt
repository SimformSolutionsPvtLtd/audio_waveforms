package com.simform.audio_waveforms

import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.MediaPlayer.SEEK_CLOSEST
import android.media.MediaPlayer.SEEK_PREVIOUS_SYNC
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.lang.Exception


class AudioPlayer : EventChannel.StreamHandler {
    private val LOG_TAG = "AudioWaveforms"
    var mediaPlayer: MediaPlayer? = null
    private var sink: EventChannel.EventSink? = null
    private var handler: Handler = Handler(Looper.getMainLooper())


    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    fun preparePlayer(
        result: MethodChannel.Result,
        path: String?,
        volume: Float?
    ) {
        //TODO: meta data of song
        mediaPlayer = MediaPlayer()
        if (path != null) {
            mediaPlayer?.setDataSource(path)
            mediaPlayer?.setAudioAttributes(
                AudioAttributes
                    .Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            )
            mediaPlayer?.prepare()
            mediaPlayer?.setVolume(volume ?: 1F, volume ?: 1F)
            result.success(true)
        } else {
            result.success(false)
        }

    }

    @RequiresApi(Build.VERSION_CODES.O)
    fun seekToPosition(result: MethodChannel.Result, progress: Long?) {
        if (progress != null) {
            mediaPlayer?.seekTo(progress, SEEK_PREVIOUS_SYNC)
            result.success(true)
        } else {
            result.success(false)
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    fun start(result: MethodChannel.Result, seekToStart: Boolean) {
        try {
            mediaPlayer?.start()
            mediaPlayer?.setOnCompletionListener { mp ->
                run {
                    sink?.success(mediaPlayer?.duration)
                    if (seekToStart) mp.seekTo(0, SEEK_PREVIOUS_SYNC)
                }
            }
            result.success(true)
        } catch (e: Exception) {
            result.error(LOG_TAG, "Can not start the player", e.toString())
        }
    }

    fun getDuration(result: MethodChannel.Result, durationType: DurationType) {
        try {
            if (durationType == DurationType.Current) {
                result.success(mediaPlayer?.currentPosition)
            } else {
                result.success(mediaPlayer?.duration)
            }

        } catch (e: Exception) {
            result.error(LOG_TAG, "Can not get duration", e.toString())
        }
    }

    fun stop(result: MethodChannel.Result) {
        try {
            mediaPlayer?.stop()
            mediaPlayer?.reset()
            mediaPlayer?.release()
            result.success(true)
        } catch (e: Exception) {
            result.error(LOG_TAG, "Failed to stop the player", e.toString())
        }
    }


    fun pause(result: MethodChannel.Result) {
        try {
            mediaPlayer?.pause()
            result.success(true)
        } catch (e: Exception) {
            result.error(LOG_TAG, "Failed to pause the player", e.toString())
        }
    }

    fun setVolume(volume: Float?, result: MethodChannel.Result) {
        try {
            if (volume != null) {
                mediaPlayer?.setVolume(volume, volume)
                result.success(true)
            } else {
                result.success(false)
            }
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private val runnable = object : Runnable {
        override fun run() {
            if (mediaPlayer?.currentPosition != null) {
                sink?.success(mediaPlayer?.currentPosition)
            } else {
                sink?.error("MediaPlayer", "Can not get duration", "")
            }
            handler.postDelayed(this, 200)
        }
    }

    private fun startListening() {
        handler.post(runnable)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
        Log.d(LOG_TAG, "Attaching listener")
        startListening()
    }

    override fun onCancel(arguments: Any?) {
        sink = null
        handler.removeCallbacks(runnable)
        Log.d(LOG_TAG, "cancelling listener")
    }
}
