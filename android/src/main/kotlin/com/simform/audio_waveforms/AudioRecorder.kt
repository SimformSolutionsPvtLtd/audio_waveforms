package com.simform.audio_waveforms

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaMetadataRetriever
import android.media.MediaMetadataRetriever.METADATA_KEY_DURATION
import android.media.MediaRecorder
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
import com.google.android.exoplayer2.audio.OpusUtil.SAMPLE_RATE
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.DataInputStream
import java.io.DataOutputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileNotFoundException
import java.io.FileOutputStream
import java.io.IOException
import java.lang.Math.abs
import java.lang.Math.log10
import java.nio.ByteBuffer
import java.nio.ByteOrder


private const val LOG_TAG = "AudioWaveforms"
private const val RECORD_AUDIO_REQUEST_CODE = 1001

val CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO
val AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT
val BUFFER_SIZE_RECORDING = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT)

class AudioRecorder : PluginRegistry.RequestPermissionsResultListener {
    private var permissions = arrayOf(Manifest.permission.RECORD_AUDIO)
    private var useLegacyNormalization = false
    private var successCallback: RequestPermissionsSuccessCallback? = null
    var bufferSize = 0
    var nativePath: String = ""
    var tempPath: String = ""
    private var recordingThread: Thread? = null
    private var isRecordingAudio = true
    private lateinit var recorder: AudioRecord
    private var isConvertingDone = true
    var decibleToSend = 0.0
    fun getDecibel(result: MethodChannel.Result, recorder: AudioRecord?) {
        /*if (useLegacyNormalization) {
            val db = 20 * log10(((maxAmplitude?.toDouble() ?: (0.0 / 32768.0))))
            if (db == Double.NEGATIVE_INFINITY) {
                Log.d(LOG_TAG, "Microphone might be turned off")
            } else {
                result.success(db)
            }
        } else {
            result.success(maxAmplitude?.toDouble() ?: 0.0)
        }*/
        //For temporary testing we have used global variable
        result.success(decibleToSend?.toDouble() ?: 0.0)
    }

    fun initRecorder(
        path: String,
        result: MethodChannel.Result,
        //recorder: AudioRecord?,
        encoder: Int,
        outputFormat: Int,
        sampleRate: Int,
        bitRate: Int?
    ): AudioRecord {
        isConvertingDone = false
        /*recorder?.apply {
            setAudioSource(MediaRecorder.AudioSource.MIC)
            setOutputFormat(getOutputFormat(outputFormat))
            setAudioEncoder(getEncoder(encoder))
            setAudioSamplingRate(sampleRate)
            if (bitRate != null) {
                setAudioEncodingBitRate(bitRate)
            }
            setOutputFile(path)
            try {
                recorder.prepare()
                result.success(true)
            } catch (e: IOException) {
                Log.e(LOG_TAG, "Failed to stop initialize recorder")
            }
        }*/
        val file = File(path)
        file.delete()
        file.parentFile.mkdirs()
        tempPath = file.parentFile.path +"tempRecording.m4a";
        nativePath = path;
        Log.e(LOG_TAG, "outputPath:" + file.absolutePath);
        // temporary file of storing recording
        Log.e(LOG_TAG, "tempPath:" + tempPath);
        bufferSize = AudioRecord.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            getEncoder(encoder)
        )
        val minBufferSize = 1792;
        val bufferSize = (sampleRate / 2).coerceAtLeast(minBufferSize)

