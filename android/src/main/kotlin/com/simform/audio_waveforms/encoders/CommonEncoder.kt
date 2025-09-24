package com.simform.audio_waveforms.encoders

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaCodec
import android.media.MediaFormat
import android.media.MediaMuxer
import android.os.Handler
import android.os.HandlerThread
import android.util.Log
import com.simform.audio_waveforms.Constants
import com.simform.audio_waveforms.Encoder
import com.simform.audio_waveforms.RecorderSettings
import com.simform.audio_waveforms.isEof
import io.flutter.plugin.common.MethodChannel
import java.io.FileOutputStream
import java.util.LinkedList

/**
 * CommonEncoder provides a unified interface for audio encoding functionality across
 * multiple encoder types (AMR, AAC, etc.). It handles the complexities of:
 * 
 * - Initializing the appropriate MediaCodec encoder based on the selected encoder type
 * - Managing input and output buffer processing
 * - Handling MediaMuxer operations when required (for container formats like MP4)
 * - Writing encoded audio data to the output file
 * - Adding format-specific headers like ADTS headers for AAC
 * 
 * This class acts as a bridge between raw audio data captured from AudioRecord
 * and the encoded output file ready for playback.
 */
class CommonEncoder {
    companion object {
        // AMR file headers
        private const val AMR_NB_HEADER = "#!AMR\n"
        private const val AMR_WB_HEADER = "#!AMR-WB\n"

        // ADTS header constants
        private const val ADTS_HEADER_SIZE = 7
        private const val ADTS_SYNC_WORD_HIGH = 0xFF.toByte()
        private const val ADTS_SYNC_WORD_LOW = 0xF9.toByte()
        private const val ADTS_FRAME_END = 0xFC.toByte()
        private const val ADTS_FULLNESS = 0x1F

        // AAC profile constants
        private const val AAC_LC_PROFILE = 2
        private const val AAC_HE_PROFILE = 5
        private const val AAC_ELD_PROFILE = 39

        // Error codes
        private const val ENCODER_INIT_ERROR = "ENCODER_INIT_ERROR"
        private const val ENCODER_PROCESSING_ERROR = "ENCODER_PROCESSING_ERROR"

        // Buffer and queue limits
        private const val MAX_INPUT_QUEUE_SIZE = 100
        private const val INVALID_BUFFER_INDEX = -1
        private const val INVALID_TRACK_INDEX = -1
        private const val THREAD_JOIN_TIMEOUT_MS = 1000L

        // Bit manipulation constants
        private const val BITS_PER_BYTE = 8
        private const val CHANNEL_CONFIG_SHIFT = 2
        private const val FRAME_LENGTH_SHIFT_11 = 11
        private const val FRAME_LENGTH_SHIFT_3 = 3
        private const val FRAME_LENGTH_MASK_7 = 7
        private const val FRAME_LENGTH_SHIFT_5 = 5
        private const val PROFILE_SHIFT_6 = 6
        private const val FREQ_SHIFT_2 = 2
        private const val CHANNEL_SHIFT_6 = 6
        private const val CHANNEL_MASK_3 = 3
        private const val FREQUENCY_MASK_0x7FF = 0x7FF
    }

    // Encoder state enum for better state management
    private enum class EncoderState {
        UNINITIALIZED,
        INITIALIZING,
        INITIALIZED,
        STARTED,
        STOPPING,
        STOPPED,
        ERROR
    }

    @Volatile
    private var encoderState = EncoderState.UNINITIALIZED

    /** MediaCodec instance for encoding audio data */
    private var mediaCodec: MediaCodec? = null
    
    /** The selected encoder type (AAC_LC, AMR_NB, etc.) */
    private var encoder: Encoder? = null
    
    /** Background thread for encoder operations */
    private var handlerThread: HandlerThread? = null
    
    /** Handler for the encoder thread */
    private var handler: Handler? = null
    
    /** Output stream for writing encoded audio data */
    private var outputStream: FileOutputStream? = null
    
    /** Configuration for the recorder and encoder */
    private var recorderSettings: RecorderSettings? = null
    
    /** MediaMuxer instance for container formats (optional) */
    private var mediaMuxer: MediaMuxer? = null

    /** Queue for audio data waiting to be encoded - thread-safe implementation */
    private val inputQueue = LinkedList<ByteArray>()
    private val inputQueueLock = Any()

