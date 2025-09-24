package com.simform.audio_waveforms

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaMetadataRetriever
import android.media.MediaMetadataRetriever.METADATA_KEY_DURATION
import android.media.MediaRecorder
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
import com.simform.audio_waveforms.Constants.LOG_TAG
import com.simform.audio_waveforms.encoders.*
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import kotlin.math.sqrt

class AudioRecorder : PluginRegistry.RequestPermissionsResultListener {
    private val permissions = arrayOf(Manifest.permission.RECORD_AUDIO)
    private var audioRecord: AudioRecord? = null
    private val channelConfig: Int = AudioFormat.CHANNEL_IN_MONO
    private val audioFormat: Int = AudioFormat.ENCODING_PCM_16BIT
    private var bufferSize: Int? = null
    private var recorderState: RecorderState = RecorderState.Disposed
    private var filePath: String? = null
    private var recordingThread: Thread? = null
    private var recorderSettings: RecorderSettings? = null
    private var encoder: Encoder? = null
    lateinit var channel: MethodChannel
    private val commonEncoder = CommonEncoder()
    private var wavEncoder: WavEncoder? = null
    private var successCallback: RequestPermissionsSuccessCallback? = null

    companion object {
        private const val NORMALISATION_FACTOR = 32767.0
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>, grantResults: IntArray
    ): Boolean {
        return if (requestCode == Constants.RECORD_AUDIO_REQUEST_CODE) {
            val isGranted =
                grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            successCallback?.onSuccess(isGranted)
            isGranted
        } else {
            false
        }
    }

    private fun isPermissionGranted(activity: Activity?): Boolean {
        return if (activity != null && permissions.isNotEmpty()) {
            val result = ActivityCompat.checkSelfPermission(activity, permissions[0])
            result == PackageManager.PERMISSION_GRANTED
        } else {
            false
        }
    }

    fun checkPermission(
        result: Result, activity: Activity?, successCallback: RequestPermissionsSuccessCallback
    ) {
        this.successCallback = successCallback
        if (!isPermissionGranted(activity)) {
            if (activity != null) {
                ActivityCompat.requestPermissions(
                    activity, permissions, Constants.RECORD_AUDIO_REQUEST_CODE
                )
            } else {
                result.error(LOG_TAG, "Activity is null, cannot request permissions", null)
            }
        } else {
            result.success(true)
        }
    }

    @RequiresApi(Build.VERSION_CODES.M)
    @SuppressLint("MissingPermission")
    fun initRecorder(
        recorderSettings: RecorderSettings, channel: MethodChannel, result: Result
    ) {
        filePath = recorderSettings.path
        if (filePath == null) {
            result.error(LOG_TAG, "File path is null", null)
            return
        }
        
        this.channel = channel
        bufferSize =
            AudioRecord.getMinBufferSize(recorderSettings.sampleRate, channelConfig, audioFormat)

        if (bufferSize == AudioRecord.ERROR || bufferSize == AudioRecord.ERROR_BAD_VALUE) {
            result.error(
                LOG_TAG,
                "Invalid buffer size: $bufferSize",
                null
            )
            return
        }

        try {
            val currentBufferSize = bufferSize
            if (currentBufferSize != null && currentBufferSize > 0) {
                audioRecord = AudioRecord(
                    MediaRecorder.AudioSource.MIC,
                    recorderSettings.sampleRate,
                    channelConfig,
                    audioFormat,
                    currentBufferSize
                )
            } else {
                result.error(LOG_TAG, "Invalid buffer size", null)
                return
            }
        } catch (e: Exception) {
            result.error(
                LOG_TAG,
                "Error initializing AudioRecord: ${e.message}",
                null
            )
            return
        }
        this.recorderSettings = recorderSettings
        encoder = recorderSettings.encoder
        recorderState = RecorderState.Initialised
        result.success(true)
    }

