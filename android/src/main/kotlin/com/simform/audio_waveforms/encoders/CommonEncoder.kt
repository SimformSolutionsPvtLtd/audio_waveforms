package com.simform.audio_waveforms.encoders

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.util.Log
import com.simform.audio_waveforms.Constants
import com.simform.audio_waveforms.Encoder
import com.simform.audio_waveforms.RecorderSettings
import com.simform.audio_waveforms.isEof
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.nio.ByteBuffer
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
    /** MediaCodec instance for encoding audio data */
    private lateinit var mediaCodec: MediaCodec
    
    /** The selected encoder type (AAC_LC, AMR_NB, etc.) */
    private lateinit var encoder: Encoder
    
    /** Background thread for encoder operations */
    private lateinit var handlerThread: HandlerThread
    
    /** Handler for the encoder thread */
    private lateinit var handler: Handler
    
    /** Output stream for writing encoded audio data */
    private lateinit var outputStream: FileOutputStream
    
    /** Configuration for the recorder and encoder */
    private lateinit var recorderSettings: RecorderSettings
    
    /** MediaMuxer instance for container formats (optional) */
    private var mediaMuxer: MediaMuxer? = null

    /** Queue for audio data waiting to be encoded */
    private val inputQueue = LinkedList<ByteArray>()
    
    /** Current available input buffer index (-1 if none available) */
    private var currentInputBufferIndex = -1

    /** Flag indicating if the muxer has been started */
    private var isMuxerStarted = false
    
    /** Flag indicating encoding process should complete */
    private var isEncodingComplete = false
    
    /** Flag indicating encoder has been stopped */
    private var isEncoderStopped = false
    
    /** Track index for the audio track in the muxer */
    private var trackIndex = -1
    
    /** Callback to invoke when encoding is complete, with the error if saving the file failed */
    private var completionCallback: ((Exception?) -> Unit)? = null
    
    /** Total bytes encoded so far, used for calculating presentation timestamps */
    private var totalBytesEncoded = 0L
    
    /** Track the first output timestamp to normalize subsequent timestamps */
    private var firstOutputTimestamp = -1L
    
    /** Track the last valid output timestamp to ensure monotonic increasing */
    private var lastOutputTimestamp = 0L

    /**
     * File encoded into after a resume. A muxed file can't be reopened for
     * appending, so this is appended to the recording once encoding completes.
     */
    private var segmentPath: String? = null

    /**
     * Initializes the MediaCodec encoder with the specified settings
     *
     * @param recorderSettings The configuration for the recorder and encoder
     * @param result The Flutter method channel result to report initialization status
     * @param isResuming Whether to append to the existing recording instead of replacing it
     * @param onEncodingCompleted Optional callback to invoke when encoding is completed
     * @return Whether the encoder was initialized
     */
    fun initCodec(
        recorderSettings: RecorderSettings,
        result: MethodChannel.Result,
        isResuming: Boolean = false,
        onEncodingCompleted: ((Exception?) -> Unit)? = null,
    ): Boolean {
        // Reset state at the beginning
        isMuxerStarted = false
        trackIndex = -1
        isEncodingComplete = false
        isEncoderStopped = false
        inputQueue.clear()
        currentInputBufferIndex = -1
        totalBytesEncoded = 0L
        firstOutputTimestamp = -1L
        lastOutputTimestamp = 0L

        this.recorderSettings = recorderSettings
        encoder = recorderSettings.encoder
        completionCallback = onEncodingCompleted
        var useMediaMuxer = encoder.useMediaMuxer
        var format: MediaFormat
        segmentPath = if (isResuming && useMediaMuxer) "${recorderSettings.path}.resumed" else null
        if (!isResuming) {
            // Left behind if the app was killed while appending a resumed recording.
            File("${recorderSettings.path}.resumed").delete()
            File("${recorderSettings.path}.merged").delete()
        }
        val outputPath = segmentPath ?: recorderSettings.path!!
        try {
            outputStream = FileOutputStream(outputPath, isResuming && !useMediaMuxer)
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

            // A resumed file already starts with its header.
            if (!isResuming) {
                if (encoder == Encoder.AMR_NB) {
                    outputStream.write("#!AMR\n".toByteArray())
                } else if (encoder == Encoder.AMR_WB) {
                    outputStream.write("#!AMR-WB\n".toByteArray())
                }
            }

            if (useMediaMuxer) {
                mediaMuxer = MediaMuxer(outputPath, encoder.toMuxerOutputFormat)
            }
        } catch (e: Exception) {
            result.error(
                Constants.LOG_TAG, "Error initializing encoder: ${e.message}", null
            )
            return false
        }

        mediaCodec.setCallback(object : MediaCodec.Callback() {
            override fun onInputBufferAvailable(codec: MediaCodec, index: Int) {
                if (isEncodingComplete && inputQueue.isEmpty()) {
                    queueEndOfStream(index)
                } else {
                    currentInputBufferIndex = index
                    feedEncoder()
                }
            }

            override fun onOutputBufferAvailable(
                codec: MediaCodec, index: Int, info: MediaCodec.BufferInfo
            ) {
                val buffer = codec.getOutputBuffer(index) ?: return
                
                if (info.isEof()) {
                    codec.releaseOutputBuffer(index, false)
                    stopEncoder()
                    return
                }

                // Normalize output timestamps to start from 0
                if (firstOutputTimestamp == -1L && info.presentationTimeUs > 0) {
                    firstOutputTimestamp = info.presentationTimeUs
                }
                
                // Calculate normalized timestamp (starting from 0)
                val normalizedTimestamp = if (firstOutputTimestamp >= 0) {
                    maxOf(info.presentationTimeUs - firstOutputTimestamp, lastOutputTimestamp)
                } else {
                    info.presentationTimeUs
                }
                
                lastOutputTimestamp = normalizedTimestamp

                if (useMediaMuxer) {
                    if (!isMuxerStarted) {
                        trackIndex = mediaMuxer?.addTrack(mediaCodec.outputFormat) ?: -1
                        mediaMuxer?.start()
                        isMuxerStarted = true
                    }

                    // Ensure buffer is positioned correctly for MediaMuxer
                    buffer.position(info.offset)
                    buffer.limit(info.offset + info.size)
                    
                    // Create a new BufferInfo with normalized timestamp to avoid modifying the original
                    val normalizedInfo = MediaCodec.BufferInfo()
                    normalizedInfo.set(info.offset, info.size, normalizedTimestamp, info.flags)
                    
                    // Write sample data with normalized timestamps
                    mediaMuxer?.writeSampleData(trackIndex, buffer, normalizedInfo)
                } else {
                    // For raw output (AAC/AMR without container), extract the encoded data
                    buffer.position(info.offset)
                    buffer.limit(info.offset + info.size)
                    val encodedData = ByteArray(info.size)
                    buffer.get(encodedData)
                    
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
        return true
    }

    /**
     * Queues the end-of-stream signal on the given input buffer
     *
     * @param index Index of an available input buffer
     */
    private fun queueEndOfStream(index: Int) {
        // Use the last calculated presentation time for EOF, not system time
        val eofTimestamp = if (totalBytesEncoded > 0) {
            val bytesPerSample = 2L
            val channels = 1L
            (totalBytesEncoded * 1_000_000L) / (recorderSettings.sampleRate * channels * bytesPerSample)
        } else {
            0L
        }
        mediaCodec.queueInputBuffer(
            index, 0, 0, eofTimestamp, MediaCodec.BUFFER_FLAG_END_OF_STREAM
        )
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
        synchronized(inputQueue) {
            inputQueue.add(buffer)
        }

        if (currentInputBufferIndex >= 0) {
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
        // An encoder that already stopped, e.g. after an error, won't call back.
        if (isEncoderStopped) {
            completionCallback?.invoke(null)
            return
        }
        isEncodingComplete = true
        // A buffer that is already waiting for data gets no new callback,
        // so the end-of-stream has to be queued on it here.
        synchronized(inputQueue) {
            if (inputQueue.isEmpty() && currentInputBufferIndex >= 0) {
                queueEndOfStream(currentInputBufferIndex)
                currentInputBufferIndex = -1
            }
        }
    }

    /**
     * Sets the callback to be invoked when encoding is completed
     * 
     * @param callback The function to call when encoding completes
     */
    fun setOnEncodingCompleted(callback: (Exception?) -> Unit) {
        completionCallback = callback
    }


    /**
     * Feeds available audio data to the encoder
     * 
     * This method is called when both audio data is available in the queue
     * and an input buffer is available from the encoder. It's synchronized
     * to ensure thread safety when accessing the input queue.
     * 
     * The presentation timestamp is calculated based on the amount of audio data
     * encoded so far, starting from 0. This ensures monotonic timestamps that
     * represent the actual audio timeline for proper playback and looping.
     */
    private fun feedEncoder() {
        synchronized(inputQueue) {
            if (inputQueue.isEmpty() || currentInputBufferIndex < 0) return

            val data = inputQueue.poll() ?: return
            val inputBuffer = mediaCodec.getInputBuffer(currentInputBufferIndex) ?: return
            inputBuffer.clear()
            inputBuffer.put(data)

            // Calculate presentation time based on actual audio data encoded
            // Formula: presentationTimeUs = (totalBytes * 1,000,000) / (sampleRate * channels * bytesPerSample)
            // For 16-bit PCM mono: bytesPerSample = 2, channels = 1
            val bytesPerSample = 2L  // 16-bit = 2 bytes
            val channels = 1L  // Mono
            val presentationTimeUs = (totalBytesEncoded * 1_000_000L) / (recorderSettings.sampleRate * channels * bytesPerSample)
            totalBytesEncoded += data.size
            
            mediaCodec.queueInputBuffer(
                currentInputBufferIndex, 0, data.size, presentationTimeUs, 0
            )
            currentInputBufferIndex = -1
        }
    }

    /**
     * Adds ADTS (Audio Data Transport Stream) header for AAC audio files
     * 
     * AAC raw frames require an ADTS header to be properly recognized by players.
     * This method adds the header when necessary based on the encoder type and file extension.
     */
    private fun addADTSIfAAC() {
        if ((encoder.isAAC && recorderSettings.path!!.endsWith(
                Constants.AAC_FILE_EXTENSION
            ))
        ) {
            outputStream.write(addADTSPacket(encoder.bufferSize, recorderSettings.sampleRate))
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

    /**
     * Stops the encoder and releases all resources
     * 
     * This method is called when encoding is complete or when an error occurs.
     * It:
     * 1. Stops and releases the MediaCodec
     * 2. Stops and releases the MediaMuxer (if used)
     * 3. Closes the output file stream
     * 4. Shuts down the handler thread
     * 5. Calls the completion callback
     * 
     * This method is designed to be idempotent (can be called multiple times safely).
     */
    private fun stopEncoder() {
        if (isEncoderStopped) return
        isEncoderStopped = true

        try {
            mediaCodec.stop()
            mediaCodec.release()
            // A muxer that never received a sample was never started.
            if (isMuxerStarted) mediaMuxer?.stop()
            mediaMuxer?.release()
            outputStream.close()
            handlerThread.quitSafely()
            handlerThread.join()
        } catch (e: Exception) {
            Log.e(Constants.LOG_TAG, "Error stopping encoder: ${e.message}")
        }
        // Pause and stop wait for this, so it runs even if stopping failed.
        val segment = segmentPath
        if (segment != null && isMuxerStarted) {
            appendSegment(segment, completionCallback)
        } else {
            segment?.let { File(it).delete() }
            completionCallback?.invoke(null)
        }

        // Reset state for next recording
        isMuxerStarted = false
        trackIndex = -1
        isEncodingComplete = false
        inputQueue.clear()
        currentInputBufferIndex = -1
        totalBytesEncoded = 0L
        firstOutputTimestamp = -1L
        lastOutputTimestamp = 0L
        segmentPath = null
    }

    /**
     * Appends a segment recorded after a resume to the end of the recording
     *
     * Encoded samples of both files are copied into a new file without
     * re-encoding, which then replaces the recording. Runs on a background
     * thread as the recording can be large. If appending fails, the segment
     * is kept so the resumed audio isn't lost.
     *
     * @param segment Path of the segment to append
     * @param onCompleted Callback invoked on the main thread once done, with
     * the error if appending failed
     */
    private fun appendSegment(segment: String, onCompleted: ((Exception?) -> Unit)?) {
        val path = recorderSettings.path!!
        val muxerFormat = encoder.toMuxerOutputFormat
        Thread {
            val recording = File(path)
            val merged = File("$path.merged")
            var error: Exception? = null
            try {
                if (hasAudioTrack(path)) {
                    val muxer = MediaMuxer(merged.path, muxerFormat)
                    try {
                        copySamples(listOf(path, segment), muxer)
                        muxer.stop()
                    } finally {
                        muxer.release()
                    }
                    if (!merged.renameTo(recording)) {
                        throw IOException("Unable to replace $path with the appended recording")
                    }
                    File(segment).delete()
                } else {
                    // Pausing before any audio was encoded leaves a recording
                    // without audio, so the segment replaces it.
                    if (!File(segment).renameTo(recording)) {
                        throw IOException("Unable to replace $path with the resumed recording")
                    }
                }
            } catch (e: Exception) {
                Log.e(Constants.LOG_TAG, "Error appending resumed recording: ${e.message}")
                merged.delete()
                error = IOException("${e.message}. Resumed audio is kept at $segment", e)
            }
            Handler(Looper.getMainLooper()).post { onCompleted?.invoke(error) }
        }.start()
    }

    /**
     * Checks whether a file has an audio track that can be read
     *
     * @param path Path of the file to check
     * @return Whether the file has a readable audio track
     */
    private fun hasAudioTrack(path: String): Boolean {
        val extractor = MediaExtractor()
        return try {
            extractor.setDataSource(path)
            audioTrackIndex(extractor) >= 0
        } catch (e: Exception) {
            false
        } finally {
            extractor.release()
        }
    }

    /**
     * Writes the encoded samples of each file one after another into [muxer]
     *
     * @param sources Paths of the files to copy, in playback order
     * @param muxer The muxer to write into, started on the first sample track
     */
    private fun copySamples(sources: List<String>, muxer: MediaMuxer) {
        var track = -1
        var offsetUs = 0L
        for (source in sources) {
            val extractor = MediaExtractor()
            try {
                extractor.setDataSource(source)
                val trackIndex = audioTrackIndex(extractor)
                extractor.selectTrack(trackIndex)
                val format = extractor.getTrackFormat(trackIndex)
                if (track == -1) {
                    track = muxer.addTrack(format)
                    muxer.start()
                }
                val buffer = ByteBuffer.allocate(
                    if (format.containsKey(MediaFormat.KEY_MAX_INPUT_SIZE)) {
                        format.getInteger(MediaFormat.KEY_MAX_INPUT_SIZE)
                    } else {
                        DEFAULT_SAMPLE_BUFFER_SIZE
                    }
                )
                val info = MediaCodec.BufferInfo()
                var lastUs = offsetUs
                var frameUs = 0L
                while (true) {
                    val size = extractor.readSampleData(buffer, 0)
                    if (size < 0) break
                    val timeUs = extractor.sampleTime + offsetUs
                    frameUs = timeUs - lastUs
                    lastUs = timeUs
                    info.set(0, size, timeUs, MediaCodec.BUFFER_FLAG_KEY_FRAME)
                    muxer.writeSampleData(track, buffer, info)
                    extractor.advance()
                }
                // Start the next file one frame after the last sample.
                offsetUs = lastUs + frameUs.coerceAtLeast(1)
            } finally {
                extractor.release()
            }
        }
    }

    /**
     * Finds the audio track of a file opened by [extractor]
     *
     * @return Index of the first track with an audio MIME type, or -1 if there is none
     */
    private fun audioTrackIndex(extractor: MediaExtractor): Int {
        return (0 until extractor.trackCount).firstOrNull {
            extractor.getTrackFormat(it).getString(MediaFormat.KEY_MIME)?.startsWith("audio/") == true
        } ?: -1
    }

    private companion object {
        /** Sample buffer size used when the track doesn't report its max sample size */
        const val DEFAULT_SAMPLE_BUFFER_SIZE = 64 * 1024
    }
}