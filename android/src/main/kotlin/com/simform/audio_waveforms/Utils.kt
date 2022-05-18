package com.simform.audio_waveforms

enum class DurationType { Current, Max }

object Constants {

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
    const val fileNameFormat = "dd-MM-yy-hh-mm-ss"


    /** encoder */
    const val acc = 1
    const val aac_eld = 2
    const val he_aac = 3
    const val opus = 6
    const val vorbis = 7

    /** output format */
    const val mpeg4 = 1
    const val three_gpp = 2
    const val ogg = 3
    const val webm = 6
    const val mpeg_2_ts = 7
    const val aac_adts = 8

    /** common */
    const val amr_nb = 4
    const val amr_wb = 5

    const val preparePlayer = "preparePlayer"
    const val startPlayer = "startPlayer"
    const val stopPlayer = "stopPlayer"
    const val pausePlayer = "pausePlayer"
    const val seekTo = "seekTo"
    const val progress = "progress"
    const val setVolume = "setVolume"
    const val volume = "volume"
    const val getDuration = "getDuration"
    const val durationType = "durationType"
    const val seekToStart = "seekToStart"
    const val playerKey = "playerKey"
    const val current = "current"
    const val onCurrentDuration = "onCurrentDuration"
    const val stopAllPlayers = "stopAllPlayers"
    const val onDidFinishPlayingAudio = "onDidFinishPlayingAudio"
    const val finishMode = "finishMode"
    const val finishType = "finishType"
}

enum class FinishMode(val value:Int) {
    Loop(0),
    Pause(1),
    Stop(2)
}