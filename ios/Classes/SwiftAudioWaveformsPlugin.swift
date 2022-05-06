import Flutter
import UIKit

public class SwiftAudioWaveformsPlugin: NSObject, FlutterPlugin {
    
    final var audioRecorder = AudioRecorder()
    var audioPlayers = [String: AudioPlayer]()
    var flutterChannel: FlutterMethodChannel
    
    init(registrar: FlutterPluginRegistrar, flutterChannel: FlutterMethodChannel) {
        self.flutterChannel = flutterChannel
        super.init()
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
            if(key != nil){
                initPlayer(playerKey: key!)
                audioPlayers[key!]?.preparePlayer(path: args?[Constants.path] as? String, volume: args?[Constants.volume] as? Double,result: result)
            } else {
                result(FlutterError(code: Constants.audioWaveforms, message: "Can not prepare player", details: "Player key is null"))
            }
            break
        case Constants.startPlayer:
            let key = args?[Constants.playerKey] as? String
            let finishMode = args?[Constants.finishMode] as? Int
            if(key != nil){
                audioPlayers[key!]?.startPlyer(result: result,finishMode: finishMode)
            } else {
                result(FlutterError(code: Constants.audioWaveforms, message: "Can not start player", details: "Player key is null"))
            }
            break
        case Constants.pausePlayer:
            let key = args?[Constants.playerKey] as? String
            if(key != nil){
                audioPlayers[key!]?.pausePlayer(result: result)
            } else {
                result(FlutterError(code: Constants.audioWaveforms, message: "Can not pause player", details: "Player key is null"))
            }
            break
        case Constants.stopPlayer:
            let key = args?[Constants.playerKey] as? String
            if(key != nil){
                audioPlayers[key!]?.stopPlayer(result: result)
            } else {
                result(FlutterError(code: Constants.audioWaveforms, message: "Can not stop player", details: "Player key is null"))
            }
            break
        case Constants.seekTo:
            let key = args?[Constants.playerKey] as? String
            if(key != nil){
                audioPlayers[key!]?.seekTo(args?[Constants.progress] as? Int,result)
            } else {
                result(FlutterError(code: Constants.audioWaveforms, message: "Can not seek to postion", details: "Player key is null"))
            }
        case Constants.setVolume:
            let key = args?[Constants.playerKey] as? String
            if(key != nil){
                audioPlayers[key!]?.setVolume(args?[Constants.volume] as? Double,result)
            } else {
                result(FlutterError(code: Constants.audioWaveforms, message: "Can not set volume", details: "Player key is null"))
            }
        case Constants.getDuration:
            let type = args?[Constants.durationType] as? Int
            let key = args?[Constants.playerKey] as? String
            if(key != nil){
                do{
                    if(type == 0){
                        try audioPlayers[key!]?.getDuration(DurationType.Current,result)
                    } else {
                        try audioPlayers[key!]?.getDuration( DurationType.Max,result)
                    }
                } catch{
                    result(FlutterError(code: "", message: "Failed to get duration", details: nil))
                }
            } else {
                result(FlutterError(code: Constants.audioWaveforms, message: "Can not get duration", details: "Player key is null"))
            }
        case Constants.stopAllPlayers:
            for (playerKey,_) in audioPlayers{
                audioPlayers[playerKey]?.stopPlayer(result: result)
                audioPlayers[playerKey] = nil
            }
            result(true)
        default:
            result(FlutterMethodNotImplemented)
            break
        }
    }
    
    func initPlayer(playerKey: String) {
        if audioPlayers[playerKey] == nil {
            let newPlayer = AudioPlayer(plugin: self,playerKey: playerKey)
            audioPlayers[playerKey] = newPlayer
        }
    }
    
    func onCurrentDuration(duration: Int, playerKey: String){
        flutterChannel.invokeMethod(Constants.onCurrentDuration, arguments: [Constants.current : duration, Constants.playerKey : playerKey])
    }
}
