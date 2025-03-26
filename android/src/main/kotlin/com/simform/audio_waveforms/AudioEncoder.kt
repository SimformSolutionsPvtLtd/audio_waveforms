package com.simform.audio_waveforms

import android.media.AudioRecord
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.nio.ByteBuffer

class AudioEncoder {

    private val sampleRate: Int = 44100
    fun convertPcmToWav(
        pcmFilePath: String,
        wavFilePath: String,
        sampleRate: Int,
        channels: Int,
        bitsPerSample: Int
    ) {
        val pcmFile = File(pcmFilePath)
        val wavFile = File(wavFilePath)

        val pcmData = pcmFile.readBytes()
        val wavOutputStream = FileOutputStream(wavFile)

        // WAV Header
        val header = ByteArray(44)

        val totalAudioLen = pcmData.size.toLong()
        val totalDataLen = totalAudioLen + 36
        val byteRate = sampleRate * channels * bitsPerSample / 8

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

        // RIFF Header
        "RIFF".toByteArray().copyInto(header, 0)
        writeInt(4, totalDataLen.toInt())
        "WAVE".toByteArray().copyInto(header, 8)

        // fmt chunk
        "fmt ".toByteArray().copyInto(header, 12)
        writeInt(16, 16) // Subchunk size
        writeShort(20, 1) // Audio format (1 = PCM)
        writeShort(22, channels.toShort())
        writeInt(24, sampleRate)
        writeInt(28, byteRate)
        writeShort(32, (channels * bitsPerSample / 8).toShort())
        writeShort(34, bitsPerSample.toShort())

        // data chunk
        "data".toByteArray().copyInto(header, 36)
        writeInt(40, totalAudioLen.toInt())

        // Write header + data
        wavOutputStream.write(header)
        wavOutputStream.write(pcmData)
        wavOutputStream.close()
    }

    fun convertPCMToM4A(inputPCMPath: String, outputM4APath: String, bufferSize: Int) {
        val mediaCodec = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC)
        val format = MediaFormat.createAudioFormat(MediaFormat.MIMETYPE_AUDIO_AAC, sampleRate, 1)
        format.setInteger(MediaFormat.KEY_BIT_RATE, 128000)
        format.setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC)
        format.setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, bufferSize)

        mediaCodec.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        mediaCodec.start()

        val mediaMuxer = MediaMuxer(outputM4APath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)

        val inputFile = File(inputPCMPath)
        val inputStream = FileInputStream(inputFile)
        val bufferInfo = MediaCodec.BufferInfo()

        var isMuxerStarted = false
        var trackIndex = -1
        val tempBuffer = ByteArray(bufferSize)

        var bytesRead: Int

        // Read until the end of the file
        while (inputStream.read(tempBuffer).also { bytesRead = it } != -1) {
            val inputBufferIndex = mediaCodec.dequeueInputBuffer(10000)
            if (inputBufferIndex >= 0) {
                val inputBuffer = mediaCodec.getInputBuffer(inputBufferIndex)
                inputBuffer?.clear()
                inputBuffer?.put(tempBuffer, 0, bytesRead)

                mediaCodec.queueInputBuffer(
                    inputBufferIndex,
                    0,
                    bytesRead,
                    System.nanoTime() / 1000,
                    0
                )
            }

            var outputBufferIndex = mediaCodec.dequeueOutputBuffer(bufferInfo, 10000)
            while (outputBufferIndex >= 0) {
                val outputBuffer = mediaCodec.getOutputBuffer(outputBufferIndex) ?: continue

                if (!isMuxerStarted) {
                    val outputFormat = mediaCodec.outputFormat
                    trackIndex = mediaMuxer.addTrack(outputFormat)
                    mediaMuxer.start()
                    isMuxerStarted = true
                }

                bufferInfo.presentationTimeUs = System.nanoTime() / 1000
                mediaMuxer.writeSampleData(trackIndex, outputBuffer, bufferInfo)
                mediaCodec.releaseOutputBuffer(outputBufferIndex, false)

                outputBufferIndex = mediaCodec.dequeueOutputBuffer(bufferInfo, 10000)
            }
        }

        // Send end-of-stream signal
        val inputBufferIndex = mediaCodec.dequeueInputBuffer(10000)
        if (inputBufferIndex >= 0) {
            mediaCodec.queueInputBuffer(inputBufferIndex, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
        }

        // Process remaining output buffers
        var outputBufferIndex = mediaCodec.dequeueOutputBuffer(bufferInfo, 10000)
        while (outputBufferIndex >= 0) {
            val outputBuffer = mediaCodec.getOutputBuffer(outputBufferIndex) ?: continue
            bufferInfo.presentationTimeUs = System.nanoTime() / 1000
            mediaMuxer.writeSampleData(trackIndex, outputBuffer, bufferInfo)
            mediaCodec.releaseOutputBuffer(outputBufferIndex, false)
            outputBufferIndex = mediaCodec.dequeueOutputBuffer(bufferInfo, 10000)
        }

        mediaCodec.stop()
        mediaCodec.release()
        mediaMuxer.stop()
        mediaMuxer.release()
        inputStream.close()
    }
}