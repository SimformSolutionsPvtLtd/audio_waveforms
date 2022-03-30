package com.simform.audio_waveforms

import android.app.Activity
import android.media.MediaRecorder
import android.os.Build
import android.util.Log
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.*


/** AudioWaveformsPlugin */
class AudioWaveformsPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var recorder: MediaRecorder? = null
    private var activity: Activity? = null
    private lateinit var audioWaveMethodCall: AudioRecorder
    private var path: String? = null
    private var codec: Int = 0
    private var sampleRate: Int = 16000

    //Todo: bitrate
    private lateinit var audioPlayer: AudioPlayer

    object Constants {
        const val initRecorder = "initRecorder"
        const val startRecording = "startRecording"
        const val stopRecording = "stopRecording"
        const val pauseRecording = "pauseRecording"
        const val resumeRecording = "resumeRecording"
        const val getDecibel = "getDecibel"
        const val checkPermission = "checkPermission"
        const val path = "path"
        const val LOG_TAG = "AudioWaveforms"
        const val methodChannelName = "simform_audio_waveforms_plugin/methods"
        const val enCoder = "enCoder"
        const val sampleRate = "sampleRate"
        const val fileNameFormat = "dd-MM-yy-hh-mm-ss"
        const val preparePlayer = "preparePlayer"
        const val startPlayer = "startPlayer"
        const val stopPlayer = "stopPlayer"
        const val pausePlayer = "pausePlayer"
        const val seekTo = "seekTo"
        const val progress = "progress"
        const val setVolume = "setVolume"
        const val volume = "volume"
        const val getDuration = "getDuration"
        const val durationType = "durationType"
        const val durationEventChannel = "durationEventChannel"
        const val seekToStart = "seekToStart"
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, Constants.methodChannelName)
        channel.setMethodCallHandler(this)
        audioWaveMethodCall = AudioRecorder()
        audioPlayer = AudioPlayer()
        val eventChannel = EventChannel(
            flutterPluginBinding.binaryMessenger,
            Constants.durationEventChannel
        )
        eventChannel.setStreamHandler(audioPlayer)
    }

    @RequiresApi(Build.VERSION_CODES.N)
    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            Constants.initRecorder -> {
                path = call.argument(Constants.path) as String?
                codec = (call.argument(Constants.enCoder) as Int?) ?: 0
                sampleRate = (call.argument(Constants.sampleRate) as Int?) ?: 16000
                checkPathAndInitialiseRecorder(result, codec, sampleRate)
            }
            Constants.startRecording -> audioWaveMethodCall.startRecorder(result, recorder)
            Constants.stopRecording -> {
                audioWaveMethodCall.stopRecording(result, recorder, path!!)
                recorder = null
            }
            Constants.pauseRecording -> audioWaveMethodCall.pauseRecording(result, recorder)
            Constants.resumeRecording -> audioWaveMethodCall.resumeRecording(result, recorder)
            Constants.getDecibel -> audioWaveMethodCall.getDecibel(result, recorder)
            Constants.checkPermission -> audioWaveMethodCall.checkPermission(result, activity)
            Constants.preparePlayer -> {
                val audioPath = call.argument(Constants.path) as String?
                val volume = call.argument(Constants.volume) as Double?
                audioPlayer.preparePlayer(result, audioPath, volume?.toFloat())
            }
            Constants.startPlayer -> {
                val seekToStart = call.argument(Constants.seekToStart) as Boolean?
                audioPlayer.start(result, seekToStart ?: true)
            }
            Constants.stopPlayer -> audioPlayer.stop(result)
            Constants.pausePlayer -> audioPlayer.pause(result)
            Constants.seekTo -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val progress = call.argument(Constants.progress) as Int?
                    audioPlayer.seekToPosition(result, progress?.toLong())
                } else {
                    Log.e(
                        Constants.LOG_TAG,
                        "Minimum android O is required for seekTo function to works"
                    )
                }
            }
            Constants.setVolume -> {
                val volume = call.argument(Constants.volume) as Float?
                audioPlayer.setVolume(volume, result)
            }
            Constants.getDuration -> {
                val type =
                    if ((call.argument(Constants.durationType) as Int?) == 0) DurationType.Current else DurationType.Max
                audioPlayer.getDuration(result, type)
            }
            else -> result.notImplemented()
        }
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun checkPathAndInitialiseRecorder(
        result: Result,
        enCoder: Int,
        sampleRate: Int
    ) {
        try {
            recorder = MediaRecorder()
        } catch (e: Exception) {
            Log.e(Constants.LOG_TAG, "Failed to initialise Recorder")
        }
        if (path == null) {
            val outputDir = activity?.cacheDir
            val outputFile: File?
            val dateTimeInstance = SimpleDateFormat(Constants.fileNameFormat, Locale.US)
            val currentDate = dateTimeInstance.format(Date())
            try {
                outputFile = File.createTempFile(currentDate, ".aac", outputDir)
                path = outputFile.path
                audioWaveMethodCall.initRecorder(
                    path!!,
                    result,
                    recorder,
                    enCoder,
                    enCoder,
                    sampleRate
                )
            } catch (e: IOException) {
                Log.e(Constants.LOG_TAG, "Failed to create file")
            }
        } else {
            audioWaveMethodCall.initRecorder(
                path!!,
                result,
                recorder,
                enCoder,
                enCoder,
                sampleRate
            )
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        recorder?.release()
        recorder = null
        activity = null
    }
}
