package com.simform.audio_waveforms

import android.app.Activity
import android.content.Context
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
import io.flutter.plugin.common.PluginRegistry.Registrar
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
    private var sampleRate: Int = 44100
    private var bitRate: Int? = null
    private lateinit var applicationContext: Context
    private var audioPlayers = mutableMapOf<String, AudioPlayer?>()
    private var extractors = mutableMapOf<String, WaveformExtractor?>()
    private var pluginBinding: ActivityPluginBinding? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, Constants.methodChannelName)
        channel.setMethodCallHandler(this)
        audioRecorder = AudioRecorder()
        applicationContext = flutterPluginBinding.applicationContext
    }

    @RequiresApi(Build.VERSION_CODES.N)
    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            Constants.initRecorder -> {
                path = call.argument(Constants.path) as String?
                encoder = (call.argument(Constants.encoder) as Int?) ?: 0
                outputFormat = (call.argument(Constants.outputFormat) as Int?) ?: 0
                sampleRate = (call.argument(Constants.sampleRate) as Int?) ?: 44100
                bitRate = (call.argument(Constants.bitRate) as Int?)
                checkPathAndInitialiseRecorder(result, encoder, outputFormat, sampleRate, bitRate)
            }
            Constants.startRecording -> {
                val useLegacyNormalization =
                    (call.argument(Constants.useLegacyNormalization) as Boolean?) ?: false
                audioRecorder.startRecorder(result, recorder, useLegacyNormalization)
            }
            Constants.stopRecording -> {
                audioRecorder.stopRecording(result, recorder, path!!)
                recorder = null
            }
            Constants.pauseRecording -> audioRecorder.pauseRecording(result, recorder)
            Constants.resumeRecording -> audioRecorder.resumeRecording(result, recorder)
            Constants.getDecibel -> audioRecorder.getDecibel(result, recorder)
            Constants.checkPermission -> audioRecorder.checkPermission(result, activity, result :: success)
            Constants.preparePlayer -> {
                val audioPath = call.argument(Constants.path) as String?
                val volume = call.argument(Constants.volume) as Double?
                val key = call.argument(Constants.playerKey) as String?
                val frequency = call.argument(Constants.updateFrequency) as Int?
                if (key != null) {
                    initPlayer(key)
                    audioPlayers[key]?.preparePlayer(
                        result,
                        audioPath,
                        volume?.toFloat(),
                        getUpdateFrequency(frequency),
                    )
                } else {
                    result.error(Constants.LOG_TAG, "Player key can't be null", "")
                }

            }
            Constants.startPlayer -> {
                val finishMode = call.argument(Constants.finishMode) as Int?
                val key = call.argument(Constants.playerKey) as String?
                if (key != null) {
                    audioPlayers[key]?.start(
                        result,
                        finishMode ?: 2
                    )
                } else {
                    result.error(Constants.LOG_TAG, "Player key can't be null", "")
                }
            }
            Constants.stopPlayer -> {
                val key = call.argument(Constants.playerKey) as String?
                if (key != null) {
                    audioPlayers[key]?.stop(result)
                } else {
                    result.error(Constants.LOG_TAG, "Player key can't be null", "")
                }
            }
            Constants.pausePlayer -> {
                val key = call.argument(Constants.playerKey) as String?
                if (key != null) {
                    audioPlayers[key]?.pause(result)
                } else {
                    result.error(Constants.LOG_TAG, "Player key can't be null", "")
                }
            }
            Constants.releasePlayer -> {
                val key = call.argument(Constants.playerKey) as String?
                audioPlayers[key]?.release(result)
            }
            Constants.seekTo -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val progress = call.argument(Constants.progress) as Int?
                    val key = call.argument(Constants.playerKey) as String?
                    if (key != null) {
                        audioPlayers[key]?.seekToPosition(result, progress?.toLong())
                    } else {
                        result.error(Constants.LOG_TAG, "Player key can't be null", "")
                    }
                } else {
                    Log.e(
                        Constants.LOG_TAG,
                        "Minimum android O is required for seekTo function to works"
                    )
                }
            }
            Constants.setVolume -> {
                val volume = call.argument(Constants.volume) as Double?
                val key = call.argument(Constants.playerKey) as String?
                if (key != null) {
                    audioPlayers[key]?.setVolume(volume?.toFloat(), result)
                } else {
                    result.error(Constants.LOG_TAG, "Player key can't be null", "")
                }
            }
            Constants.getDuration -> {
                val type =
                    if ((call.argument(Constants.durationType) as Int?) == 0) DurationType.Current else DurationType.Max
                val key = call.argument(Constants.playerKey) as String?
                if (key != null) {
                    audioPlayers[key]?.getDuration(result, type)
                } else {
                    result.error(Constants.LOG_TAG, "Player key can't be null", "")
                }
            }
            Constants.extractWaveformData -> {
                val key = call.argument(Constants.playerKey) as String?
                val path = call.argument(Constants.path) as String?
                val noOfSample = call.argument(Constants.noOfSamples) as Int?
                if (key != null) {
                    createOrUpdateExtractor(
                        playerKey = key,
                        result = result,
                        path = path,
                        noOfSamples = noOfSample ?: 100,
                    )
                } else {
                    result.error(Constants.LOG_TAG, "Player key can't be null", "")
                }
            }
            Constants.stopAllPlayers -> {
                for ((key, _) in audioPlayers) {
                    audioPlayers[key]?.stop(result)
                    audioPlayers[key] = null
                }
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun checkPathAndInitialiseRecorder(
        result: Result,
        encoder: Int,
        outputFormat: Int,
        sampleRate: Int,
        bitRate: Int?
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
                outputFile = File.createTempFile(currentDate, ".m4a", outputDir)
                path = outputFile.path
                audioRecorder.initRecorder(
                    path!!,
                    result,
                    recorder,
                    encoder,
                    outputFormat,
                    sampleRate,
                    bitRate
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
                sampleRate,
                bitRate
            )
        }
    }

    private fun initPlayer(playerKey: String) {
        if (audioPlayers[playerKey] == null) {
            val newPlayer = AudioPlayer(
                context = applicationContext,
                channel = channel,
                playerKey = playerKey,
            )
            audioPlayers[playerKey] = newPlayer
        }
        return
    }

    private fun getUpdateFrequency(frequency: Int?): UpdateFrequency {
        if (frequency == 2) {
            return UpdateFrequency.High
        } else if (frequency == 1) {
            return UpdateFrequency.Medium
        }
        return UpdateFrequency.Low
    }

    private fun createOrUpdateExtractor(
        playerKey: String,
        noOfSamples: Int,
        path: String?,
        result: Result,
    ) {
        if (path == null) {
            result.error(Constants.LOG_TAG, "Path cant be null", "")
            return
        }
        extractors[playerKey] = WaveformExtractor(
            context = applicationContext,
            methodChannel = channel,
            expectedPoints = noOfSamples,
            key = playerKey,
            path = path,
            result = result,
            extractorCallBack = object : ExtractorCallBack {
                override fun onProgress(value: Float) {
                    if (value == 1.0F) {
                        result.success(extractors[playerKey]?.sampleData)
                    }
                }

            }
        )
        extractors[playerKey]?.startDecode()
        extractors[playerKey]?.stop()
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        pluginBinding = binding
        pluginBinding!!.addRequestPermissionsResultListener(this.audioRecorder)

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
        audioPlayers.clear()
        extractors.clear()
        activity = null
        if (pluginBinding != null) {
            pluginBinding!!.removeRequestPermissionsResultListener(this.audioRecorder)
        }
    }
}
