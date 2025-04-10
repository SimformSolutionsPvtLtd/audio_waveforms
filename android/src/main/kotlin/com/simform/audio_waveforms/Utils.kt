package com.simform.audio_waveforms

import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import android.media.MediaRecorder
import android.os.Build
import android.util.Log
import com.simform.audio_waveforms.Constants.LOG_TAG

/**
 * Specifies which duration value to retrieve from an audio player
 */
enum class DurationType { 
    /** Current playback position */
    Current, 
    /** Total duration of the audio file */
    Max 
}

/**
 * Global constants used throughout the audio_waveforms plugin
 *
 * This object contains method channel names, parameter keys, default values,
 * and other constants needed for the plugin's operation.
 */
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
    // TODO: make user can set this in future
    const val CHANNEL: Int = 1
    const val BIT_PER_SAMPLE: Int = 16

    const val RECORD_AUDIO_REQUEST_CODE = 1001

    /// Indicates 128 bits in a single channel for 8-bit PCM
    const val EIGHT_BITS = 128f

    /// Indicates 32767 bits in a single channel for 16-bit PCM
    const val SIXTEEN_BITS = 32767f

    /// Indicates 2147483648f bits in a single channel for 32-bit PCM
    const val THIRTY_TWO_BITS = 2.14748365E9f
    const val ENCODER_THREAD = "EncoderThread"
    const val AAC_FILE_EXTENSION = "aac"
}

/**
 * Defines behavior when audio playback reaches the end
 * 
 * Controls what happens when an audio file finishes playing.
 * 
 * @property value The integer value sent to the platform channel
 */
enum class FinishMode(val value: Int) {
    /** Restart playback from the beginning */
    Loop(0), 
    
    /** Pause at the end of the file */
    Pause(1), 
    
    /** Stop playback and release resources */
    Stop(2)
}


/**
 * Callback interface for permission request results
 * 
 * This functional interface is used to notify when a permission request
 * has been processed, providing the result of the permission check.
 */
fun interface RequestPermissionsSuccessCallback {
    /**
     * Called when permission request completes
     * 
     * @param results true if all required permissions were granted, false otherwise
     */
    fun onSuccess(results: Boolean?)
}

/**
 * Defines the possible states of the audio recorder
 *
 * These states allow tracking the recorder's lifecycle and determine
 * which operations are valid at any given time.
 */
enum class RecorderState {
    /** Recorder is initialized and ready to start recording */
    Initialised, 
    
    /** Recorder is actively recording audio */
    Recording, 
    
    /** Recorder has been temporarily paused but can resume */
    Paused, 
    
    /** Recording has been stopped (can't resume, but can start a new recording) */
    Stopped, 
    
    /** Recorder has been disposed and cannot be used anymore */
    Disposed
}

/**
 * Defines the supported audio encoders for recording
 *
 * This enum provides configuration details for various audio encoders,
 * including:
 * - MIME type
 * - Buffer size
 * - Output format
 * - AAC profile (when applicable)
 * - MediaMuxer usage requirements
 *
 * Each encoder has different characteristics in terms of audio quality,
 * file size, and compatibility across platforms.
 */
enum class Encoder {
    /** Uncompressed PCM audio in WAV container */
    WAV, 
    /** AAC Low Complexity profile - good quality/size balance */
    AAC_LC, 
    /** AAC High Efficiency profile - better compression than AAC_LC */
    AAC_HE, 
    /** AAC Enhanced Low Delay - optimized for real-time communication */
    AAC_ELD, 
    /** Adaptive Multi-Rate Narrowband - speech optimized, low bitrate */
    AMR_NB, 
    /** Adaptive Multi-Rate Wideband - better speech quality than AMR_NB */
    AMR_WB, 
    /** Opus codec - versatile audio codec with good compression */
    OPUS;

    /**
     * Gets the MIME type string for this encoder
     * 
     * Used when configuring MediaCodec encoders
     */
    val mimeType: String
        get() = when (this) {
            WAV -> MediaFormat.MIMETYPE_AUDIO_RAW
            AAC_LC, AAC_HE, AAC_ELD -> MediaFormat.MIMETYPE_AUDIO_AAC
            AMR_NB -> MediaFormat.MIMETYPE_AUDIO_AMR_NB
            AMR_WB -> MediaFormat.MIMETYPE_AUDIO_AMR_WB
            OPUS -> MediaFormat.MIMETYPE_AUDIO_OPUS
        }

    /**
     * Gets the recommended buffer size for this encoder
     * 
     * Different encoders work optimally with different buffer sizes.
     * This property returns the recommended size for each encoder type.
     */
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

    /**
     * Gets the appropriate output format for this encoder
     * 
     * Maps each encoder to its corresponding container format in MediaRecorder.
     * For OPUS, uses OGG container format on Android Q and above.
     * 
     * @throws IllegalArgumentException if WAV is selected (uses raw PCM)
     * @throws Exception if OPUS is selected on Android below Q
     */
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

    /**
     * Indicates whether this encoder requires MediaMuxer
     * 
     * Some encoders (AAC, OPUS) require a container format that needs MediaMuxer
     * for proper file creation, while others (WAV, AMR) don't.
     */
    val useMediaMuxer: Boolean
        get() = when (this) {
            WAV, AMR_NB, AMR_WB -> false
            AAC_LC, AAC_HE, AAC_ELD, OPUS -> true
        }

    /**
     * Gets the AAC profile for this encoder if it's an AAC variant
     * 
     * Returns the appropriate MediaCodecInfo profile constant for AAC encoders,
     * or null for non-AAC encoders.
     */
    val aacProfile: Int?
        get() = when (this) {
            AAC_LC -> MediaCodecInfo.CodecProfileLevel.AACObjectLC
            AAC_HE -> MediaCodecInfo.CodecProfileLevel.AACObjectHE
            AAC_ELD -> MediaCodecInfo.CodecProfileLevel.AACObjectELD
            else -> null
        }

    companion object {
        /**
         * Creates an Encoder from a string value
         *
         * Safely converts a string to its corresponding Encoder enum value.
         * Returns AAC_LC as a fallback if the string is null or invalid.
         *
         * @param value The string representation of the encoder
         * @return The matching Encoder, or AAC_LC if invalid
         */
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

    /**
     * Indicates if this encoder uses WAV format
     * 
     * WAV format requires special handling for raw PCM data
     */
    val encodeForWav: Boolean
        get() {
            return this == WAV
        }
        
    /**
     * Indicates if this encoder is an AAC variant
     * 
     * AAC encoders may need ADTS headers when writing raw frames
     */
    val isAAC: Boolean
        get() {
            return this == AAC_LC || this == AAC_HE || this == AAC_ELD
        }
}