    /** Current available input buffer index */
    @Volatile
    private var currentInputBufferIndex = INVALID_BUFFER_INDEX
    
    /** Flag indicating if the muxer has been started */
    @Volatile
    private var isMuxerStarted = false
    
    /** Flag indicating encoding process should complete */
    @Volatile
    private var isEncodingComplete = false
    
    /** Flag indicating encoder has been stopped */
    @Volatile
    private var isEncoderStopped = false
    
    /** Track index for the audio track in the muxer */
    @Volatile
    private var trackIndex = INVALID_TRACK_INDEX
    
    /** Callback to invoke when encoding is complete */
    private var completionCallback: (() -> Unit)? = null

    /**
     * Initializes the MediaCodec encoder with the specified settings
     *
     * @param recorderSettings The configuration for the recorder and encoder
     * @param result The Flutter method channel result to report initialization status
     * @param onEncodingCompleted Optional callback to invoke when encoding is completed
     */
    fun initCodec(
        recorderSettings: RecorderSettings,
        result: MethodChannel.Result,
        onEncodingCompleted: (() -> Unit)? = null,
    ) {
        // Validate state
        if (encoderState != EncoderState.UNINITIALIZED) {
            result.error(
                ENCODER_INIT_ERROR,
                "Encoder is already initialized. Call release() first.",
                null
            )
            return
        }

        // Validate input parameters
        val path = recorderSettings.path
        if (path.isNullOrBlank()) {
            result.error(
                ENCODER_INIT_ERROR,
                "Output path cannot be null or empty",
                null
            )
            return
        }

        if (recorderSettings.sampleRate <= 0) {
            result.error(
                ENCODER_INIT_ERROR,
                "Sample rate must be positive",
                null
            )
            return
        }

        encoderState = EncoderState.INITIALIZING

        try {
            this.recorderSettings = recorderSettings
            encoder = recorderSettings.encoder
            completionCallback = onEncodingCompleted

            // Initialize components with proper error handling
            initializeOutputStream(path)
            initializeMediaCodec()
            initializeHandlerThread()
            writeFormatHeaders()
            initializeMediaMuxer()

            // Configure and start MediaCodec
            configureMediaCodec()
            mediaCodec?.start()
            encoderState = EncoderState.STARTED

        } catch (e: Exception) {
            encoderState = EncoderState.ERROR
            cleanup()
            result.error(
                ENCODER_INIT_ERROR,
                "Error initializing encoder: ${e.message}",
                null
            )
        }
    }

    /**
     * Initializes the output stream for writing encoded data
     */
    private fun initializeOutputStream(path: String) {
        outputStream = FileOutputStream(path)
    }

    /**
     * Initializes the MediaCodec encoder
     */
    private fun initializeMediaCodec() {
        val encoderType = encoder ?: throw IllegalStateException("Encoder type not set")
        mediaCodec = MediaCodec.createEncoderByType(encoderType.mimeType)
    }

    /**
     * Initializes the handler thread for background operations
     */
    private fun initializeHandlerThread() {
        handlerThread = HandlerThread(Constants.ENCODER_THREAD).apply {
            start()
        }
        handler = Handler(handlerThread!!.looper)
    }

    /**
     * Writes format-specific headers (AMR headers)
     */
    private fun writeFormatHeaders() {
        val encoderType = encoder ?: return
        val stream = outputStream ?: return

        when (encoderType) {
            Encoder.AMR_NB -> stream.write(AMR_NB_HEADER.toByteArray())
            Encoder.AMR_WB -> stream.write(AMR_WB_HEADER.toByteArray())
            else -> { /* No header needed for other formats */
            }
        }
    }

    /**
     * Initializes MediaMuxer if required by the encoder
     */
    private fun initializeMediaMuxer() {
        val settings = recorderSettings ?: return
        val encoderType = encoder ?: return

        if (encoderType.useMediaMuxer) {
            mediaMuxer = MediaMuxer(settings.path!!, encoderType.toOutputFormat)
        }
    }

