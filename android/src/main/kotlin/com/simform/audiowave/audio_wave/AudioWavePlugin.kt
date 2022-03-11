package com.simform.audiowave.audio_wave

import android.app.Activity
import android.media.MediaRecorder
import android.os.Build
import android.util.Log
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.IOException
import java.text.DateFormat.getDateTimeInstance
import java.util.*


/** AudioWavePlugin */


class AudioWavePlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var recorder: MediaRecorder? = null
    private var activity: Activity? = null
    private lateinit var audioWaveMethodCall: AudioWaveMethodCall
    private var path: String? = null
    private var codec: Int = 0
    private var sampleRate: Int = 16000

    object Constants {
        const val initRecorder = "initRecorder"
        const val startRecording = "startRecording"
        const val stopRecording = "stopRecording"
        const val pauseRecording = "pauseRecording"
        const val resumeRecording = "resumeRecording"
        const val getDecibel = "getDecibel"
        const val checkPermission = "checkPermission"
        const val path = "path"
        const val LOG_TAG = "AudioWave"
        const val methodChannelName = "simform_audio_wave_plugin/methods"
        const val enCoder = "enCoder"
        const val sampleRate = "sampleRate"
        const val fileNameFormat = "dd-MM-yy-hh-mm-ss"
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, Constants.methodChannelName)
        channel.setMethodCallHandler(this)
        audioWaveMethodCall = AudioWaveMethodCall()
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
            else -> result.notImplemented()
        }
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun checkPathAndInitialiseRecorder(
        result: Result,
        enCoder: Int,
        sampleRate: Int
    ) {
        if (path == null) {
            val outputDir = activity?.cacheDir
            val outputFile: File?
            val dateTimeInstance = getDateTimeInstance()
            dateTimeInstance.format(Constants.fileNameFormat)
            val currentDate = dateTimeInstance.format(Date())
            try {
                outputFile = File.createTempFile(currentDate, ".aac", outputDir)
                path = outputFile.path
                try {
                    recorder = MediaRecorder()
                } catch (e: Exception) {
                    Log.e(Constants.LOG_TAG, "Failed to initialise Recorder")
                }

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
