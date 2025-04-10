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
    /** Stream for writing data to the WAV file */
    private lateinit var outputStream: FileOutputStream
    
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
        isWriting = true
        try {
            outputStream = FileOutputStream(wavFile)
            // These are placeholder bytes for the header which will be updated later.
            val header = ByteArray(44)
            outputStream.write(header)
        } catch (e: Exception) {
            result.error(
                "WAV_FILE_WRITE_ERROR",
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
        if (!isWriting) return
        outputStream.write(pcmData)
        totalAudioLen += pcmData.size
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
            outputStream.close()
            updateWavHeader()
        } catch (e: Exception) {
            result.error(
                "WAV_FILE_CLOSE_ERROR",
                "Error closing WAV file: ${e.message}",
                null
            )
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
        val totalDataLen = totalAudioLen + 36
        val byteRate = sampleRate * Constants.CHANNEL * Constants.BIT_PER_SAMPLE / 8
        val header = ByteArray(44)

        /**
         * Writes a 32-bit integer to the header in little-endian format
         *
         * @param offset Starting position in the header array
         * @param value Integer value to write
         */
        fun writeInt(offset: Int, value: Int) {
            header[offset] = (value and 0xff).toByte()
            header[offset + 1] = ((value shr 8) and 0xff).toByte()
            header[offset + 2] = ((value shr 16) and 0xff).toByte()
            header[offset + 3] = ((value shr 24) and 0xff).toByte()
        }

        /**
         * Writes a 16-bit short to the header in little-endian format
         *
         * @param offset Starting position in the header array
         * @param value Short value to write
         */
        fun writeShort(offset: Int, value: Short) {
            header[offset] = (value.toInt() and 0xff).toByte()
            header[offset + 1] = ((value.toInt() shr 8) and 0xff).toByte()
        }

        // RIFF chunk descriptor
        "RIFF".toByteArray().copyInto(header, 0)        // ChunkID: "RIFF" in ASCII
        writeInt(4, totalDataLen.toInt())                // ChunkSize: total size minus 8 bytes
        "WAVE".toByteArray().copyInto(header, 8)        // Format: "WAVE" in ASCII

        // "fmt " sub-chunk (format information)
        "fmt ".toByteArray().copyInto(header, 12)       // Subchunk1ID: "fmt " in ASCII
        writeInt(16, 16)                                // Subchunk1Size: 16 for PCM format
        writeShort(20, 1)                               // AudioFormat: 1 for PCM (uncompressed)
        writeShort(22, Constants.CHANNEL.toShort())     // NumChannels: Mono=1, Stereo=2
        writeInt(24, sampleRate)                        // SampleRate: samples per second
        writeInt(28, byteRate)                          // ByteRate: bytes per second
        writeShort(32, (Constants.CHANNEL * Constants.BIT_PER_SAMPLE / 8).toShort()) // BlockAlign
        writeShort(34, Constants.BIT_PER_SAMPLE.toShort()) // BitsPerSample: 8, 16, etc.

        // "data" sub-chunk (the actual sound data)
        "data".toByteArray().copyInto(header, 36)       // Subchunk2ID: "data" in ASCII
        writeInt(40, totalAudioLen.toInt())             // Subchunk2Size: size of the audio data

        // Write the completed header back to the beginning of the file
        val raf = RandomAccessFile(wavFile, "rw")
        raf.seek(0)
        raf.write(header)
        raf.close()
    }
}