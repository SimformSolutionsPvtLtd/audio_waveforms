package com.simform.audio_waveforms

data class RecorderSettings(
    var path: String?,
    val encoder: Encoder = Encoder.AAC_LC,
    val sampleRate: Int = 44100,
    val bitRate: Int = 128000
) {
    companion object {
        fun fromJson(json: Map<*, *>): RecorderSettings {
            return RecorderSettings(
                path = json[Constants.path] as String?,
                encoder = Encoder.fromString(json[Constants.encoder] as String?),
                sampleRate = (json[Constants.sampleRate] as Int?) ?: 44100,
                bitRate = json[Constants.bitRate] as Int
            )
        }
    }
}