    /**
     * Configures the MediaCodec with format parameters
     */
    private fun configureMediaCodec() {
        val settings =
            recorderSettings ?: throw IllegalStateException("RecorderSettings not initialized")
        val encoderType = encoder ?: throw IllegalStateException("Encoder type not set")
        val codec = mediaCodec ?: throw IllegalStateException("MediaCodec not initialized")

        val format = MediaFormat.createAudioFormat(
            encoderType.mimeType,
            settings.sampleRate,
            Constants.CHANNEL
        )

        // Set bit rate
        format.setInteger(MediaFormat.KEY_BIT_RATE, settings.bitRate)

        // Set AAC profile if applicable
        encoderType.aacProfile?.let { profile ->
            format.setInteger(MediaFormat.KEY_AAC_PROFILE, profile)
        }

        // Set max input size
        format.setInteger(
            MediaFormat.KEY_MAX_INPUT_SIZE,
            AudioRecord.getMinBufferSize(
                settings.sampleRate,
                Constants.CHANNEL,
                AudioFormat.ENCODING_PCM_16BIT
            )
        )

        // Set MediaCodec callback
        codec.setCallback(createMediaCodecCallback())

        // Configure the codec
        codec.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)

    }

    /**
     * Creates the MediaCodec callback with proper error handling
     */
    private fun createMediaCodecCallback() = object : MediaCodec.Callback() {
        override fun onInputBufferAvailable(codec: MediaCodec, index: Int) {
            try {
                if (isEncodingComplete && isInputQueueEmpty()) {
                    codec.queueInputBuffer(
                        index, 0, 0,
                        System.nanoTime() / 1000,
                        MediaCodec.BUFFER_FLAG_END_OF_STREAM
                    )
                } else {
                    currentInputBufferIndex = index
                    feedEncoder()
                }
            } catch (e: Exception) {
                Log.e(Constants.LOG_TAG, "Error in onInputBufferAvailable: ${e.message}")
                handleEncoderError()
            }
        }

        override fun onOutputBufferAvailable(
            codec: MediaCodec, index: Int, info: MediaCodec.BufferInfo
        ) {
            try {
                val buffer = codec.getOutputBuffer(index) ?: return
                buffer.rewind()
                val encodedData = ByteArray(info.size)
                buffer.get(encodedData)

                if (info.isEof()) {
                    stopEncoder()
                    return
                }

                val encoderType = encoder
                val useMediaMuxer = encoderType?.useMediaMuxer ?: false

                if (useMediaMuxer) {
                    handleMuxerOutput(buffer, info, codec)
                } else {
                    handleDirectOutput(encodedData)
                }

                codec.releaseOutputBuffer(index, false)
            } catch (e: Exception) {
                Log.e(Constants.LOG_TAG, "Error in onOutputBufferAvailable: ${e.message}")
                handleEncoderError()
            }
        }

        override fun onError(codec: MediaCodec, e: MediaCodec.CodecException) {
            Log.e(Constants.LOG_TAG, "MediaCodec error: ${e.message}")
            handleEncoderError()
        }

        override fun onOutputFormatChanged(codec: MediaCodec, format: MediaFormat) {
            try {
                val encoderType = encoder
                val useMediaMuxer = encoderType?.useMediaMuxer ?: false

                if (useMediaMuxer && !isMuxerStarted) {
                    startMuxer(format)
                }
            } catch (e: Exception) {
                Log.e(Constants.LOG_TAG, "Error in onOutputFormatChanged: ${e.message}")
                handleEncoderError()
            }
        }
    }

    /**
     * Handles muxer output for container formats
     */
    private fun handleMuxerOutput(
        buffer: java.nio.ByteBuffer,
        info: MediaCodec.BufferInfo,
        codec: MediaCodec
    ) {
        val muxer = mediaMuxer ?: return

        if (!isMuxerStarted) {
            startMuxer(codec.outputFormat)
        }

        info.set(0, info.size, info.presentationTimeUs, info.flags)
        muxer.writeSampleData(trackIndex, buffer, info)
    }

    /**
     * Handles direct output to file
     */
    private fun handleDirectOutput(encodedData: ByteArray) {
        val stream = outputStream ?: return

        addADTSIfAAC()
        stream.write(encodedData)
    }

    /**
     * Starts the MediaMuxer with the given format
     */
    private fun startMuxer(format: MediaFormat) {
        val muxer = mediaMuxer ?: return

        synchronized(this) {
            if (!isMuxerStarted) {
                trackIndex = muxer.addTrack(format)
                muxer.start()
                isMuxerStarted = true
            }
        }
    }

    /**
     * Checks if input queue is empty in a thread-safe manner
     */
    private fun isInputQueueEmpty(): Boolean {
        synchronized(inputQueueLock) {
            return inputQueue.isEmpty()
        }
    }

    /**
     * Handles encoder errors by transitioning to error state and cleaning up
     */
    private fun handleEncoderError() {
        encoderState = EncoderState.ERROR
        stopEncoder()
    }

    /**
     * Queues audio data for encoding
     * 
     * This method safely adds audio data to the input queue and attempts to feed
     * it to the encoder if an input buffer is available. Thread-safe.
     *
     * @param buffer The raw audio data to encode
     */
    fun queueInputBuffer(buffer: ByteArray) {
        if (encoderState != EncoderState.STARTED) return

        synchronized(inputQueueLock) {
            // Prevent unbounded queue growth
            if (inputQueue.size >= MAX_INPUT_QUEUE_SIZE) {
                Log.w(Constants.LOG_TAG, "Input queue is full, dropping audio data")
                return
            }
            inputQueue.add(buffer)
        }

        if (currentInputBufferIndex != INVALID_BUFFER_INDEX) {
            feedEncoder()
        }
    }

    /**
     * Signals that no more audio data will be provided
     * 
     * This method marks the encoding process as complete. Once all queued data
     * is processed, the encoder will be sent an end-of-stream signal.
     */
    fun signalToStop() {
        encoderState = EncoderState.STOPPING
        isEncodingComplete = true
    }

    /**
     * Sets the callback to be invoked when encoding is completed
     * 
     * @param callback The function to call when encoding completes
     */
    fun setOnEncodingCompleted(callback: () -> Unit) {
        completionCallback = callback
    }


    /**
     * Feeds available audio data to the encoder
     * 
     * This method is called when both audio data is available in the queue
     * and an input buffer is available from the encoder. It's synchronized
     * to ensure thread safety when accessing the input queue.
     */
    private fun feedEncoder() {
        synchronized(inputQueueLock) {
            if (inputQueue.isEmpty() || currentInputBufferIndex == INVALID_BUFFER_INDEX) return

            val data = inputQueue.poll() ?: return
            val codec = mediaCodec ?: return
            val inputBuffer = codec.getInputBuffer(currentInputBufferIndex) ?: return

            inputBuffer.clear()
            inputBuffer.put(data)

            // Use more accurate presentation time
            val presentationTimeUs = System.nanoTime() / 1000
            codec.queueInputBuffer(
                currentInputBufferIndex, 0, data.size, presentationTimeUs, 0
            )
            currentInputBufferIndex = INVALID_BUFFER_INDEX
        }
    }

    /**
     * Adds ADTS (Audio Data Transport Stream) header for AAC audio files
     * 
     * AAC raw frames require an ADTS header to be properly recognized by players.
     * This method adds the header when necessary based on the encoder type and file extension.
     */
    private fun addADTSIfAAC() {
        val encoderType = encoder ?: return
        val settings = recorderSettings ?: return
        val stream = outputStream ?: return
        val path = settings.path ?: return

        if (encoderType.isAAC && path.endsWith(Constants.AAC_FILE_EXTENSION)) {
            stream.write(addADTSPacket(encoderType.bufferSize, settings.sampleRate))
        }
    }

    /**
     * Creates an ADTS header packet for AAC audio data
     *
     * @param dataLength The length of the AAC frame data
     * @param sampleRate The sample rate of the audio in Hz
     * @param channelConfig The channel configuration (mono/stereo)
     * @return The ADTS header as a byte array
     */
    private fun addADTSPacket(
        dataLength: Int,
        sampleRate: Int,
        channelConfig: Int = Constants.CHANNEL
    ): ByteArray {
        val packet = ByteArray(ADTS_HEADER_SIZE)
        val encoderType = encoder ?: return packet

        val profile = when (encoderType) {
            Encoder.AAC_LC -> AAC_LC_PROFILE
            Encoder.AAC_HE -> AAC_HE_PROFILE
            Encoder.AAC_ELD -> AAC_ELD_PROFILE
            else -> AAC_LC_PROFILE
        }

        val frameLength = dataLength + ADTS_HEADER_SIZE

        val freqIdx = when (sampleRate) {
            96000 -> 0
            88200 -> 1
            64000 -> 2
            48000 -> 3
            44100 -> 4
            32000 -> 5
            24000 -> 6
            22050 -> 7
            16000 -> 8
            12000 -> 9
            11025 -> 10
            8000 -> 11
            7350 -> 12
            else -> 4
        }

        packet[0] = ADTS_SYNC_WORD_HIGH
        packet[1] = ADTS_SYNC_WORD_LOW
        packet[2] = ((profile - 1 shl PROFILE_SHIFT_6) +
                (freqIdx shl FREQ_SHIFT_2) +
                (channelConfig shr CHANNEL_CONFIG_SHIFT)).toByte()
        packet[3] = ((channelConfig and CHANNEL_MASK_3 shl CHANNEL_SHIFT_6) +
                (frameLength shr FRAME_LENGTH_SHIFT_11)).toByte()
        packet[4] = (frameLength and FREQUENCY_MASK_0x7FF shr FRAME_LENGTH_SHIFT_3).toByte()
        packet[5] = ((frameLength and FRAME_LENGTH_MASK_7 shl FRAME_LENGTH_SHIFT_5) +
                ADTS_FULLNESS).toByte()
        packet[6] = ADTS_FRAME_END

        return packet
    }

    /**
     * Stops the encoder and releases all resources
     * 
     * This method is called when encoding is complete or when an error occurs.
     * It ensures all resources are properly cleaned up and calls the completion callback.
     * This method is designed to be idempotent (can be called multiple times safely).
     */
    private fun stopEncoder() {
        if (encoderState == EncoderState.STOPPED || isEncoderStopped) return

        synchronized(this) {
            if (isEncoderStopped) return
            isEncoderStopped = true
            encoderState = EncoderState.STOPPED
        }

        cleanup()

        // Invoke completion callback on a separate thread to avoid blocking
        completionCallback?.let { callback ->
            handler?.post { callback() } ?: callback()
        }
    }

    /**
     * Cleans up all resources safely
     */
    private fun cleanup() {
        try {
            // Stop and release MediaCodec
            mediaCodec?.let { codec ->
                try {
                    codec.stop()
                } catch (e: Exception) {
                    Log.w(Constants.LOG_TAG, "Error stopping MediaCodec: ${e.message}")
                }
                try {
                    codec.release()
                } catch (e: Exception) {
                    Log.w(Constants.LOG_TAG, "Error releasing MediaCodec: ${e.message}")
                }
            }

            // Stop and release MediaMuxer
            mediaMuxer?.let { muxer ->
                try {
                    if (isMuxerStarted) {
                        muxer.stop()
                    }
                } catch (e: Exception) {
                    Log.w(Constants.LOG_TAG, "Error stopping MediaMuxer: ${e.message}")
                }
                try {
                    muxer.release()
                } catch (e: Exception) {
                    Log.w(Constants.LOG_TAG, "Error releasing MediaMuxer: ${e.message}")
                }
            }

            // Close output stream
            outputStream?.let { stream ->
                try {
                    stream.flush()
                    stream.close()
                } catch (e: Exception) {
                    Log.w(Constants.LOG_TAG, "Error closing output stream: ${e.message}")
                }
            }

            // Shutdown handler thread
            handlerThread?.let { thread ->
                try {
                    thread.quitSafely()
                    thread.join(THREAD_JOIN_TIMEOUT_MS) // Wait up to 1 second for clean shutdown
                } catch (e: Exception) {
                    Log.w(Constants.LOG_TAG, "Error shutting down handler thread: ${e.message}")
                }
            }

        } finally {
            // Reset all references
            mediaCodec = null
            mediaMuxer = null
            outputStream = null
            handlerThread = null
            handler = null
            completionCallback = null

            // Clear input queue
            synchronized(inputQueueLock) {
                inputQueue.clear()
            }

            // Reset state
            isMuxerStarted = false
            currentInputBufferIndex = INVALID_BUFFER_INDEX
            trackIndex = INVALID_TRACK_INDEX
        }
    }

    /**
     * Public method to release all resources
     *
     * Call this method when completely done with the encoder to ensure
     * proper cleanup of all resources.
     */
    fun release() {
        encoderState = EncoderState.STOPPED
        cleanup()
    }
}
