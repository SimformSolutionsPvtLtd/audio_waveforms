package com.simform.audio_waveforms

import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import android.media.MediaRecorder
import android.os.Build
import android.util.Log
import com.simform.audio_waveforms.Constants.LOG_TAG

enum class DurationType { Current, Max }

object Constants {

    // TODO: Update all const to uppercase
    const val initRecorder = "initRecorder"
    const val startRecording = "startRecording"
    const val stopRecording = "stopRecording"
    const val pauseRecording = "pauseRecording"
    const val resumeRecording = "resumeRecording"
    const val checkPermission = "checkPermission"
    const val path = "path"
    const val LOG_TAG = "AudioWaveforms"
    const val methodChannelName = "simform_audio_waveforms_plugin/methods"
    const val encoder = "encoder"
    const val sampleRate = "sampleRate"
    const val bitRate = "bitRate"
    const val fileNameFormat = "dd-MM-yy-hh-mm-ss"

    const val preparePlayer = "preparePlayer"
    const val startPlayer = "startPlayer"
    const val stopPlayer = "stopPlayer"
    const val pausePlayer = "pausePlayer"
    const val releasePlayer = "releasePlayer"
    const val seekTo = "seekTo"
    const val progress = "progress"
    const val setVolume = "setVolume"
    const val finishMode = "finishMode"
    const val finishType = "finishType"
    const val volume = "volume"
    const val setRate = "setRate"
    const val rate = "rate"
    const val getDuration = "getDuration"
    const val durationType = "durationType"
    const val playerKey = "playerKey"
    const val current = "current"
    const val onCurrentDuration = "onCurrentDuration"
    const val stopAllPlayers = "stopAllPlayers"
    const val onDidFinishPlayingAudio = "onDidFinishPlayingAudio"
    const val extractWaveformData = "extractWaveformData"
    const val noOfSamples = "noOfSamples"
    const val onCurrentExtractedWaveformData = "onCurrentExtractedWaveformData"
    const val waveformData = "waveformData"
    const val updateFrequency = "updateFrequency"
    const val STOP_EXTRACTION = "stopExtraction"

    const val resultFilePath = "resultFilePath"
    const val resultDuration = "resultDuration"
    const val pauseAllPlayers = "pauseAllPlayers"
    const val ENCODER_THREAD = "EncoderThread"
    const val AAC_FILE_EXTENSION = "aac"


    // TODO: make user can set this in future
    const val CHANNEL: Int = 1
    const val BIT_PER_SAMPLE: Int = 16

    const val RECORD_AUDIO_REQUEST_CODE = 1001
}

enum class FinishMode(val value: Int) {
    Loop(0), Pause(1), Stop(2)
}


fun interface RequestPermissionsSuccessCallback {
    fun onSuccess(results: Boolean?)
}

enum class RecorderState {
    Initialised, Recording, Paused, Stopped, Disposed
}

enum class Encoder {
    WAV, AAC_LC, AAC_HE, AAC_ELD, AMR_NB, AMR_WB, OPUS;

    val mimeType: String
        get() = when (this) {
            WAV -> MediaFormat.MIMETYPE_AUDIO_RAW
            AAC_LC, AAC_HE, AAC_ELD -> MediaFormat.MIMETYPE_AUDIO_AAC
            AMR_NB -> MediaFormat.MIMETYPE_AUDIO_AMR_NB
            AMR_WB -> MediaFormat.MIMETYPE_AUDIO_AMR_WB
            OPUS -> MediaFormat.MIMETYPE_AUDIO_OPUS
        }

    val bufferSize: Int
        get() = when (this) {
            AAC_LC -> 2048
            AAC_HE -> 2048
            AAC_ELD -> 2048
            AMR_NB -> 1024
            AMR_WB -> 2048
            WAV -> 8192
            OPUS -> 2048
        }

    val toOutputFormat: Int
        get() = when (this) {
            WAV -> throw IllegalArgumentException("Illegal format selection.")
            AAC_LC, AAC_HE, AAC_ELD -> MediaRecorder.OutputFormat.MPEG_4
            AMR_NB -> MediaRecorder.OutputFormat.AMR_NB
            AMR_WB -> MediaRecorder.OutputFormat.AMR_WB
            OPUS -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    MediaMuxer.OutputFormat.MUXER_OUTPUT_OGG
                } else {
                    throw Exception("Minimum android Q is required for $this encoder.")
                }
            }
        }

    val useMediaMuxer: Boolean
        get() = when (this) {
            WAV, AMR_NB, AMR_WB -> false
            AAC_LC, AAC_HE, AAC_ELD, OPUS -> true
        }

    val aacProfile: Int?
        get() = when (this) {
            AAC_LC -> MediaCodecInfo.CodecProfileLevel.AACObjectLC
            AAC_HE -> MediaCodecInfo.CodecProfileLevel.AACObjectHE
            AAC_ELD -> MediaCodecInfo.CodecProfileLevel.AACObjectELD
            else -> null
        }

    companion object {
        fun fromString(value: String?): Encoder {
            return try {
                if (value == null) {
                    Log.e(LOG_TAG, "Encoder type is null. Defaulting to AAC_LC.")
                    return AAC_LC
                }
                valueOf(value)
            } catch (_: IllegalArgumentException) {
                Log.e(LOG_TAG, "Invalid encoder type: $value. Defaulting to AAC_LC.")
                AAC_LC
            }
        }
    }

    val encodeForWav: Boolean
        get() {
            return this == WAV
        }
    val isAAC: Boolean
        get() {
            return this == AAC_LC || this == AAC_HE || this == AAC_ELD
        }
}