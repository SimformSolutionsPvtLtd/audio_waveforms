import Flutter
import UIKit

public class SwiftAudioWaveformsPlugin: NSObject, FlutterPlugin {
    
    final var audioRecorder = AudioRecorder()
    var audioPlayer : AudioPlayer?
    var flutterChannel: FlutterMethodChannel
    
    init(registrar: FlutterPluginRegistrar, flutterChannel: FlutterMethodChannel) {
        self.flutterChannel = flutterChannel
        super.init()
        self.audioPlayer = AudioPlayer(plugin: self)
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: Constants.methodChannelName, binaryMessenger: registrar.messenger())
        let instance = SwiftAudioWaveformsPlugin(registrar: registrar, flutterChannel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? Dictionary<String, Any>
        switch call.method {
        case Constants.startRecording:
            audioRecorder.startRecording(result,  args?[Constants.path] as? String,
                                         args?[Constants.encoder] as? Int, args?[Constants.sampleRate] as? Int,Constants.fileNameFormat)
            break
        case Constants.pauseRecording:
            audioRecorder.pauseRecording(result)
            break
        case Constants.resumeRecording:
            audioRecorder.resumeRecording(result)
        case Constants.stopRecording:
            audioRecorder.stopRecording(result)
            break
        case Constants.getDecibel:
            audioRecorder.getDecibel(result)
            break
        case Constants.checkPermission:
            audioRecorder.checkHasPermission(result)
            break
        case Constants.preparePlayer:
            let key = args?[Constants.playerKey] as? String
            
            audioPlayer?.preparePlayer(path: args?[Constants.path] as? String, volume: args?[Constants.volume] as? Double,key: key,result: result)
            break
        case Constants.startPlayer:
            let key = args?[Constants.playerKey] as? String
            let seekToStart = args?[Constants.seekToStart] as? Bool
            audioPlayer?.startPlyer(key: key, result: result, seekToStart:seekToStart)
            break
        case Constants.pausePlayer:
            let key = args?[Constants.playerKey] as? String
            audioPlayer?.pausePlayer(key: key, result: result)
            break
        case Constants.stopPlayer:
            let key = args?[Constants.playerKey] as? String
            audioPlayer?.stopPlayer(key: key,result: result)
            break
        case Constants.seekTo:
            let key = args?[Constants.playerKey] as? String
            audioPlayer?.seekTo(key: key,args?[Constants.progress] as? Int,result)
        case Constants.setVolume:
            let key = args?[Constants.playerKey] as? String
            audioPlayer?.setVolume(key: key,args?[Constants.volume] as? Double,result)
        case Constants.getDuration:
            let type = args?[Constants.durationType] as? Int
            let key = args?[Constants.playerKey] as? String
            do{
                if(type == 0){
                    try audioPlayer?.getDuration(key: key,DurationType.Current,result)
                } else {
                    try audioPlayer?.getDuration(key: key, DurationType.Max,result)
                }
            } catch{
                result(FlutterError(code: "", message: "Failed to get duration", details: nil))
            }
        case Constants.stopAllPlayers:
            audioPlayer?.stopAllPlayers(result)
        default:
            result(FlutterMethodNotImplemented)
            break
        }
    }
    
    func onCurrentDuration(duration: Int,key: String){
        flutterChannel.invokeMethod(Constants.onCurrentDuration, arguments: [Constants.current : duration,Constants.playerKey: key])
    }
}
