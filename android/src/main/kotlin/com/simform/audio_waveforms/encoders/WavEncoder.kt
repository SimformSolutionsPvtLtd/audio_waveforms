package com.simform.audio_waveforms.encoders

import com.simform.audio_waveforms.Constants
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.RandomAccessFile

class WavEncoder(
    private val wavFile: File,
    private val sampleRate: Int
) {
    private lateinit var outputStream: FileOutputStream
    private var totalAudioLen = 0L
    private var isWriting = false

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

    fun writePcmData(pcmData: ByteArray) {
        if (!isWriting) return
        outputStream.write(pcmData)
        totalAudioLen += pcmData.size
    }

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

    private fun updateWavHeader() {
        val totalDataLen = totalAudioLen + 36
        val byteRate = sampleRate * Constants.CHANNEL * Constants.BIT_PER_SAMPLE / 8
        val header = ByteArray(44)

        fun writeInt(offset: Int, value: Int) {
            header[offset] = (value and 0xff).toByte()
            header[offset + 1] = ((value shr 8) and 0xff).toByte()
            header[offset + 2] = ((value shr 16) and 0xff).toByte()
            header[offset + 3] = ((value shr 24) and 0xff).toByte()
        }

        fun writeShort(offset: Int, value: Short) {
            header[offset] = (value.toInt() and 0xff).toByte()
            header[offset + 1] = ((value.toInt() shr 8) and 0xff).toByte()
        }

        "RIFF".toByteArray().copyInto(header, 0)
        writeInt(4, totalDataLen.toInt())
        "WAVE".toByteArray().copyInto(header, 8)

        "fmt ".toByteArray().copyInto(header, 12)
        writeInt(16, 16) // Subchunk 1Size for PCM
        writeShort(20, 1) // AudioFormat PCM
        writeShort(22, Constants.CHANNEL.toShort())
        writeInt(24, sampleRate)
        writeInt(28, byteRate)
        writeShort(32, (Constants.CHANNEL * Constants.BIT_PER_SAMPLE / 8).toShort())
        writeShort(34, Constants.BIT_PER_SAMPLE.toShort())

        "data".toByteArray().copyInto(header, 36)
        writeInt(40, totalAudioLen.toInt())

        val raf = RandomAccessFile(wavFile, "rw")
        raf.seek(0)
        raf.write(header)
        raf.close()
    }
}