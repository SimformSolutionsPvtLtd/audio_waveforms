import Flutter
import UIKit

public class SwiftAudioWaveformsPlugin: NSObject, FlutterPlugin {
    
    final var audioRecorder = AudioRecorder()
    var audioPlayers = [String: AudioPlayer]()
    var extractors = [String: WaveformExtractor]()
    var flutterChannel: FlutterMethodChannel
    
    init(registrar: FlutterPluginRegistrar, flutterChannel: FlutterMethodChannel) {
        self.flutterChannel = flutterChannel
        super.init()
    }
    
    deinit {
        audioPlayers.removeAll()
        extractors.removeAll()
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
                                         args?[Constants.encoder] as? Int, args?[Constants.sampleRate] as? Int, args?[Constants.bitRate] as? Int,Constants.fileNameFormat, args?[Constants.useLegacyNormalization] as? Bool)
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
                audioPlayers[key!]?.preparePlayer(path: args?[Constants.path] as? String,
                                                  volume: args?[Constants.volume] as? Double,
                                                  updateFrequency: getUpdateFrequency(freq: args?[Constants.updateFrequency] as? Int) ,
                                                  result: result)
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
        case Constants.setRate:
            let key = args?[Constants.playerKey] as? String
            if(key != nil){
                audioPlayers[key!]?.setRate(args?[Constants.rate] as? Double,result)
            } else {
                result(FlutterError(code: Constants.audioWaveforms, message: "Can not set rate", details: "Player key is null"))
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
        case Constants.extractWaveformData:
            let key = args?[Constants.playerKey] as? String
            let path = args?[Constants.path] as? String
            let noOfSamples = args?[Constants.noOfSamples] as? Int
            if(key != nil) {
                createOrUpdateExtractor(playerKey: key!, result: result, path: path, noOfSamples: noOfSamples)
            } else {
                result(FlutterError(code: Constants.audioWaveforms, message: "Can not get waveform data", details: "Player key is null"))
            }
        default:
            result(FlutterMethodNotImplemented)
            break
        }
    }
    
    func getUpdateFrequency(freq: Int?) -> UpdateFrequency{
        if(freq == 2){
            return UpdateFrequency.high
        } else if(freq == 1){
            return UpdateFrequency.medium
        }
        return UpdateFrequency.low
    }
    
    func initPlayer(playerKey: String) {
        if audioPlayers[playerKey] == nil {
            let newPlayer = AudioPlayer(plugin: self,playerKey: playerKey,channel: flutterChannel)
            audioPlayers[playerKey] = newPlayer
        }
    }
    
    func createOrUpdateExtractor(playerKey: String, result: @escaping FlutterResult,path: String?, noOfSamples: Int?) {
        if(!(path ?? "").isEmpty) {
            do {
                let audioUrl = URL.init(string: path!)
                if(audioUrl == nil){
                    result(FlutterError(code: Constants.audioWaveforms, message: "Failed to initialise Url from provided audio file", details: "If path contains `file://` try removing it"))
                    return
                }
                let newExtractor = try WaveformExtractor(url: audioUrl!, flutterResult: result, channel: flutterChannel)
                extractors[playerKey] = newExtractor
                let data = newExtractor.extractWaveform(samplesPerPixel: noOfSamples, playerKey: playerKey)
                newExtractor.cancel()
                if(newExtractor.progress == 1.0) {
                    let waveformData = newExtractor.getChannelMean(data: data!)
                    result(waveformData)
                }
            } catch {
                result(FlutterError(code: Constants.audioWaveforms, message: "Failed to decode audio file", details: nil))
            }
        } else {
            result(FlutterError(code: Constants.audioWaveforms, message: "Audio file path can't be empty or null", details: nil))
        }
    }
}
