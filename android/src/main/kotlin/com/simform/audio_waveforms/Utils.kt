package com.simform.audio_waveforms

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

    /// Indicates 128 bits in a single channel for 8-bit PCM
    const val EIGHT_BITS = 128f

    /// Indicates 32767 bits in a single channel for 16-bit PCM
    const val SIXTEEN_BITS = 32767f

    /// Indicates 2147483648f bits in a single channel for 32-bit PCM
    const val THIRTY_TWO_BITS = 2.14748365E9f
}

enum class FinishMode(val value: Int) {
    Loop(0),
    Pause(1),
    Stop(2)
}


fun interface RequestPermissionsSuccessCallback {
    fun onSuccess(results: Boolean?)
}