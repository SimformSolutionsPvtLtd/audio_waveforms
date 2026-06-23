package com.simform.audio_waveforms

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaMetadataRetriever
import android.media.MediaMetadataRetriever.METADATA_KEY_DURATION
import android.media.audiofx.AcousticEchoCanceler
import android.media.audiofx.AudioEffect
import android.media.audiofx.AutomaticGainControl
import android.media.audiofx.NoiseSuppressor
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
    private var permissions = arrayOf(Manifest.permission.RECORD_AUDIO)
    private var audioRecord: AudioRecord? = null
    private var noiseSuppressor: NoiseSuppressor? = null
    private var echoCanceler: AcousticEchoCanceler? = null
    private var gainControl: AutomaticGainControl? = null
    private var channelConfig: Int = AudioFormat.CHANNEL_IN_MONO
    private var audioFormat: Int = AudioFormat.ENCODING_PCM_16BIT
    private var bufferSize: Int? = null
    private var recorderState: RecorderState = RecorderState.Disposed
    private var filePath: String? = null
    private var recordingThread: Thread? = null
    private var recorderSettings: RecorderSettings? = null
    private var encoder: Encoder? = null
    lateinit var channel: MethodChannel
    private var commonEncoder = CommonEncoder()
    private var wavEncoder: WavEncoder? = null
    private var successCallback: RequestPermissionsSuccessCallback? = null
    private var totalSamples = 0L
    private val channelCount: Int
        get() = when (channelConfig) {
            AudioFormat.CHANNEL_IN_MONO -> 1
            AudioFormat.CHANNEL_IN_STEREO -> 2
            else -> 1
        }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>, grantResults: IntArray
    ): Boolean {
        return if (requestCode == Constants.RECORD_AUDIO_REQUEST_CODE) {
            successCallback?.onSuccess(grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED)
            grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
        } else {
            false
        }
    }

    private fun isPermissionGranted(activity: Activity?): Boolean {
        val result = ActivityCompat.checkSelfPermission(activity!!, permissions[0])
        return result == PackageManager.PERMISSION_GRANTED
    }

    fun checkPermission(
        result: Result, activity: Activity?, successCallback: RequestPermissionsSuccessCallback
    ) {
        this.successCallback = successCallback
        if (!isPermissionGranted(activity)) {
            activity?.let {
                ActivityCompat.requestPermissions(
                    it, permissions, Constants.RECORD_AUDIO_REQUEST_CODE
                )
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
        if (filePath == null) return
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
        val resolvedSource = resolveAudioSource(recorderSettings.audioSource)
        try {
            audioRecord = AudioRecord(
                resolvedSource,
                recorderSettings.sampleRate,
                channelConfig,
                audioFormat,
                bufferSize!!
            )
        } catch (e: Exception) {
            result.error(
                LOG_TAG,
                "Error initializing AudioRecord: ${e.message}",
                null
            )
            return
        }
        // A successfully constructed AudioRecord can still be unusable when the
        // requested (source, sampleRate, channel) combo is unsupported — e.g.
        // VOICE_COMMUNICATION at 44100Hz on some devices. Reading from an
        // uninitialised recorder yields garbage/wrong-rate PCM (loud noise),
        // so fail loudly instead of recording unusable audio.
        if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
            audioRecord?.release()
            audioRecord = null
            result.error(
                LOG_TAG,
                "AudioRecord failed to initialise for source=$resolvedSource, " +
                    "sampleRate=${recorderSettings.sampleRate}. The audio source may not support this configuration.",
                null
            )
            return
        }
        attachAudioEffects(audioRecord!!.audioSessionId, recorderSettings)
        this.recorderSettings = recorderSettings
        encoder = recorderSettings.encoder
        recorderState = RecorderState.Initialised
        result.success(true)
    }

    /**
     * Resolves the requested audio source against the running API level.
     *
     * UNPROCESSED (9) requires API 24 and VOICE_PERFORMANCE (10) requires API
     * 29. On older devices these constants are unknown, so we fall back to
     * DEFAULT (0) instead of passing an int the platform cannot honour.
     */
    private fun resolveAudioSource(audioSource: Int): Int {
        return when {
            audioSource == UNPROCESSED_SOURCE && Build.VERSION.SDK_INT < Build.VERSION_CODES.N ->
                DEFAULT_SOURCE
            audioSource == VOICE_PERFORMANCE_SOURCE && Build.VERSION.SDK_INT < Build.VERSION_CODES.Q ->
                DEFAULT_SOURCE
            else -> audioSource
        }
    }

    /**
     * Attaches the audio effects the caller opted into to the recording session.
     *
     * Each effect is opt-in (off by default) and device-dependent, so we guard
     * with the caller's flag and isAvailable(), and swallow failures
     * individually — a missing or unsupported effect must not abort recording.
     */
    private fun attachAudioEffects(sessionId: Int, recorderSettings: RecorderSettings) {
        if (recorderSettings.useNoiseSuppressor) {
            try {
                if (NoiseSuppressor.isAvailable()) {
                    noiseSuppressor = NoiseSuppressor.create(sessionId)?.also { enableEffect(it, "NoiseSuppressor") }
                }
            } catch (e: Exception) {
                Log.e(LOG_TAG, "Error enabling NoiseSuppressor: ${e.message}")
            }
        }
        if (recorderSettings.useEchoCanceler) {
            try {
                if (AcousticEchoCanceler.isAvailable()) {
                    echoCanceler = AcousticEchoCanceler.create(sessionId)?.also { enableEffect(it, "AcousticEchoCanceler") }
                }
            } catch (e: Exception) {
                Log.e(LOG_TAG, "Error enabling AcousticEchoCanceler: ${e.message}")
            }
        }
        if (recorderSettings.useAutoGainControl) {
            try {
                if (AutomaticGainControl.isAvailable()) {
                    gainControl = AutomaticGainControl.create(sessionId)?.also { enableEffect(it, "AutomaticGainControl") }
                }
            } catch (e: Exception) {
                Log.e(LOG_TAG, "Error enabling AutomaticGainControl: ${e.message}")
            }
        }
    }

    /**
     * Enables an audio effect and logs when the platform refuses to enable it.
     *
     * [AudioEffect.setEnabled] returns a status code rather than throwing; a
     * non-SUCCESS result means the effect is attached but inactive, so the
     * recording keeps the unwanted noise/echo. Surface that instead of silently
     * pretending the effect is on.
     */
    private fun enableEffect(effect: AudioEffect, name: String) {
        val status = effect.setEnabled(true)
        if (status != AudioEffect.SUCCESS) {
            Log.e(LOG_TAG, "Failed to enable $name (status=$status); recording continues without it")
        }
    }

    private fun releaseAudioEffects() {
        try {
            noiseSuppressor?.release()
            echoCanceler?.release()
            gainControl?.release()
        } catch (e: Exception) {
            Log.e(LOG_TAG, "Error releasing audio effects: ${e.message}")
        }
        noiseSuppressor = null
        echoCanceler = null
        gainControl = null
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
        if (encoder?.encodeForWav == true) {
            wavEncoder = WavEncoder(
                wavFile = File(recorderSettings!!.path!!),
                sampleRate = recorderSettings!!.sampleRate
            )
            wavEncoder?.start(result)
        } else {
            commonEncoder.initCodec(recorderSettings = recorderSettings!!, result = result) {
                recordingThread?.join()
            }
        }
        val buffer = ByteArray(bufferSize!!)
        recordingThread = Thread {
            while (recorderState == RecorderState.Recording || recorderState == RecorderState.Paused) {
                if (recorderState == RecorderState.Recording) {
                    val read = audioRecord?.read(buffer, 0, buffer.size) ?: 0

                    if (read > 0) {
                        val audioData = buffer.copyOf(read)
                        if (encoder?.encodeForWav == true) {
                            wavEncoder?.writePcmData(audioData)
                        } else {
                            commonEncoder.queueInputBuffer(audioData)
                        }
                        val rms = calculateRms(audioData, read)
                        totalSamples += read / channelCount
                        val durationSec =
                            totalSamples.toDouble() / (recorderSettings?.sampleRate
                                ?: Constants.DEFAULT_SAMPLE_RATE)
                        val milliSeconds = (durationSec * 1000).toLong()
                        sendBytesToFlutter(audioData, rms, milliSeconds)
                    }
                }
            }
        }
        recordingThread?.start()
        result.success(true)
    }

    fun stop(result: Result) {
        try {
            audioRecord?.stop()
            totalSamples = 0L
            recorderState = RecorderState.Stopped
            if (encoder?.encodeForWav == true) {
                wavEncoder?.stop(result)
                recordingThread?.join()
                sendRecordingResult(result)
            } else {
                commonEncoder.setOnEncodingCompleted {
                    sendRecordingResult(result)
                }
                commonEncoder.signalToStop()
            }

        } catch (e: Exception) {
            result.error(LOG_TAG, e.message, "An error occurred while stopping the recorder")
            return
        }
        release()
    }

    private fun sendRecordingResult(result: Result) {
        val duration = getDuration(recorderSettings?.path)
        val hashMap = HashMap<String, Any?>()
        hashMap[Constants.resultFilePath] = recorderSettings?.path
        hashMap[Constants.resultDuration] = duration
        result.success(hashMap)
    }

    private fun sendBytesToFlutter(chunk: ByteArray, rms: Double, milliSeconds: Long) {
        val args: MutableMap<String, Any?> = HashMap()
        args[Constants.normalisedRms] = rms
        args[Constants.bytes] = chunk
        args[Constants.recordedDuration] = milliSeconds
        Handler(Looper.getMainLooper()).post {
            channel.invokeMethod(Constants.onAudioChunk, args)
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

        val normalisedRms = sqrt(sum / count) / 32767.0
        return normalisedRms
    }

    fun pause(result: Result) {
        recorderState = RecorderState.Paused
        result.success(false)
    }

    fun resume(result: Result) {
        recorderState = RecorderState.Recording
        result.success(true)
    }

    fun release() {
        releaseAudioEffects()
        try {
            audioRecord?.release()
        } catch (e: Exception) {
            Log.e(LOG_TAG, "Error releasing AudioRecord: ${e.message}")
        }

        audioRecord = null
        recorderState = RecorderState.Disposed
    }

    private fun getDuration(path: String?): Int {
        val mediaMetadataRetriever = MediaMetadataRetriever()
        try {
            mediaMetadataRetriever.setDataSource(path)
            val duration = mediaMetadataRetriever.extractMetadata(METADATA_KEY_DURATION)
            return duration?.toInt() ?: -1
        } catch (e: Exception) {
            Log.e(LOG_TAG, "Error getting duration: ${e.message}")
        } finally {
            mediaMetadataRetriever.release()
        }
        return -1
    }

    companion object {
        private const val DEFAULT_SOURCE = 0
        private const val UNPROCESSED_SOURCE = 9
        private const val VOICE_PERFORMANCE_SOURCE = 10
    }
}