    fun start(result: Result) {
        if (recorderSettings == null || bufferSize == null) {
            result.error(
                LOG_TAG,
                "recorder settings is null or bufferSize is null",
                "recorderSettings: $recorderSettings, bufferSize: $bufferSize"
            )
            return
        }

        audioRecord?.startRecording()
        recorderState = RecorderState.Recording

        if (currentEncoder?.encodeForWav == true) {
            val currentPath = currentRecorderSettings.path
            if (currentPath != null) {
                wavEncoder = WavEncoder(
                    wavFile = File(currentPath),
                    sampleRate = currentRecorderSettings.sampleRate
                )
                wavEncoder?.start(result)
            } else {
                result.error(LOG_TAG, "File path is null for WAV encoder", null)
                return
            }
        } else {
            commonEncoder.initCodec(recorderSettings = currentRecorderSettings, result = result) {
                recordingThread?.join()
            }
        }

        val buffer = ByteArray(currentBufferSize)
        recordingThread = Thread {
            while (Thread.currentThread().isAlive && !Thread.currentThread().isInterrupted &&
                (recorderState == RecorderState.Recording || recorderState == RecorderState.Paused)
            ) {
                if (recorderState != RecorderState.Recording) continue

                val read = audioRecord?.read(buffer, 0, buffer.size) ?: 0
                if (read <= 0) continue

                val audioData = buffer.copyOf(read)
                if (currentEncoder?.encodeForWav == true) {
                    wavEncoder?.writePcmData(audioData)
                } else {
                    commonEncoder.queueInputBuffer(audioData)
                }
                val rms = calculateRms(audioData, read)
                sendBytesToFlutter(audioData, rms)
            }
        }
        recordingThread?.start()
        result.success(true)
    }

    fun stop(result: Result) {
        try {
            recordingThread?.interrupt() // Interrupt the thread to stop the loop
            audioRecord?.stop()
            recorderState = RecorderState.Stopped

            if (encoder?.encodeForWav == true) {
                wavEncoder?.stop(result)
                recordingThread?.join()
            } else {
                commonEncoder.setOnEncodingCompleted {
                    val duration = getDuration(recorderSettings?.path)
                    val hashMap = HashMap<String, Any?>()
                    hashMap[Constants.resultFilePath] = recorderSettings?.path
                    hashMap[Constants.resultDuration] = duration
                    result.success(hashMap)
                }
                commonEncoder.signalToStop()
            }

        } catch (e: Exception) {
            result.error(LOG_TAG, e.message, "An error occurred while stopping the recorder")
            return
        }
        release()
    }

    private fun sendBytesToFlutter(chunk: ByteArray, rms: Double) {
        if (::channel.isInitialized) {
            val args: MutableMap<String, Any?> = HashMap()
            args["normalisedRms"] = rms
            args["bytes"] = chunk
            Handler(Looper.getMainLooper()).post {
                try {
                    channel.invokeMethod("onAudioChunk", args)
                } catch (e: Exception) {
                    Log.e(LOG_TAG, "Error sending bytes to Flutter: ${e.message}")
                }
            }
        } else {
            Log.w(LOG_TAG, "Channel not initialized, cannot send audio data to Flutter")
        }
    }

    private fun calculateRms(chunk: ByteArray, size: Int): Double {
        var sum = 0.0
        var count = 0

        val adjustedSize = if (size % 2 == 0) size else size - 1
        for (i in 0 until adjustedSize step 2) {
            val low = chunk[i].toInt() and 0xff
            val high = chunk[i + 1].toInt()
            val sample = (high shl 8) or low

            sum += sample * sample.toDouble()
            count++
        }

        val normalisedRms = sqrt(sum / count) / NORMALISATION_FACTOR
        return normalisedRms
    }

    fun pause(result: Result) {
        recorderState = RecorderState.Paused
        result.success(false)
    }

    fun resume(result: Result) {
        recorderState = RecorderState.Recording
        result.success(false)
    }

    fun release() {
        try {
            audioRecord?.stop()
            audioRecord?.release()
            recordingThread?.interrupt()
        } catch (e: Exception) {
            Log.e(LOG_TAG, "Error releasing AudioRecord: ${e.message}")
        }

        audioRecord = null
        recordingThread = null
        recorderState = RecorderState.Disposed
    }

    private fun getDuration(path: String?): Int {
        if (path == null) {
            Log.w(LOG_TAG, "Path is null, cannot get duration")
            return -1
        }
        
        val mediaMetadataRetriever = MediaMetadataRetriever()
        return try {
            mediaMetadataRetriever.setDataSource(path)
            val duration = mediaMetadataRetriever.extractMetadata(METADATA_KEY_DURATION)
            Log.d(LOG_TAG, "Duration: $duration")
            duration?.toInt() ?: -1
        } catch (e: Exception) {
            Log.e(LOG_TAG, "Error getting duration: ${e.message}", e)
            -1
        } finally {
            try {
                mediaMetadataRetriever.release()
            } catch (e: Exception) {
                Log.e(LOG_TAG, "Error releasing MediaMetadataRetriever: ${e.message}")
            }
        }
    }
}
