package com.simform.audio_waveforms

import android.annotation.SuppressLint
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import java.io.File
import java.io.FileOutputStream

class Record {
    private var audioRecord: AudioRecord? = null
    private var channelConfig: Int = AudioFormat.CHANNEL_IN_MONO
    private var audioFormat: Int = AudioFormat.ENCODING_PCM_16BIT
    private var bufferSize: Int? = null
    private var fileOutputStream: FileOutputStream? = null
    private var recorderState: RecorderState = RecorderState.Disposed
    private var filePath: String? = null
    private var pcmFilePath: String? = null
    private var recordingThread: Thread? = null
    private var audioEncoder = AudioEncoder()
    private var recorderSettings: RecorderSettings? = null

    @SuppressLint("MissingPermission")
    fun initRecorder(recorderSettings: RecorderSettings) {
        filePath = recorderSettings.path
        if (filePath == null) return
        bufferSize =
            AudioRecord.getMinBufferSize(recorderSettings.sampleRate, channelConfig, audioFormat)

        if (bufferSize == AudioRecord.ERROR || bufferSize == AudioRecord.ERROR_BAD_VALUE) {
            throw IllegalStateException("Invalid buffer size: $bufferSize")
        }
        audioRecord = AudioRecord(
            MediaRecorder.AudioSource.MIC,
            recorderSettings.sampleRate,
            channelConfig,
            audioFormat,
            bufferSize!!
        )


        pcmFilePath = filePath!!.replaceAfterLast(".", "pcm")
        val file = File(pcmFilePath!!)
        file.parentFile?.mkdirs()
        fileOutputStream = FileOutputStream(file)

        this.recorderSettings = recorderSettings
        recorderState = RecorderState.Initialised
    }

    fun start() {
        if (recorderSettings == null || bufferSize == null) return;
        audioRecord?.startRecording()
        recorderState = RecorderState.Recording
        val buffer = ByteArray(bufferSize!!)
        recordingThread = Thread {
            while (recorderState == RecorderState.Recording || recorderState == RecorderState.Paused) {
                if (recorderState == RecorderState.Recording) {
                    val read = audioRecord?.read(buffer, 0, buffer.size) ?: 0
                    if (read > 0) {
                        fileOutputStream?.write(buffer, 0, read)
                    }
                }
            }
            fileOutputStream?.close()
            audioRecord?.stop()
        }
        recordingThread?.start()
    }

    fun stop() {
        recorderState = RecorderState.Stopped
        recordingThread?.interrupt()
        recordingThread?.join()
        filePath?.let {
            if (recorderSettings != null) {
                audioEncoder.encodeByType(
                    pcmFilePath = pcmFilePath!!,
                    outputPath = it,
                    outputFormat = OutputFormat.AAC_ADTS,
                    sampleRate = recorderSettings!!.sampleRate,
                    bitRate = recorderSettings!!.bitRate,
                )
            }
        }

        release()
    }

    fun pause() {
        recorderState = RecorderState.Paused
    }

    fun resume() {
        recorderState = RecorderState.Recording
    }

    fun release() {
        audioRecord?.release()
        audioRecord = null
        recorderState = RecorderState.Disposed
    }
}
