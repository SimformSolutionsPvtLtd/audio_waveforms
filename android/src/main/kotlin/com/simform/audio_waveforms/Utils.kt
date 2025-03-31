package com.simform.audio_waveforms

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
    const val getDecibel = "getDecibel"
    const val checkPermission = "checkPermission"
    const val path = "path"
    const val LOG_TAG = "AudioWaveforms"
    const val methodChannelName = "simform_audio_waveforms_plugin/methods"
    const val encoder = "encoder"
    const val outputFormat = "outputFormat"
    const val sampleRate = "sampleRate"
    const val bitRate = "bitRate"
    const val fileNameFormat = "dd-MM-yy-hh-mm-ss"


    /** encoder */
    const val acc = 0
    const val aac_eld = 1
    const val he_aac = 2
    const val opus = 5
    const val vorbis = 6

    /** output format */
    const val mpeg4 = 0
    const val three_gpp = 1
    const val ogg = 2
    const val webm = 5
    const val mpeg_2_ts = 6
    const val aac_adts = 7

    /** common */
    const val amr_nb = 3
    const val amr_wb = 4

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
    const val useLegacyNormalization = "useLegacyNormalization"
    const val updateFrequency = "updateFrequency"
    const val STOP_EXTRACTION = "stopExtraction"

    const val resultFilePath = "resultFilePath"
    const val resultDuration = "resultDuration"
    const val pauseAllPlayers = "pauseAllPlayers"


    const val CHANNEL: Int = 1
    const val BIT_PER_SAMPLE: Int = 16
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

enum class OutputFormat {
    AAC_ADTS, AMR_NB, AMR_WB, MPEG_4, OGG, THREE_GPP, WEBM, WAV;

    val mimeType: String
        get() = when (this) {
            AAC_ADTS -> "audio/aac"
            AMR_NB -> "audio/3gpp"
            AMR_WB -> "audio/amr-wb"
            MPEG_4 -> "audio/mp4a-latm"
            OGG -> "audio/ogg"
            THREE_GPP -> "audio/3gpp"
            WEBM -> "audio/webm"
            WAV -> "audio/wav"
        }

    val toAndroidOutputFormat: Int
        get() = when (this) {
            AAC_ADTS -> MediaRecorder.OutputFormat.AAC_ADTS
            AMR_NB -> MediaRecorder.OutputFormat.AMR_NB
            AMR_WB -> MediaRecorder.OutputFormat.AMR_WB
            MPEG_4 -> MediaRecorder.OutputFormat.MPEG_4
            OGG -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    MediaRecorder.OutputFormat.OGG
                } else {
                    Log.e(LOG_TAG, "Minimum android Q is required, Setting Acc encoder.")
                    MediaRecorder.OutputFormat.MPEG_4
                }
            }

            THREE_GPP -> MediaRecorder.OutputFormat.THREE_GPP
            WEBM -> MediaRecorder.OutputFormat.WEBM
            WAV -> MediaRecorder.OutputFormat.MPEG_4
        }

    val bufferSize: Int
        get() = when (this) {
            AAC_ADTS -> 2048
            AMR_NB -> 1024
            AMR_WB -> 2048
            MPEG_4 -> 2048
            OGG -> 4096
            THREE_GPP -> 1024
            WEBM -> 4096
            WAV -> 4096
        }
}


enum class Encoder {
    AAC, AAC_ELD, HE_AAC, AMR_NB, AMR_WB, OPUS, VORBIS;

    val toAndroidEncoder: Int
        get() = when (this) {
            AAC -> MediaRecorder.AudioEncoder.AAC
            AAC_ELD -> MediaRecorder.AudioEncoder.AAC_ELD
            HE_AAC -> MediaRecorder.AudioEncoder.HE_AAC
            AMR_NB -> MediaRecorder.AudioEncoder.AMR_NB
            AMR_WB -> MediaRecorder.AudioEncoder.AMR_WB
            OPUS -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    MediaRecorder.AudioEncoder.OPUS
                } else {
                    Log.e(LOG_TAG, "Minimum android Q is required, Setting Acc encoder.")
                    MediaRecorder.AudioEncoder.AAC
                }
            }

            VORBIS -> MediaRecorder.AudioEncoder.VORBIS
        }
}