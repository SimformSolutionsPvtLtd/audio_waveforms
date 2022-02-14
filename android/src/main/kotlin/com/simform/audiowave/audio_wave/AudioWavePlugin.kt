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


/** AudioWavePlugin */


class AudioWavePlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var recorder: MediaRecorder? = null
    private var activity: Activity? = null
    private lateinit var audioWaveMethodCall: AudioWaveMethodCall
    private var path: String? = null

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
                checkPathAndInitialiseRecorder(result)
            }
            Constants.startRecording -> audioWaveMethodCall.startRecorder(result, recorder)
            Constants.stopRecording -> {
                recorder = null
                audioWaveMethodCall.stopRecording(result, recorder)
            }
            Constants.pauseRecording -> audioWaveMethodCall.pauseRecording(result, recorder)
            Constants.resumeRecording -> audioWaveMethodCall.resumeRecording(result, recorder)
            Constants.getDecibel -> audioWaveMethodCall.getDecibel(result, recorder)
            Constants.checkPermission -> audioWaveMethodCall.checkPermission(result, activity)
            else -> result.notImplemented()
        }
    }

    private fun checkPathAndInitialiseRecorder(result: Result) {
        if (path == null) {
            val outputDir = activity?.cacheDir
            val outputFile: File?
            try {
                outputFile = File.createTempFile("audio-wave", ".mp3", outputDir)
                path = outputFile.path
                try {
                    recorder = MediaRecorder()
                } catch (e: Exception) {
                    Log.e(Constants.LOG_TAG, "Failed to initialise Recorder")
                }

                audioWaveMethodCall.initRecorder(path!!, result, recorder)
            } catch (e: IOException) {
                Log.e(Constants.LOG_TAG, "Failed to create file")
            }
        } else {
            audioWaveMethodCall.initRecorder(path!!, result, recorder)
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
