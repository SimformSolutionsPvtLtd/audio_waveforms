package com.simform.audio_waveforms

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaCodecList
import android.media.MediaFormat
import android.media.MediaMuxer
import android.media.MediaRecorder
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream

class AudioEncoder {

    fun encodeByType(
        outputPath: String,
        pcmFilePath: String,
        outputFormat: OutputFormat,
        sampleRate: Int,
        bitRate: Int?
    ) {
        if (outputFormat == OutputFormat.WAV) {
            convertPcmToWav(
                pcmFilePath,
                outputPath,
                sampleRate,
            )
        } else {
            convertPCMToEncodedAudio(
                pcmFilePath,
                outputPath,
                sampleRate,
                bitRate,
                outputFormat
            )
        }
//        deletePCMFile(pcmFilePath)
    }

    private fun convertPcmToWav(
        pcmFilePath: String,
        wavFilePath: String,
        sampleRate: Int,
    ) {
        val pcmFile = File(pcmFilePath)
        val wavFile = File(wavFilePath)

        val pcmData = pcmFile.readBytes()
        val wavOutputStream = FileOutputStream(wavFile)

        // WAV Header
        val header = ByteArray(44)

        val totalAudioLen = pcmData.size.toLong()
        val totalDataLen = totalAudioLen + 36
        val byteRate = sampleRate * Constants.CHANNEL * Constants.BIT_PER_SAMPLE / 8

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
        writeShort(22, Constants.CHANNEL.toShort())
        writeInt(24, sampleRate)
        writeInt(28, byteRate)
        writeShort(32, (Constants.CHANNEL * Constants.BIT_PER_SAMPLE / 8).toShort())
        writeShort(34, Constants.BIT_PER_SAMPLE.toShort())

        // data chunk
        "data".toByteArray().copyInto(header, 36)
        writeInt(40, totalAudioLen.toInt())

        // Write header + data
        wavOutputStream.write(header)
        wavOutputStream.write(pcmData)
        wavOutputStream.close()
    }

