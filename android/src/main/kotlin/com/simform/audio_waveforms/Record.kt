package com.simform.audio_waveforms

import android.annotation.SuppressLint
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import java.io.File
import java.io.FileOutputStream

class Record {
    private var audioRecord: AudioRecord? = null
    private var sampleRate = 44100 // Standard sample rate
    private var channelConfig: Int = AudioFormat.CHANNEL_IN_MONO
    private var audioFormat: Int = AudioFormat.ENCODING_PCM_16BIT
    private var bufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)
    private var fileOutputStream: FileOutputStream? = null
    private var recorderState: RecorderState = RecorderState.Disposed
    private var filePath: String? = null
    private var recordingThread: Thread? = null

    @SuppressLint("MissingPermission")
    fun initRecorder(path: String) {
        audioRecord = AudioRecord(
            MediaRecorder.AudioSource.MIC,
            sampleRate,
            channelConfig,
            audioFormat,
            bufferSize
        )

        filePath = path
        val file = File(path)
        file.parentFile?.mkdirs()
        fileOutputStream = FileOutputStream(file)

        recorderState = RecorderState.Initialised
    }

    fun start() {
        audioRecord?.startRecording()
        recorderState = RecorderState.Recording
        val buffer = ByteArray(bufferSize)
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
        recordingThread?.join()
//        filePath?.let {
////            val wavPath = it.replace("pcm", "wav")
////            AudioEncoder().convertPcmToWav(it, wavPath, sampleRate, 1, 64000)
//            val accPath = it.replace("pcm", "m4a")
//            AudioEncoder().convertPCMToM4A(it, accPath, bufferSize)
//        }

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
