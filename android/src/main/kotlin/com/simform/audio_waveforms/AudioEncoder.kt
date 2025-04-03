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

    var isEncodingComplete = false

    fun convertPCMToEncodedAudio(
        inputPCMPath: String,
        outputPath: String,
        sampleRate: Int,
        bitRate: Int?,
        outputFormat: OutputFormat
    ) {
        val bufferSize = outputFormat.bufferSize
        val mimeType = outputFormat.mimeType
        val mediaCodec = MediaCodec.createEncoderByType(mimeType)
        val format = MediaFormat.createAudioFormat(mimeType, sampleRate, 1)

        bitRate?.let {
            println("Bitrate: $it")
            format.setInteger(MediaFormat.KEY_BIT_RATE, it)
        }

        if (mimeType == MediaFormat.MIMETYPE_AUDIO_AAC) {
            format.setInteger(
                MediaFormat.KEY_AAC_PROFILE,
                MediaCodecInfo.CodecProfileLevel.AACObjectLC
            )
        }

        format.setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, bufferSize)
        mediaCodec.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)

        val inputFile = File(inputPCMPath)
        val inputStream = FileInputStream(inputFile)
        val bufferInfo = MediaCodec.BufferInfo()

        val outputFile = File(outputPath)
        val outputStream = FileOutputStream(outputFile)

        var mediaMuxer: MediaMuxer? = null
        var trackIndex = -1
        var isMuxerStarted = false

        if (outputFormat == OutputFormat.MPEG_4 ||
            outputFormat == OutputFormat.THREE_GPP ||
            outputFormat == OutputFormat.WEBM
        ) {
            mediaMuxer = MediaMuxer(outputPath, outputFormat.toAndroidOutputFormat)
        }

        if (outputFormat == OutputFormat.AMR_NB) {
            outputStream.write("#!AMR\n".toByteArray()) // AMR-NB Header
        } else if (outputFormat == OutputFormat.AMR_WB) {
            outputStream.write("#!AMR-WB\n".toByteArray()) // AMR-WB Header
        }

        val tempBuffer = ByteArray(bufferSize)

        mediaCodec.setCallback(object : MediaCodec.Callback() {
            override fun onInputBufferAvailable(codec: MediaCodec, index: Int) {
                if (isEncodingComplete) return

                val inputBuffer = codec.getInputBuffer(index) ?: return
                inputBuffer.clear()
                val bytesRead = inputStream.read(tempBuffer)

                if (bytesRead > 0) {
                    inputBuffer.put(tempBuffer, 0, bytesRead)
                    codec.queueInputBuffer(index, 0, bytesRead, System.nanoTime() / 1000, 0)
                } else {
                    codec.queueInputBuffer(index, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                    isEncodingComplete = true
                }
            }

            override fun onOutputBufferAvailable(
                codec: MediaCodec,
                index: Int,
                info: MediaCodec.BufferInfo
            ) {
                val outputBuffer = codec.getOutputBuffer(index) ?: return
                outputBuffer.position(0)

                val encodedData = ByteArray(info.size)
                outputBuffer.get(encodedData)

                if (info.isEof()) {
                    stopEncoding(codec, mediaMuxer, outputStream, inputStream)
                    return
                }

                if (outputFormat == OutputFormat.MPEG_4 ||
                    outputFormat == OutputFormat.THREE_GPP ||
                    outputFormat == OutputFormat.WEBM
                ) {
                    if (!isMuxerStarted) {
                        trackIndex = mediaMuxer!!.addTrack(mediaCodec.outputFormat)
                        mediaMuxer.start()
                        isMuxerStarted = true
                    }
                    bufferInfo.set(0, info.size, info.presentationTimeUs, info.flags)
                    mediaMuxer?.writeSampleData(trackIndex, outputBuffer, bufferInfo)
                } else if (outputFormat == OutputFormat.AAC_ADTS) {
                    outputStream.write(addADTSPacket(encodedData.size, sampleRate, 1))
                    outputStream.write(encodedData)
                } else {
                    outputStream.write(encodedData)
                }

                codec.releaseOutputBuffer(index, false)
            }

            override fun onError(codec: MediaCodec, e: MediaCodec.CodecException) {
                println("Encoding error: ${e.message}")
            }

            override fun onOutputFormatChanged(codec: MediaCodec, format: MediaFormat) {
                if ((outputFormat == OutputFormat.MPEG_4 ||
                            outputFormat == OutputFormat.THREE_GPP ||
                            outputFormat == OutputFormat.WEBM) && !isMuxerStarted
                ) {
                    trackIndex = mediaMuxer!!.addTrack(format)
                    mediaMuxer.start()
                    isMuxerStarted = true
                }
            }
        })

        mediaCodec.start()
    }

    private fun stopEncoding(
        codec: MediaCodec,
        mediaMuxer: MediaMuxer?,
        outputStream: FileOutputStream,
        inputStream: FileInputStream
    ) {
        codec.stop()
        codec.release()
        mediaMuxer?.stop()
        mediaMuxer?.release()
        outputStream.close()
        inputStream.close()
        println("Encoding completed successfully!")
    }

    /**
     * **Adds ADTS Header for AAC Files**
     */
    fun addADTSPacket(dataLength: Int, sampleRate: Int, channelConfig: Int): ByteArray {
        val packet = ByteArray(7)
        val profile = 2  // AAC LC
        val frameLength = dataLength + 7

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
            else -> 4 // Default to 44100 Hz
        }

        packet[0] = 0xFF.toByte()
        packet[1] = 0xF9.toByte()
        packet[2] = ((profile - 1 shl 6) + (freqIdx shl 2) + (channelConfig shr 2)).toByte()
        packet[3] = ((channelConfig and 3 shl 6) + (frameLength shr 11)).toByte()
        packet[4] = (frameLength and 0x7FF shr 3).toByte()
        packet[5] = ((frameLength and 7 shl 5) + 0x1F).toByte()
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