    fun convertPCMToM4A(
        inputPCMPath: String,
        outputM4APath: String,
        bufferSize: Int,
        sampleRate: Int
    ) {
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
            mediaCodec.queueInputBuffer(
                inputBufferIndex,
                0,
                0,
                0,
                MediaCodec.BUFFER_FLAG_END_OF_STREAM
            )
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

    fun convertPCMToEncodedAudio(
        inputPCMPath: String,
        outputPath: String,
        sampleRate: Int,
        bitRate: Int?,
        outputFormat: OutputFormat
    ) {
        val bufferSize = outputFormat.bufferSize
        val mimeType = outputFormat.mimeType
        val outputFormat = outputFormat
        val mediaCodec = MediaCodec.createEncoderByType(mimeType)
        val format = MediaFormat.createAudioFormat(mimeType, sampleRate, 1)
        if (bitRate != null) {
            format.setInteger(MediaFormat.KEY_BIT_RATE, bitRate)
        }

        if (mimeType == MediaFormat.MIMETYPE_AUDIO_AAC) {
            format.setInteger(
                MediaFormat.KEY_AAC_PROFILE,
                MediaCodecInfo.CodecProfileLevel.AACObjectLC
            )
        }
        format.setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, bufferSize)
        mediaCodec.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        mediaCodec.start()

        val inputFile = File(inputPCMPath)
        val inputStream = FileInputStream(inputFile)
        val bufferInfo = MediaCodec.BufferInfo()

        val outputFile = File(outputPath)
        val outputStream = FileOutputStream(outputFile)

        var mediaMuxer: MediaMuxer? = null
        var trackIndex = -1
        var isMuxerStarted = false

        // **Initialize MediaMuxer for MP4, 3GP, WebM**
        if (outputFormat == OutputFormat.MPEG_4 ||
            outputFormat == OutputFormat.THREE_GPP ||
            outputFormat == OutputFormat.WEBM
        ) {
            mediaMuxer = MediaMuxer(outputPath, outputFormat.toAndroidOutputFormat)
        }

        // **Add file headers for AMR or AAC_ADTS**
        if (outputFormat == OutputFormat.AMR_NB) {
            outputStream.write("#!AMR\n".toByteArray()) // AMR-NB Header
        } else if (outputFormat == OutputFormat.AMR_WB) {
            outputStream.write("#!AMR-WB\n".toByteArray()) // AMR-WB Header
        }

        val tempBuffer = ByteArray(bufferSize)
        var bytesRead: Int

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
                val encodedData = ByteArray(bufferInfo.size)
                outputBuffer.get(encodedData)

                if (outputFormat == OutputFormat.MPEG_4 ||
                    outputFormat == OutputFormat.THREE_GPP ||
                    outputFormat == OutputFormat.WEBM
                ) {
                    // **Write to MediaMuxer**
                    if (!isMuxerStarted) {
                        trackIndex = mediaMuxer!!.addTrack(mediaCodec.outputFormat)
                        mediaMuxer.start()
                        isMuxerStarted = true
                    }
                    bufferInfo.presentationTimeUs = System.nanoTime() / 1000
                    mediaMuxer?.writeSampleData(trackIndex, outputBuffer, bufferInfo)
                } else if (outputFormat == OutputFormat.AAC_ADTS) {
                    // **Write ADTS Header + Data for AAC**
                    outputStream.write(addADTSPacket(encodedData.size))
                    outputStream.write(encodedData)
                } else {
                    // **Write raw encoded data (AMR)**
                    outputStream.write(encodedData)
                }

                mediaCodec.releaseOutputBuffer(outputBufferIndex, false)
                outputBufferIndex = mediaCodec.dequeueOutputBuffer(bufferInfo, 10000)
            }
        }

        // **Send End-of-Stream signal**
        val inputBufferIndex = mediaCodec.dequeueInputBuffer(10000)
        if (inputBufferIndex >= 0) {
            mediaCodec.queueInputBuffer(
                inputBufferIndex,
                0,
                0,
                0,
                MediaCodec.BUFFER_FLAG_END_OF_STREAM
            )
        }

        // **Process remaining output**
        var outputBufferIndex = mediaCodec.dequeueOutputBuffer(bufferInfo, 10000)
        while (outputBufferIndex >= 0) {
            val outputBuffer = mediaCodec.getOutputBuffer(outputBufferIndex) ?: continue
            val encodedData = ByteArray(bufferInfo.size)
            outputBuffer.get(encodedData)

            if (outputFormat == OutputFormat.MPEG_4 ||
                outputFormat == OutputFormat.THREE_GPP ||
                outputFormat == OutputFormat.WEBM
            ) {
                bufferInfo.presentationTimeUs = System.nanoTime() / 1000
                mediaMuxer?.writeSampleData(trackIndex, outputBuffer, bufferInfo)
            } else if (outputFormat == OutputFormat.AAC_ADTS) {
                outputStream.write(addADTSPacket(encodedData.size))
                outputStream.write(encodedData)
            } else {
                outputStream.write(encodedData)
            }

            mediaCodec.releaseOutputBuffer(outputBufferIndex, false)
            outputBufferIndex = mediaCodec.dequeueOutputBuffer(bufferInfo, 10000)
        }

        mediaCodec.stop()
        mediaCodec.release()
        mediaMuxer?.stop()
        mediaMuxer?.release()
        outputStream.close()
        inputStream.close()
    }

    /**
     * **Adds ADTS Header for AAC Files**
     */
    fun addADTSPacket(dataLength: Int): ByteArray {
        val packet = ByteArray(7)
        val profile = 2  // AAC LC
        val freqIdx = 4  // 44100 Hz
        val chanCfg = 1  // Mono

        packet[0] = 0xFF.toByte()
        packet[1] = 0xF1.toByte()
        packet[2] = ((profile - 1) shl 6 or (freqIdx shl 2) or (chanCfg shr 2)).toByte()
        packet[3] = ((chanCfg and 3) shl 6 or (dataLength shr 11)).toByte()
        packet[4] = (dataLength shr 3).toByte()
        packet[5] = ((dataLength and 7) shl 5 or 0x1F).toByte()
        packet[6] = 0xFC.toByte()

        return packet
    }

    private fun deletePCMFile(pcmFilePath: String) {
        val file = File(pcmFilePath)
        if (file.exists()) {
            file.delete()
        }
    }
}