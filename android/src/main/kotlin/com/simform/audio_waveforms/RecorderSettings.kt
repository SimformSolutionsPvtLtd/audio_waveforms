package com.simform.audio_waveforms

/**
 * Configuration class for audio recording settings
 *
 * This data class encapsulates all the settings required for configuring
 * the audio recorder, including:
 * - Output file path
 * - Audio encoder/format
 * - Sample rate
 * - Bit rate
 *
 * It provides sensible defaults for common recording scenarios and includes
 * a factory method to create instances from JSON/Map data received from Flutter.
 */
data class RecorderSettings(
    /**
     * Path where the recorded audio file will be saved
     * Can be null if not specified by the caller
     */
    var path: String?,
    
    /**
     * Audio encoder to use for the recording
     * Defaults to AAC Low Complexity (AAC_LC)
     */
    val encoder: Encoder = Encoder.AAC_LC,
    
    /**
     * Sample rate in Hz (samples per second)
     * Defaults to 44100Hz (CD quality)
     */
    val sampleRate: Int = 44100,
    
    /**
     * Bit rate in bits per second
     * Defaults to 128kbps (good quality for most audio)
     */
    val bitRate: Int = 128000
) {
    companion object {
        /**
         * Creates a RecorderSettings instance from a Map/JSON object
         *
         * This factory method is used to convert parameters received from Flutter
         * into a RecorderSettings object. It handles default values when parameters
         * are missing.
         *
         * @param json The map containing recorder settings from Flutter
         * @return A configured RecorderSettings instance
         */
        fun fromJson(json: Map<*, *>): RecorderSettings {
            return RecorderSettings(
                path = json[Constants.path] as String?,
                encoder = Encoder.fromString(json[Constants.encoder] as String?),
                sampleRate = (json[Constants.sampleRate] as Int?) ?: 44100,
                bitRate = json[Constants.bitRate] as Int? ?: 128000
            )
        }
    }
}
