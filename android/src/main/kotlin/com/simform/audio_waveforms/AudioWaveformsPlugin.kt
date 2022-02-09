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
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.IOException
import java.text.DateFormat.getDateTimeInstance
import java.text.SimpleDateFormat
import java.util.*

/** AudioWaveformsPlugin */
class AudioWaveformsPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var recorder: MediaRecorder? = null
    private var activity: Activity? = null
    private lateinit var audioWaveMethodCall: AudioWaveformsMethodCall
    private var path: String? = null
    private var encoder: Int = 0
    private var outputFormat: Int = 0
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
        const val LOG_TAG = "AudioWaveforms"
        const val methodChannelName = "simform_audio_waveforms_plugin/methods"
        const val encoder = "encoder"
        const val outputFormat = "outputFormat"
        const val sampleRate = "sampleRate"
        const val fileNameFormat = "dd-MM-yy-hh-mm-ss"
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, Constants.methodChannelName)
        channel.setMethodCallHandler(this)
        audioWaveMethodCall = AudioWaveformsMethodCall()
    }

    @RequiresApi(Build.VERSION_CODES.N)
    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            Constants.initRecorder -> {
                path = call.argument(Constants.path) as String?
                encoder = (call.argument(Constants.encoder) as Int?) ?: 0
                outputFormat = (call.argument(Constants.outputFormat) as Int?) ?: 0
                sampleRate = (call.argument(Constants.sampleRate) as Int?) ?: 16000
                checkPathAndInitialiseRecorder(result, encoder, outputFormat, sampleRate)
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
        encoder: Int,
        outputFormat: Int,
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
                    encoder,
                    outputFormat,
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
                encoder,
                outputFormat,
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
