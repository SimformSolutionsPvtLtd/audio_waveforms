package com.simform.audio_waveforms

import android.content.Context
import android.media.AudioFormat
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.net.Uri
import android.os.Build
import io.flutter.plugin.common.MethodChannel
import java.nio.ByteBuffer
import java.util.concurrent.CountDownLatch
import kotlin.math.pow
import kotlin.math.sqrt

class WaveformExtractor(
    private val path: String,
    private val expectedPoints: Int,
    private val key: String,
    private val methodChannel: MethodChannel,
    private val result: MethodChannel.Result,
    private val extractorCallBack: ExtractorCallBack,
    private val context: Context,
) {
    private var decoder: MediaCodec? = null
    private var extractor: MediaExtractor? = null
    private var duration = 0L
    private var progress = 0F
    private var currentProgress = 0F

    @Volatile
    private var started = false
    private val finishCount = CountDownLatch(1)
    private var inputEof = false
    private var sampleRate = 0
    private var channels = 1
    private var pcmEncodingBit = 16
    private var totalSamples = 0L
    private var perSamplePoints = 0L

    private fun getFormat(path: String): MediaFormat? {
        val mediaExtractor = MediaExtractor()
        this.extractor = mediaExtractor
        val uri = Uri.parse(path)
        mediaExtractor.setDataSource(context, uri, null)
        val trackCount = mediaExtractor.trackCount
        repeat(trackCount) {
            val format = mediaExtractor.getTrackFormat(it)
            val mime = format.getString(MediaFormat.KEY_MIME) ?: ""
            if (mime.contains("audio")) {
                duration = format.getLong(MediaFormat.KEY_DURATION) / 1000000
                mediaExtractor.selectTrack(it)
                return format
            }
        }
        return null
    }

    fun startDecode() {
        try {
            val format = getFormat(path) ?: error("No audio format found")
            val mime = format.getString(MediaFormat.KEY_MIME) ?: error("No MIME type found")
            decoder = MediaCodec.createDecoderByType(mime).also {
                it.configure(format, null, null, 0)
                it.setCallback(object : MediaCodec.Callback() {
                    override fun onInputBufferAvailable(codec: MediaCodec, index: Int) {
                        if (inputEof) return
                        val extractor = extractor ?: return
                        codec.getInputBuffer(index)?.let { buf ->
                            val size = extractor.readSampleData(buf, 0)
                            if (size > 0) {
                                codec.queueInputBuffer(index, 0, size, extractor.sampleTime, 0)
                                extractor.advance()
                            } else {
                                codec.queueInputBuffer(
                                    index,
                                    0,
                                    0,
                                    0,
                                    MediaCodec.BUFFER_FLAG_END_OF_STREAM
                                )
                                inputEof = true
                            }
                        }
                    }

                    override fun onOutputFormatChanged(codec: MediaCodec, format: MediaFormat) {
                        sampleRate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                        channels = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                        pcmEncodingBit = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                            if (format.containsKey(MediaFormat.KEY_PCM_ENCODING)) {
                                when (format.getInteger(MediaFormat.KEY_PCM_ENCODING)) {
                                    AudioFormat.ENCODING_PCM_16BIT -> 16
                                    AudioFormat.ENCODING_PCM_8BIT -> 8
                                    AudioFormat.ENCODING_PCM_FLOAT -> 32
                                    else -> 16
                                }
                            } else {
                                16
                            }
                        } else {
                            16
                        }
                        totalSamples = sampleRate.toLong() * duration
                        perSamplePoints = totalSamples / expectedPoints
                    }

                    override fun onError(codec: MediaCodec, e: MediaCodec.CodecException) {
                        result.error(
                            Constants.LOG_TAG,
                            e.message,
                            "An error is thrown while decoding the audio file"
                        )
                        finishCount.countDown()
                    }

                    override fun onOutputBufferAvailable(
                        codec: MediaCodec,
                        index: Int,
                        info: MediaCodec.BufferInfo
                    ) {
                        if (info.size > 0) {
                            codec.getOutputBuffer(index)?.let { buf ->
                                val size = info.size
                                buf.position(info.offset)
                                when (pcmEncodingBit) {
                                    8 -> {
                                        handle8bit(size, buf)
                                    }
                                    16 -> {
                                        handle16bit(size, buf)
                                    }
                                    32 -> {
                                        handle32bit(size, buf)
                                    }
                                }
                                codec.releaseOutputBuffer(index, false)
                            }
                        }

                        if (info.isEof()) {
                            stop()
                        }
                    }

                })
                it.start()
            }

        } catch (e: Exception) {
            result.error(
                Constants.LOG_TAG,
                e.message,
                "An error is thrown before decoding the audio file"
            )
        }


    }

    var sampleData = ArrayList<Float>()
    private var sampleCount = 0L
    private var sampleSum = 0.0

    private fun rms(value: Float) {
        if (sampleCount == perSamplePoints) {
            currentProgress++
            progress = currentProgress / expectedPoints

            // Discard redundant values and release resources
            if (progress > 1.0F) {
                stop()
                return
            }

            val rms = sqrt(sampleSum / perSamplePoints)
            sampleData.add(rms.toFloat())
            extractorCallBack.onProgress(progress)
            sampleCount = 0
            sampleSum = 0.0

            val args: MutableMap<String, Any?> = HashMap()
            args[Constants.waveformData] = sampleData
            args[Constants.progress] = progress
            args[Constants.playerKey] = key
            methodChannel.invokeMethod(
                Constants.onCurrentExtractedWaveformData,
                args
            )
        }

        sampleCount++
        sampleSum += value.toDouble().pow(2.0)
    }

    private fun handle8bit(size: Int, buf: ByteBuffer) {
        repeat(size / if (channels == 2) 2 else 1) {
            val result = buf.get().toInt() / 128f
            if (channels == 2) {
                buf.get()
            }
            rms(result)
        }
    }

    private fun handle16bit(size: Int, buf: ByteBuffer) {
        repeat(size / if (channels == 2) 4 else 2) {
            val first = buf.get().toInt()
            val second = buf.get().toInt() shl 8
            val value = (first or second) / 32767f
            if (channels == 2) {
                buf.get()
                buf.get()
            }
            rms(value)
        }
    }

    private fun handle32bit(size: Int, buf: ByteBuffer) {
        repeat(size / if (channels == 2) 8 else 4) {
            val first = buf.get().toLong()
            val second = buf.get().toLong() shl 8
            val third = buf.get().toLong() shl 16
            val forth = buf.get().toLong() shl 24
            val value = (first or second or third or forth) / 2147483648f
            if (channels == 2) {
                buf.get()
                buf.get()
                buf.get()
                buf.get()
            }
            rms(value)
        }
    }

    fun stop() {
        if (!started) return
        started = false
        decoder?.stop()
        decoder?.release()
        extractor?.release()
        finishCount.countDown()
    }
}

fun MediaCodec.BufferInfo.isEof() = flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0

interface ExtractorCallBack {
    fun onProgress(value: Float)
}