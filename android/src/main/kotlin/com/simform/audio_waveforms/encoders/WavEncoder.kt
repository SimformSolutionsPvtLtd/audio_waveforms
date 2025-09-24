package com.simform.audio_waveforms.encoders

import com.simform.audio_waveforms.Constants
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.RandomAccessFile

/**
 * WavEncoder handles the creation of WAV audio files from raw PCM data.
 * 
 * This class manages the process of writing PCM audio data to a file with the proper
 * WAV file format headers. WAV is an uncompressed audio format that preserves the full
 * quality of the recorded audio but results in larger file sizes compared to
 * compressed formats like AAC or MP3.
 * 
 * The encoder works in three main steps:
 * 1. Start - Creates the file and writes a placeholder header
 * 2. Write - Appends PCM audio data to the file
 * 3. Stop - Updates the header with the final file size and audio parameters
 */
class WavEncoder(
    /** Target file where the WAV audio will be written */
    private val wavFile: File,
    
    /** Sample rate of the audio in Hz (e.g., 44100, 48000) */
    private val sampleRate: Int
) {
    companion object {
        // WAV file format constants
        private const val WAV_HEADER_SIZE = 44
        private const val WAV_CHUNK_SIZE_OFFSET = 36
        private const val BITS_PER_BYTE = 8
        
        // WAV format constants
        private const val PCM_FORMAT_SIZE = 16
        private const val PCM_FORMAT_CODE = 1
        
        // Header field offsets
        private const val CHUNK_ID_OFFSET = 0
        private const val CHUNK_SIZE_OFFSET = 4
        private const val FORMAT_OFFSET = 8
        private const val SUBCHUNK1_ID_OFFSET = 12
        private const val SUBCHUNK1_SIZE_OFFSET = 16
        private const val AUDIO_FORMAT_OFFSET = 20
        private const val NUM_CHANNELS_OFFSET = 22
        private const val SAMPLE_RATE_OFFSET = 24
        private const val BYTE_RATE_OFFSET = 28
        private const val BLOCK_ALIGN_OFFSET = 32
        private const val BITS_PER_SAMPLE_OFFSET = 34
        private const val SUBCHUNK2_ID_OFFSET = 36
        private const val SUBCHUNK2_SIZE_OFFSET = 40
        
        // WAV format identifiers
        private const val RIFF_IDENTIFIER = "RIFF"
        private const val WAVE_IDENTIFIER = "WAVE"
        private const val FMT_IDENTIFIER = "fmt "
        private const val DATA_IDENTIFIER = "data"
        
        // File access modes
        private const val READ_WRITE_MODE = "rw"
        
        // Error codes
        private const val WAV_FILE_WRITE_ERROR = "WAV_FILE_WRITE_ERROR"
        private const val WAV_FILE_CLOSE_ERROR = "WAV_FILE_CLOSE_ERROR"
        
        // Bit manipulation constants
        private const val BYTE_MASK = 0xff
        private const val SHIFT_8_BITS = 8
        private const val SHIFT_16_BITS = 16
        private const val SHIFT_24_BITS = 24
    }
    
    /** Stream for writing data to the WAV file */
    private var outputStream: FileOutputStream? = null
    
    /** Running count of audio data length in bytes */
    private var totalAudioLen = 0L
    
    /** Flag indicating if the encoder is currently active */
    private var isWriting = false

    /**
     * Starts the WAV encoding process
     *
     * Creates a new file with a placeholder WAV header. The header will be
     * updated with the correct values when [stop] is called.
     *
     * @param result Flutter result callback to report success or errors
     */
    fun start(result: MethodChannel.Result) {
        // Clean up any existing stream before starting a new one
        cleanup()
        
        isWriting = true
        try {
            outputStream = FileOutputStream(wavFile)
            // These are placeholder bytes for the header which will be updated later.
            val header = ByteArray(WAV_HEADER_SIZE)
            outputStream?.write(header)
        } catch (e: Exception) {
            // Clean up on failure
            cleanup()
            result.error(
                WAV_FILE_WRITE_ERROR,
                "Error writing to WAV file: ${e.message}",
                null
            )
        }
    }

    /**
     * Writes PCM audio data to the WAV file
     * 
     * Appends raw audio samples to the file and updates the total audio length counter.
     * This method should be called for each chunk of audio data received from the recorder.
     *
     * @param pcmData Array of PCM audio samples to write to the file
     */
    fun writePcmData(pcmData: ByteArray) {
        if (!isWriting || outputStream == null) return
        
        try {
            outputStream?.write(pcmData)
            totalAudioLen += pcmData.size
        } catch (e: Exception) {
            isWriting = false
        }
    }

    /**
     * Stops the encoding process and finalizes the WAV file
     * 
     * This method:
     * 1. Marks the encoder as no longer writing
     * 2. Closes the output stream
     * 3. Updates the WAV header with the final file size and audio parameters
     *
     * @param result Flutter result callback to report success or errors
     */
    fun stop(result: MethodChannel.Result) {
        try {
            isWriting = false
            outputStream?.close()
            updateWavHeader()
        } catch (e: Exception) {
            result.error(
                WAV_FILE_CLOSE_ERROR,
                "Error closing WAV file: ${e.message}",
                null
            )
        } finally {
            // Always clean up resources
            cleanup()
        }
    }

    /**
     * Updates the WAV file header with the final audio parameters
     * 
     * The WAV format requires a specific header structure with information about:
     * - File format (RIFF/WAVE)
     * - Audio format (PCM)
     * - Number of channels
     * - Sample rate
     * - Bit depth
     * - Total data size
     *
     * This method writes all these parameters to the beginning of the file after
     * all audio data has been written and the total size is known.
     */
    private fun updateWavHeader() {
        val totalDataLen = totalAudioLen + WAV_CHUNK_SIZE_OFFSET
        val byteRate = sampleRate * Constants.CHANNEL * Constants.BIT_PER_SAMPLE / BITS_PER_BYTE
        val header = ByteArray(WAV_HEADER_SIZE)

        /**
         * Writes a 32-bit integer to the header in little-endian format
         *
         * @param offset Starting position in the header array
         * @param value Integer value to write
         */
        fun writeInt(offset: Int, value: Int) {
            header[offset] = (value and BYTE_MASK).toByte()
            header[offset + 1] = ((value shr SHIFT_8_BITS) and BYTE_MASK).toByte()
            header[offset + 2] = ((value shr SHIFT_16_BITS) and BYTE_MASK).toByte()
            header[offset + 3] = ((value shr SHIFT_24_BITS) and BYTE_MASK).toByte()
        }

        /**
         * Writes a 16-bit short to the header in little-endian format
         *
         * @param offset Starting position in the header array
         * @param value Short value to write
         */
        fun writeShort(offset: Int, value: Short) {
            header[offset] = (value.toInt() and BYTE_MASK).toByte()
            header[offset + 1] = ((value.toInt() shr SHIFT_8_BITS) and BYTE_MASK).toByte()
        }

        // RIFF chunk descriptor
        RIFF_IDENTIFIER.toByteArray().copyInto(header, CHUNK_ID_OFFSET)        // ChunkID: "RIFF" in ASCII
        writeInt(CHUNK_SIZE_OFFSET, totalDataLen.toInt())                      // ChunkSize: total size minus 8 bytes
        WAVE_IDENTIFIER.toByteArray().copyInto(header, FORMAT_OFFSET)          // Format: "WAVE" in ASCII

        // "fmt " sub-chunk (format information)
        FMT_IDENTIFIER.toByteArray().copyInto(header, SUBCHUNK1_ID_OFFSET)       // Subchunk1ID: "fmt " in ASCII
        writeInt(SUBCHUNK1_SIZE_OFFSET, PCM_FORMAT_SIZE)                         // Subchunk1Size: 16 for PCM format
        writeShort(AUDIO_FORMAT_OFFSET, PCM_FORMAT_CODE.toShort())               // AudioFormat: 1 for PCM (uncompressed)
        writeShort(NUM_CHANNELS_OFFSET, Constants.CHANNEL.toShort())             // NumChannels: Mono=1, Stereo=2
        writeInt(SAMPLE_RATE_OFFSET, sampleRate)                                 // SampleRate: samples per second
        writeInt(BYTE_RATE_OFFSET, byteRate)                                     // ByteRate: bytes per second
        writeShort(BLOCK_ALIGN_OFFSET, (Constants.CHANNEL * Constants.BIT_PER_SAMPLE / BITS_PER_BYTE).toShort()) // BlockAlign
        writeShort(BITS_PER_SAMPLE_OFFSET, Constants.BIT_PER_SAMPLE.toShort())   // BitsPerSample: 8, 16, etc.

        // "data" sub-chunk (the actual sound data)
        DATA_IDENTIFIER.toByteArray().copyInto(header, SUBCHUNK2_ID_OFFSET)       // Subchunk2ID: "data" in ASCII
        writeInt(SUBCHUNK2_SIZE_OFFSET, totalAudioLen.toInt())                    // Subchunk2Size: size of the audio data

        // Write the completed header back to the beginning of the file
        // Use try-with-resources to ensure proper cleanup
        try {
            RandomAccessFile(wavFile, READ_WRITE_MODE).use { raf ->
                raf.seek(CHUNK_ID_OFFSET.toLong())
                raf.write(header)
            }
        } catch (e: Exception) {
            // Re-throw as a more specific exception
            throw RuntimeException("Failed to update WAV header: ${e.message}", e)
        }
    }

    /**
     * Cleans up internal resources and resets state
     * 
     * This method safely closes any open streams and resets internal counters.
     * It's safe to call multiple times and handles null streams gracefully.
     */
    private fun cleanup() {
        try {
            outputStream?.close()
        } catch (e: Exception) {
            // Log but don't throw - cleanup should be safe
        } finally {
            outputStream = null
            totalAudioLen = 0L
            isWriting = false
        }
    }

    /**
     * Releases all resources held by this encoder
     * 
     * Call this method when you're completely done with the encoder
     * to ensure all resources are properly released. After calling this,
     * the encoder should not be used again.
     */
    fun release() {
        cleanup()
    }
}