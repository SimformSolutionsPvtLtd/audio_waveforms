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
import java.text.SimpleDateFormat
import java.util.*


/** AudioWaveformsPlugin */
class AudioWaveformsPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var recorder: MediaRecorder? = null
    private var activity: Activity? = null
    private lateinit var audioRecorder: AudioRecorder
    private var path: String? = null
    private var encoder: Int = 0
    private var outputFormat: Int = 0
    private var sampleRate: Int = 16000

    //Todo: bitrate
    private lateinit var audioPlayer: AudioPlayer

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, Constants.methodChannelName)
        channel.setMethodCallHandler(this)
        audioRecorder = AudioRecorder()
        audioPlayer = AudioPlayer(flutterPluginBinding.applicationContext, channel)

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
            Constants.startRecording -> audioRecorder.startRecorder(result, recorder)
            Constants.stopRecording -> {
                audioRecorder.stopRecording(result, recorder, path!!)
                recorder = null
            }
            Constants.pauseRecording -> audioRecorder.pauseRecording(result, recorder)
            Constants.resumeRecording -> audioRecorder.resumeRecording(result, recorder)
            Constants.getDecibel -> audioRecorder.getDecibel(result, recorder)
            Constants.checkPermission -> audioRecorder.checkPermission(result, activity)
            Constants.preparePlayer -> {
                val audioPath = call.argument(Constants.path) as String?
                val volume = call.argument(Constants.volume) as Double?
                val key = call.argument(Constants.playerKey) as String?
                audioPlayer.preparePlayer(result, audioPath, volume?.toFloat(), key)
            }
            Constants.startPlayer -> {
                val seekToStart = call.argument(Constants.seekToStart) as Boolean?
                val key = call.argument(Constants.playerKey) as String?
                audioPlayer.start(result, seekToStart ?: true, key)
            }
            Constants.stopPlayer -> {
                val key = call.argument(Constants.playerKey) as String?
                audioPlayer.stop(result, key)
            }
            Constants.pausePlayer -> {
                val key = call.argument(Constants.playerKey) as String?
                audioPlayer.pause(result, key)
            }
            Constants.seekTo -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val progress = call.argument(Constants.progress) as Int?
                    val key = call.argument(Constants.playerKey) as String?
                    audioPlayer.seekToPosition(result, progress?.toLong(), key)
                } else {
                    Log.e(
                        Constants.LOG_TAG,
                        "Minimum android O is required for seekTo function to works"
                    )
                }
            }
            Constants.setVolume -> {
                val volume = call.argument(Constants.volume) as Float?
                val key = call.argument(Constants.playerKey) as String?
                audioPlayer.setVolume(volume, result, key)
            }
            Constants.getDuration -> {
                val type =
                    if ((call.argument(Constants.durationType) as Int?) == 0) DurationType.Current else DurationType.Max
                val key = call.argument(Constants.playerKey) as String?
                audioPlayer.getDuration(result, type, key)
            }
            Constants.stopAllPlayers -> audioPlayer.stopAllPlayers(result)
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
                audioRecorder.initRecorder(
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
            audioRecorder.initRecorder(
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