        Log.e(LOG_TAG, "Buffer Size:" + bufferSize);
        recorder = AudioRecord(
            MediaRecorder.AudioSource.MIC,
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            getEncoder(encoder),
            bufferSize
        )
        try {
            //recorder.prepare()
            result.success(true)
        } catch (e: IOException) {
            Log.e(LOG_TAG, "Failed to stop initialize recorder")
        }
        return recorder;
    }

    fun stopRecording(result: MethodChannel.Result, recorder: AudioRecord?, path: String) {
        try {
            val audioInfoArrayList = ArrayList<String?>()
            isRecordingAudio = false
            recorder?.stop()
            recordingThread = null

            Log.d(LOG_TAG, "Start Converting to WAV")
            rawToWave(File(tempPath), File(path), 16000)
            Log.d(LOG_TAG, "Converted recording to WAV")
            val duration = getDuration(path)
            audioInfoArrayList.add(path)
            audioInfoArrayList.add(duration)
            result.success(audioInfoArrayList)
            Log.e(LOG_TAG, "stop path:" + path);
        } catch (e: IllegalStateException) {
            Log.e(LOG_TAG, "Failed to stop recording")
        }
    }

    private fun getDuration(path: String): String {
        val mediaMetadataRetriever = MediaMetadataRetriever()
        try {
            mediaMetadataRetriever.setDataSource(path)
            val duration = mediaMetadataRetriever.extractMetadata(METADATA_KEY_DURATION)
            return duration ?: "-1"
        } catch (e: Exception) {
            Log.e(LOG_TAG, "Failed to get recording duration")
        } finally {
            mediaMetadataRetriever.release()
        }
        return "-1"
    }

    fun startRecorder(result: MethodChannel.Result, recorder: AudioRecord?, useLegacy: Boolean) {
        try {
            useLegacyNormalization = useLegacy
            Log.i(LOG_TAG, "Starting the audio stream")
            isRecordingAudio = true
            startStreaming()
            result.success(true)
        } catch (e: IllegalStateException) {
            Log.e(LOG_TAG, "Failed to start recording")
        }
    }

    private fun startStreaming() {
        Log.i(
            LOG_TAG,
            "Starting the background thread (in this foreground service) to read the audio data"
        )
        val streamThread = Thread {
            try {
                Log.d(LOG_TAG, "Creating the buffer of size $BUFFER_SIZE_RECORDING")
                var bufferByte: ByteArray
                val sampleRate = 16000
                val bufferSize = (sampleRate / 2).coerceAtLeast(1792/*minBufferSize*/)
                val buffer = ShortArray(bufferSize)
                Log.d(LOG_TAG, "Creating the AudioRecord")
                recorder = AudioRecord(
                    MediaRecorder.AudioSource.MIC,
                    sampleRate,
                    AudioFormat.CHANNEL_IN_MONO,
                    AudioFormat.ENCODING_PCM_16BIT,
                    bufferSize
                )
                Log.d(LOG_TAG, "AudioRecord recording...")
                recorder.startRecording()
                var outputStream: FileOutputStream? = null
                try {
                    outputStream = FileOutputStream(tempPath)
                } catch (e: FileNotFoundException) {
                    //return
                    e.printStackTrace();
                }

                while (isRecordingAudio) {
                    // read the data into the buffer
                    var readBufferShortLength = recorder.read(buffer, 0, buffer.size)
                    Log.d(LOG_TAG, "readBufferShortLength $readBufferShortLength")

                    var maxAmplitude = 0.0
                    for (i in 0 until readBufferShortLength) {
                        if (abs(buffer[i].toInt().toDouble()) > maxAmplitude) {
                            maxAmplitude = abs(buffer[i].toInt().toDouble())
                        }
                    }
                    var db = 0.0
                    if (maxAmplitude != 0.0) {
                        db = 20.0 * Math.log10(maxAmplitude / 32767.0) + 90
                    }
                    decibleToSend = maxAmplitude;
                    Log.d(LOG_TAG, "Max amplitude: $maxAmplitude ; DB: $db")

                    bufferByte = shortToByte(buffer)
                    try {
                        outputStream!!.write(bufferByte, 0, bufferByte.size)
                    } catch (e: IOException) {
                        e.printStackTrace()
                    }
                }
                Log.d(LOG_TAG, "AudioRecord finished recording")
                // clean up file writing operations
                outputStream?.flush()
                outputStream?.close()
            } catch (e: Exception) {
                Log.e(LOG_TAG, "Exception: $e")
            }
        }

        // start the thread
        streamThread.start()
    }

    fun shortToByte(shortArray: ShortArray): ByteArray {
        val buffer = ByteBuffer.allocate(shortArray.size * 2)
        buffer.order(ByteOrder.LITTLE_ENDIAN)
        buffer.asShortBuffer().put(shortArray)
        val bytes = buffer.array()
        return bytes
    }

    @RequiresApi(Build.VERSION_CODES.N)
    fun pauseRecording(result: MethodChannel.Result, recorder: AudioRecord?) {
        try {
            recorder?.stop()
            result.success(false)
        } catch (e: IllegalStateException) {
            Log.e(LOG_TAG, "Failed to pause recording")
        }
    }

    @RequiresApi(Build.VERSION_CODES.N)
    fun resumeRecording(result: MethodChannel.Result, recorder: AudioRecord?) {
        try {
            recorder?.startRecording()
            result.success(true)
        } catch (e: IllegalStateException) {
            Log.e(LOG_TAG, "Failed to resume recording")
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        return if (requestCode == RECORD_AUDIO_REQUEST_CODE) {
            successCallback?.onSuccess(grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED)
            grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
        } else {
            false
        }
    }

    private fun isPermissionGranted(activity: Activity?): Boolean {
        val result =
            ActivityCompat.checkSelfPermission(activity!!, permissions[0])
        return result == PackageManager.PERMISSION_GRANTED
    }

    fun checkPermission(
        result: MethodChannel.Result,
        activity: Activity?,
        successCallback: RequestPermissionsSuccessCallback
    ) {
        this.successCallback = successCallback
        if (!isPermissionGranted(activity)) {
            activity?.let {
                ActivityCompat.requestPermissions(
                    it, permissions,
                    RECORD_AUDIO_REQUEST_CODE
                )
            }
        } else {
            result.success(true)
        }
    }

    private fun getEncoder(encoder: Int): Int {
        when (encoder) {
            Constants.acc -> return MediaRecorder.AudioEncoder.AAC
            Constants.aac_eld -> return MediaRecorder.AudioEncoder.AAC_ELD
            Constants.he_aac -> return MediaRecorder.AudioEncoder.HE_AAC
            Constants.amr_nb -> return MediaRecorder.AudioEncoder.AMR_NB
            Constants.amr_wb -> return MediaRecorder.AudioEncoder.AMR_WB
            Constants.opus -> {
                return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    MediaRecorder.AudioEncoder.OPUS
                } else {
                    Log.e(LOG_TAG, "Minimum android Q is required, Setting Acc encoder.")
                    MediaRecorder.AudioEncoder.AAC
                }
            }
            Constants.vorbis -> return MediaRecorder.AudioEncoder.VORBIS

            else -> return MediaRecorder.AudioEncoder.AAC
        }
    }

    private fun getOutputFormat(format: Int): Int {
        when (format) {
            Constants.mpeg4 -> return MediaRecorder.OutputFormat.MPEG_4
            Constants.three_gpp -> return MediaRecorder.OutputFormat.THREE_GPP
            Constants.ogg -> {
                return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    MediaRecorder.OutputFormat.OGG
                } else {
                    Log.e(LOG_TAG, "Minimum android Q is required, Setting Acc encoder.")
                    MediaRecorder.OutputFormat.MPEG_4
                }
            }

            Constants.amr_wb -> return MediaRecorder.OutputFormat.AMR_WB
            Constants.amr_nb -> return MediaRecorder.OutputFormat.AMR_NB
            Constants.webm ->
                return MediaRecorder.OutputFormat.WEBM
            Constants.mpeg_2_ts -> {
                return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    MediaRecorder.OutputFormat.MPEG_2_TS
                } else {
                    Log.e(LOG_TAG, "Minimum android Q is required, Setting MPEG_4 output format.")
                    MediaRecorder.OutputFormat.MPEG_4
                }
            }
            Constants.aac_adts -> return MediaRecorder.OutputFormat.AAC_ADTS
            else -> return MediaRecorder.OutputFormat.MPEG_4
        }
    }

    @Throws(IOException::class)
    private fun rawToWave(rawFile: File, waveFile: File, sampleRate: Int) {
        val rawData = ByteArray(rawFile.length().toInt())
        var input: DataInputStream? = null
        try {
            input = DataInputStream(FileInputStream(rawFile))
            input.read(rawData)
        } finally {
            input?.close()
        }
        var output: DataOutputStream? = null
        try {
            output = DataOutputStream(FileOutputStream(waveFile))
            // WAVE header
            // see http://ccrma.stanford.edu/courses/422/projects/WaveFormat/
            writeString(output, "RIFF") // chunk id
            writeInt(output, 36 + rawData.size) // chunk size
            writeString(output, "WAVE") // format
            writeString(output, "fmt ") // subchunk 1 id
            writeInt(output, 16) // subchunk 1 size
            writeShort(output, 1.toShort()) // audio format (1 = PCM)
            writeShort(output, 1.toShort()) // number of channels
            writeInt(output, sampleRate) // sample rate
            writeInt(output, sampleRate * 2) // byte rate
            writeShort(output, 2.toShort()) // block align
            writeShort(output, 16.toShort()) // bits per sample
            writeString(output, "data") // subchunk 2 id
            writeInt(output, rawData.size) // subchunk 2 size
            // Audio data (conversion big endian -> little endian)
            val shorts = ShortArray(rawData.size / 2)
            ByteBuffer.wrap(rawData).order(ByteOrder.LITTLE_ENDIAN).asShortBuffer().get(shorts)
            val bytes: ByteBuffer = ByteBuffer.allocate(shorts.size * 2)
            for (s in shorts) {
                bytes.putShort(s)
            }
            output.write(fullyReadFileToBytes(rawFile))
        } finally {
            output?.close()
        }
    }

    @Throws(IOException::class)
    fun fullyReadFileToBytes(f: File): ByteArray? {
        val size = f.length().toInt()
        val bytes = ByteArray(size)
        val tmpBuff = ByteArray(size)
        val fis = FileInputStream(f)
        try {
            var read = fis.read(bytes, 0, size)
            if (read < size) {
                var remain = size - read
                while (remain > 0) {
                    read = fis.read(tmpBuff, 0, remain)
                    System.arraycopy(tmpBuff, 0, bytes, size - remain, read)
                    remain -= read
                }
            }
        } catch (e: IOException) {
            throw e
        } finally {
            fis.close()
        }
        return bytes
    }

    @Throws(IOException::class)
    private fun writeInt(output: DataOutputStream, value: Int) {
        output.write(value shr 0)
        output.write(value shr 8)
        output.write(value shr 16)
        output.write(value shr 24)
    }

    @Throws(IOException::class)
    private fun writeShort(output: DataOutputStream, value: Short) {
        var v = value.toInt()
        output.write(v shr 0)
        output.write(v shr 8)
    }

    @Throws(IOException::class)
    private fun writeString(output: DataOutputStream, value: String) {
        for (element in value) {
            output.write(element.code)
        }
    }
}