import Flutter
import UIKit

public class SwiftAudioWaveformsPlugin: NSObject, FlutterPlugin {
    
    final var audioWaveformsMethodCall = AudioRecorder()
    let audioPlayer = AudioPlayer.sharedInstance
    
    struct Constants {
        static let methodChannelName = "simform_audio_waveforms_plugin/methods"
        static let startRecording = "startRecording"
        static let pauseRecording = "pauseRecording"
        static let stopRecording = "stopRecording"
        static let getDecibel = "getDecibel"
        static let checkPermission = "checkPermission"
        static let path = "path"
        static let encoder = "encoder"
        static let sampleRate = "sampleRate"
        static let fileNameFormat = "YY-MM-dd-HH-mm-ss"
        static let readAudioFile = "readAudioFile"
        static let durationEventChannel = "durationEventChannel"
        static let startPlayer = "startPlayer"
        static let stopPlayer = "stopPlayer"
        static let pausePlayer = "pausePlayer"
        static let seekTo = "seekTo"
        static let progress = "progress"
        static let setVolume = "setVolume"
        static let volume = "volume"
        static let getDuration = "getDuration"
        static let durationType = "durationType"
        static let preparePlayer = "preparePlayer"
        static let seekToStart = "seekToStart"
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: Constants.methodChannelName, binaryMessenger: registrar.messenger())
        let instance = SwiftAudioWaveformsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        let durationChannel = FlutterEventChannel(name: Constants.durationEventChannel, binaryMessenger: registrar.messenger())
        durationChannel.setStreamHandler(AudioPlayer.sharedInstance)
    }
    
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? Dictionary<String, Any>
        switch call.method {
        case Constants.startRecording:
            audioWaveformsMethodCall.startRecording(result,  args?[Constants.path] as? String,
                                                    args?[Constants.encoder] as? Int, args?[Constants.sampleRate] as? Int,Constants.fileNameFormat)
            break
        case Constants.pauseRecording:
            audioWaveformsMethodCall.pauseRecording(result)
            break
        case Constants.stopRecording:
            audioWaveformsMethodCall.stopRecording(result)
            break
        case Constants.getDecibel:
            audioWaveformsMethodCall.getDecibel(result)
            break
        case Constants.checkPermission:
            audioWaveformsMethodCall.checkHasPermission(result)
            break
        case Constants.preparePlayer:
            audioPlayer.preparePlayer(path: args?[Constants.path] as? String, volume: args?[Constants.volume] as? Double,result: result)
            break
        case Constants.startPlayer:
            let seekToStart = args?[Constants.seekToStart] as? Bool
            audioPlayer.startPlayer(result: result,seekToStart: seekToStart ?? true)
            break
        case Constants.pausePlayer:
            audioPlayer.pausePlayer(result)
            break
        case Constants.stopPlayer:
            audioPlayer.stopPlayer(result)
            break
        case Constants.seekTo:
            audioPlayer.seekTo(args?[Constants.progress] as? Int,result)
        case Constants.setVolume:
            audioPlayer.setVolume(args?[Constants.volume] as? Double,result)
        case Constants.getDuration:
            let type = args?[Constants.durationType] as? Int
            do{
                if(type == 0){
                   try audioPlayer.getDuration(.Current,result)
                } else {
                    try audioPlayer.getDuration(.Max,result)
                }
            } catch{
                result(FlutterError(code: "", message: "Failed to get duration", details: nil))
            }
        default:
            result(FlutterMethodNotImplemented)
            break
        }
    }
}
