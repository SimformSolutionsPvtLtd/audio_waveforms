package com.simform.audio_waveforms

data class RecorderSettings(
    var path: String?,
    val encoder: Int = 0,
    val outputFormat: Int = 0,
    val sampleRate: Int = 44100,
    val bitRate: Int?
) {
    companion object {
        fun fromJson(json: Map<String, Any?>): RecorderSettings {
            return RecorderSettings(
                path = json[Constants.path] as String?,
                encoder = (json[Constants.encoder] as Int?) ?: 0,
                outputFormat = (json[Constants.outputFormat] as Int?) ?: 0,
                sampleRate = (json[Constants.sampleRate] as Int?) ?: 44100,
                bitRate = json[Constants.bitRate] as Int?
            )
        }
    }
}