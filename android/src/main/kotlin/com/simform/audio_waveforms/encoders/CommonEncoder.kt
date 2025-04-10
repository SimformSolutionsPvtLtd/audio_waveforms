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

class CommonEncoder {
    private lateinit var mediaCodec: MediaCodec
    private lateinit var encoder: Encoder
    private lateinit var handlerThread: HandlerThread
    private lateinit var handler: Handler
    private lateinit var outputStream: FileOutputStream
    private lateinit var recorderSettings: RecorderSettings
    private var mediaMuxer: MediaMuxer? = null

    private val inputQueue = LinkedList<ByteArray>()
    private var currentInputBufferIndex = -1
    private var isMuxerStarted = false
    private var isEncodingComplete = false
    private var isEncoderStopped = false
    private var trackIndex = -1
    private var completionCallback: (() -> Unit)? = null


    fun initCodec(
        recorderSettings: RecorderSettings,
        result: MethodChannel.Result,
        onEncodingCompleted: (() -> Unit)? = null,
    ) {
        this.recorderSettings = recorderSettings
        encoder = recorderSettings.encoder
        completionCallback = onEncodingCompleted
        var useMediaMuxer = encoder.useMediaMuxer
        var format: MediaFormat
        try {
            outputStream = FileOutputStream(recorderSettings.path!!)
            mediaCodec = MediaCodec.createEncoderByType(encoder.mimeType)

            format = MediaFormat.createAudioFormat(encoder.mimeType, recorderSettings.sampleRate, 1)


            recorderSettings.bitRate.let {
                format.setInteger(MediaFormat.KEY_BIT_RATE, it)
            }
            encoder.aacProfile?.let {
                format.setInteger(
                    MediaFormat.KEY_AAC_PROFILE, it
                )
            }
            format.setInteger(
                MediaFormat.KEY_MAX_INPUT_SIZE, AudioRecord.getMinBufferSize(
                    recorderSettings.sampleRate, Constants.CHANNEL, AudioFormat.ENCODING_PCM_16BIT
                )
            )

            handlerThread = HandlerThread(Constants.ENCODER_THREAD)
            handlerThread.start()
            handler = Handler(handlerThread.looper)

            if (encoder == Encoder.AMR_NB) {
                outputStream.write("#!AMR\n".toByteArray())
            } else if (encoder == Encoder.AMR_WB) {
                outputStream.write("#!AMR-WB\n".toByteArray())
            }

            if (useMediaMuxer) {
                mediaMuxer = MediaMuxer(recorderSettings.path!!, encoder.toOutputFormat)
            }
        } catch (e: Exception) {
            result.error(
                Constants.LOG_TAG, "Error initializing encoder: ${e.message}", null
            )
            return
        }

        mediaCodec.setCallback(object : MediaCodec.Callback() {
            override fun onInputBufferAvailable(codec: MediaCodec, index: Int) {
                if (isEncodingComplete && inputQueue.isEmpty()) {
                    codec.queueInputBuffer(
                        index, 0, 0, System.nanoTime() / 1000, MediaCodec.BUFFER_FLAG_END_OF_STREAM
                    )
                } else {
                    currentInputBufferIndex = index
                    feedEncoder()
                }
            }

            override fun onOutputBufferAvailable(
                codec: MediaCodec, index: Int, info: MediaCodec.BufferInfo
            ) {
                val buffer = codec.getOutputBuffer(index) ?: return
                buffer.rewind()
                val encodedData = ByteArray(info.size)
                buffer.get(encodedData)

                if (info.isEof()) {
                    stopEncoder()
                    return
                }

                if (useMediaMuxer) {
                    if (!isMuxerStarted) {
                        trackIndex = mediaMuxer?.addTrack(mediaCodec.outputFormat) ?: -1
                        mediaMuxer?.start()
                        isMuxerStarted = true
                    }

                    info.set(0, info.size, info.presentationTimeUs, info.flags)
                    mediaMuxer?.writeSampleData(trackIndex, buffer, info)
                } else {
                    addADTSIfAAC()
                    outputStream.write(encodedData)
                }


                codec.releaseOutputBuffer(index, false)
            }

            override fun onError(
                codec: MediaCodec, e: MediaCodec.CodecException
            ) {
                Log.e(
                    Constants.LOG_TAG, "Error while encoding: ${e.message}"
                )
                stopEncoder()
            }

            override fun onOutputFormatChanged(
                codec: MediaCodec, format: MediaFormat
            ) {
                if ((useMediaMuxer) && !isMuxerStarted) {
                    trackIndex = mediaMuxer?.addTrack(format) ?: -1
                    mediaMuxer?.start()
                    isMuxerStarted = true
                }
            }
        })

        mediaCodec.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        mediaCodec.start()
    }

    fun queueInputBuffer(buffer: ByteArray) {
        synchronized(inputQueue) {
            inputQueue.add(buffer)
        }

        if (currentInputBufferIndex >= 0) {
            feedEncoder()
        }
    }

    fun signalToStop() {
        isEncodingComplete = true
    }


    private fun feedEncoder() {
        synchronized(inputQueue) {
            if (inputQueue.isEmpty() || currentInputBufferIndex < 0) return

            val data = inputQueue.poll() ?: return
            val inputBuffer = mediaCodec.getInputBuffer(currentInputBufferIndex) ?: return
            inputBuffer.clear()
            inputBuffer.put(data)

            // TODO()
            val presentationTimeUs = System.nanoTime() / 1000
            mediaCodec.queueInputBuffer(
                currentInputBufferIndex, 0, data.size, presentationTimeUs, 0
            )
            currentInputBufferIndex = -1
        }
    }

    private fun addADTSIfAAC() {
        if ((encoder.isAAC && recorderSettings.path!!.endsWith(
                Constants.AAC_FILE_EXTENSION
            ))
        ) {
            outputStream.write(addADTSPacket(encoder.bufferSize, recorderSettings.sampleRate))
        }
    }

    private fun addADTSPacket(
        dataLength: Int, sampleRate: Int, channelConfig: Int = Constants.CHANNEL
    ): ByteArray {
        val packet = ByteArray(7)
        val profile = when (encoder) {
            Encoder.AAC_LC -> 2
            Encoder.AAC_HE -> 5
            Encoder.AAC_ELD -> 39
            else -> 2
        }
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
            else -> 4
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

    private fun stopEncoder() {
        if (isEncoderStopped) return
        isEncoderStopped = true

        try {
            mediaCodec.stop()
            mediaCodec.release()
            mediaMuxer?.stop()
            mediaMuxer?.release()
            outputStream.close()
            handlerThread.quitSafely()
        } catch (e: Exception) {
            Log.e(Constants.LOG_TAG, "Error stopping encoder: ${e.message}")
        }

        completionCallback?.invoke()
    }
}