package com.simform.audio_waveforms

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.media.MediaMetadataRetriever
import android.media.MediaMetadataRetriever.METADATA_KEY_DURATION
import android.media.MediaRecorder
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.IOException
import java.lang.IllegalStateException
import kotlin.math.log10

private const val LOG_TAG = "AudioWaveforms"
private const val RECORD_AUDIO_REQUEST_CODE = 1001

class AudioRecorder : PluginRegistry.RequestPermissionsResultListener {
    private var permissions = arrayOf(Manifest.permission.RECORD_AUDIO)
    private var useLegacyNormalization = false
    private var successCallback: RequestPermissionsSuccessCallback? = null

    fun getDecibel(result: MethodChannel.Result, recorder: MediaRecorder?) {
        if (useLegacyNormalization) {
            val db = 20 * log10(((recorder?.maxAmplitude?.toDouble() ?: (0.0 / 32768.0))))
            if (db == Double.NEGATIVE_INFINITY) {
                Log.d(LOG_TAG, "Microphone might be turned off")
            } else {
                result.success(db)
            }
        } else {
            result.success(recorder?.maxAmplitude?.toDouble() ?: 0.0)
        }
    }

    fun initRecorder(
        path: String,
        result: MethodChannel.Result,
        recorder: MediaRecorder?,
        encoder: Int,
        outputFormat: Int,
        sampleRate: Int,
        bitRate: Int?
    ) {
        recorder?.apply {
            setAudioSource(MediaRecorder.AudioSource.MIC)
            setOutputFormat(getOutputFormat(outputFormat))
            setAudioEncoder(getEncoder(encoder))
            setAudioSamplingRate(sampleRate)
            if (bitRate != null) {
                setAudioEncodingBitRate(bitRate)
            }
            setOutputFile(path)
            try {
                recorder.prepare()
                result.success(true)
            } catch (e: IOException) {
                Log.e(LOG_TAG, "Failed to stop initialize recorder")
            }
        }
    }

    fun stopRecording(result: MethodChannel.Result, recorder: MediaRecorder?, path: String) {
        try {
            val hashMap : HashMap<String,Any?> = HashMap()
            try {
                recorder?.stop()

                val duration = getDuration(path)

                hashMap[Constants.resultFilePath] = path
                hashMap[Constants.resultDuration] = duration
            } catch (e: RuntimeException) {
                // Stop was called immediately after start which causes stop() call to fail.
                hashMap[Constants.resultFilePath] = null
                hashMap[Constants.resultDuration] = -1
            }

            recorder?.apply {
                reset()
                release()
            }

            result.success(hashMap)
        } catch (e: IllegalStateException) {
            Log.e(LOG_TAG, "Failed to stop recording")
        }
    }

    private fun getDuration(path: String): Int {
        val mediaMetadataRetriever = MediaMetadataRetriever()
        try {
            mediaMetadataRetriever.setDataSource(path)
            val duration = mediaMetadataRetriever.extractMetadata(METADATA_KEY_DURATION)
            return duration?.toInt() ?: -1
        } catch (e: Exception) {
            Log.e(LOG_TAG, "Failed to get recording duration")
        } finally {
            mediaMetadataRetriever.release()
        }
        return -1
    }

    fun startRecorder(result: MethodChannel.Result, recorder: MediaRecorder?, useLegacy: Boolean) {
        try {
            useLegacyNormalization = useLegacy
            recorder?.start()
            result.success(true)
        } catch (e: IllegalStateException) {
            Log.e(LOG_TAG, "Failed to start recording")
        }
    }

    @RequiresApi(Build.VERSION_CODES.N)
    fun pauseRecording(result: MethodChannel.Result, recorder: MediaRecorder?) {
        try {
            recorder?.pause()
            result.success(false)
        } catch (e: IllegalStateException) {
            Log.e(LOG_TAG, "Failed to pause recording")
        }
    }

    @RequiresApi(Build.VERSION_CODES.N)
    fun resumeRecording(result: MethodChannel.Result, recorder: MediaRecorder?) {
        try {
            recorder?.resume()
            result.success(true)
        } catch (e: IllegalStateException) {
            Log.e(LOG_TAG, "Failed to resume recording")
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        return if (requestCode == RECORD_AUDIO_REQUEST_CODE) {
            successCallback?.onSuccess(grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED)
            grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
        } else {
            false
        }
    }

    private fun isPermissionGranted(activity: Activity?): Boolean {
        val result =
            ActivityCompat.checkSelfPermission(activity!!, permissions[0])
        return result == PackageManager.PERMISSION_GRANTED
    }

    fun checkPermission(result: MethodChannel.Result, activity: Activity?, successCallback: RequestPermissionsSuccessCallback) {
        this.successCallback = successCallback
        if (!isPermissionGranted(activity)) {
            activity?.let {
                ActivityCompat.requestPermissions(
                    it, permissions,
                    RECORD_AUDIO_REQUEST_CODE
                )
            }
        } else {
            result.success(true)
        }
    }

    private fun getEncoder(encoder: Int): Int {
        when (encoder) {
            Constants.acc -> return MediaRecorder.AudioEncoder.AAC
            Constants.aac_eld -> return MediaRecorder.AudioEncoder.AAC_ELD
            Constants.he_aac -> return MediaRecorder.AudioEncoder.HE_AAC
            Constants.amr_nb -> return MediaRecorder.AudioEncoder.AMR_NB
            Constants.amr_wb -> return MediaRecorder.AudioEncoder.AMR_WB
            Constants.opus -> {
                return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    MediaRecorder.AudioEncoder.OPUS
                } else {
                    Log.e(LOG_TAG, "Minimum android Q is required, Setting Acc encoder.")
                    MediaRecorder.AudioEncoder.AAC
                }
            }
            Constants.vorbis -> return MediaRecorder.AudioEncoder.VORBIS

            else -> return MediaRecorder.AudioEncoder.AAC
        }
    }

    private fun getOutputFormat(format: Int): Int {
        when (format) {
            Constants.mpeg4 -> return MediaRecorder.OutputFormat.MPEG_4
            Constants.three_gpp -> return MediaRecorder.OutputFormat.THREE_GPP
            Constants.ogg -> {
                return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    MediaRecorder.OutputFormat.OGG
                } else {
                    Log.e(LOG_TAG, "Minimum android Q is required, Setting Acc encoder.")
                    MediaRecorder.OutputFormat.MPEG_4
                }
            }

            Constants.amr_wb -> return MediaRecorder.OutputFormat.AMR_WB
            Constants.amr_nb -> return MediaRecorder.OutputFormat.AMR_NB
            Constants.webm ->
                return MediaRecorder.OutputFormat.WEBM
            Constants.mpeg_2_ts -> {
                return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    MediaRecorder.OutputFormat.MPEG_2_TS
                } else {
                    Log.e(LOG_TAG, "Minimum android Q is required, Setting MPEG_4 output format.")
                    MediaRecorder.OutputFormat.MPEG_4
                }
            }
            Constants.aac_adts -> return MediaRecorder.OutputFormat.AAC_ADTS
            else -> return MediaRecorder.OutputFormat.MPEG_4
        }
    }
}