import Foundation

import AVKit

class AudioPlayer : NSObject, AVAudioPlayerDelegate {
    private var seekToStart = true
    private var timers : [String:Timer] = [:]
    private var audioPlayers: [String:AVAudioPlayer] = [:]
    var plugin : SwiftAudioWaveformsPlugin
    init(plugin : SwiftAudioWaveformsPlugin){
        self.plugin = plugin
    }
    
    
    func preparePlayer(path: String?,volume: Double?,key: String?,result:  @escaping FlutterResult){
        if(key != nil){
            let playerExists = audioPlayers[key!] != nil
            if(!(path ?? "").isEmpty){
                let audioUrl = URL.init(fileURLWithPath: path!)
                if(playerExists){
                    result(true)
                }else{
                    let player = try! AVAudioPlayer(contentsOf: audioUrl)
                    audioPlayers.updateValue(player, forKey: key!)
                    player.prepareToPlay()
                    player.volume = Float(volume ?? 1.0)
                    result(true)
                }
            }else {
                result(FlutterError(code: Constants.audioWaveforms, message: "Audio file path can't be empty or null", details: nil))
            }
        }else {
            result(FlutterError(code: Constants.audioWaveforms, message: "Can not prepare player", details: "Player key is null"))
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer,
                                     successfully flag: Bool){
        if(seekToStart){
            player.currentTime = 0
        } else {
            player.currentTime = player.duration
        }
    }
    
    func startPlyer(key: String?,result:  @escaping FlutterResult,seekToStart:Bool?){
        self.seekToStart = seekToStart ?? true
        if(key != nil){
            audioPlayers[key!]?.play()
            audioPlayers[key!]?.delegate = self
            startListening(key: key!)
            result(true)
        }
        else {
            result(FlutterError(code: Constants.audioWaveforms, message: "Can not start player", details: "Player key is null"))        }
    }
    
    func pausePlayer(key: String?,result:  @escaping FlutterResult){
        if(key != nil){
            stopListening(key: key!)
            audioPlayers[key!]?.pause()
            result(true)
        }
        else {
            result(FlutterError(code: Constants.audioWaveforms, message: "Can not pause player", details: "Player key is null"))
        }
    }
    
    func stopPlayer(key: String?,result:  @escaping FlutterResult){
        if(key != nil){
            stopListening(key: key!)
            audioPlayers[key!]?.stop()
            audioPlayers[key!] = nil
            timers.removeValue(forKey: key!)
            result(true)
        }
        else {
            result(FlutterError(code: Constants.audioWaveforms, message: "Can not stop player", details: "Player key is null"))
        }
    }
    
    
    func getDuration(key: String?,_ type:DurationType,_ result:  @escaping FlutterResult) throws {
        if(key != nil){
            if type == .Current {
                let ms = (audioPlayers[key!]?.currentTime ?? 0) * 1000
                result(Int(ms))
            }else{
                let ms = (audioPlayers[key!]?.duration ?? 0) * 1000
                result(Int(ms))
            }
        }else{
            result(FlutterError(code: Constants.audioWaveforms, message: "Can not get duration", details: "Player key is null"))
        }
    }
    
    func setVolume(key: String?,_ volume: Double?,_ result : @escaping FlutterResult) {
        if(key != nil){
            audioPlayers[key!]?.volume = Float(volume ?? 1.0)
            result(true)
        }
        else{
            result(FlutterError(code: Constants.audioWaveforms, message: "Can not set volume", details: "Player key is null"))
        }
    }
    
    func seekTo(key: String?,_ time: Int?,_ result : @escaping FlutterResult) {
        if(key != nil){
            audioPlayers[key!]?.currentTime = Double(time!/1000)
            result(true)
        }else{
            result(FlutterError(code: Constants.audioWaveforms, message: "Can not seek to provided duration", details: "Player key is null"))
        }
        
    }
    
    func startListening(key: String){
        timers[key] = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: {_ in
            let ms = (self.audioPlayers[key]?.currentTime ?? 0) * 1000
            self.plugin.onCurrentDuration(duration: Int(ms),key: key)
        })
    }
    
    func stopListening(key:String){
        if(timers[key] != nil){
            timers[key]!.invalidate()
            timers[key] = nil
        }
    }
    
    func stopAllPlayers(_ result : @escaping FlutterResult){
        for (key,_) in audioPlayers{
            audioPlayers[key]?.stop()
            audioPlayers[key] = nil
        }
        for (key,_) in timers{
            timers[key]?.invalidate()
            timers[key] = nil
        }
        result(true)
    }
}
