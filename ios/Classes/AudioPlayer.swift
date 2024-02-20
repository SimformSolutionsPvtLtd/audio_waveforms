import Foundation

import AVKit

class AudioPlayer: NSObject, AVAudioPlayerDelegate {
    private var seekToStart = true
    private var stopWhenCompleted = false
    private var timer: Timer?
    private var player: AVAudioPlayer?
    private var releaseMode:ReleaseMode = ReleaseMode.release
    private var updateFrequency = 200
    var plugin: SwiftAudioWaveformsPlugin
    var playerKey: String
    var flutterChannel: FlutterMethodChannel
    

    init(plugin: SwiftAudioWaveformsPlugin, playerKey: String, channel: FlutterMethodChannel) {
        self.plugin = plugin
        self.playerKey = playerKey
        flutterChannel = channel
    }
    
    func preparePlayer(path: String?, volume: Double?, updateFrequency: Int?,result: @escaping FlutterResult, overrideAudioSession : Bool) {
        if(!(path ?? "").isEmpty) {
            self.updateFrequency = updateFrequency ?? 200
            let audioUrl = URL.init(string: path!)
            if(audioUrl == nil){
                result(FlutterError(code: Constants.audioWaveforms, message: "Failed to initialise Url from provided audio file", details: "If path contains `file://` try removing it"))
                return
            }
            do {
                player = try AVAudioPlayer(contentsOf: audioUrl!)
                do {
                    if overrideAudioSession {
                        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                        try AVAudioSession.sharedInstance().setActive(true)
                    }
                } catch {
                    result(FlutterError(code: Constants.audioWaveforms, message: "Couldn't set audio session.", details: error.localizedDescription))

                }
                
            } catch {
                result(FlutterError(code: Constants.audioWaveforms, message: "Failed to prepare player", details: error.localizedDescription))
            }
            player?.enableRate = true
            player?.rate = 1.0
            player?.prepareToPlay()
            player?.volume = Float(volume ?? 1.0)
            result(true)
        } else {
            result(FlutterError(code: Constants.audioWaveforms, message: "Audio file path can't be empty or null", details: nil))
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer,successfully flag: Bool) {
        var finishType = 2
        var releaseType = 0

        switch self.releaseMode{
        case .release:
            self.player?.stop()
            stopListening()
            self.player = nil
            releaseType = 0

        case .loop:
            self.player?.currentTime = 0
            self.player?.play()
            releaseType = 1

        case .pause:
            self.player?.pause()
            stopListening()
            releaseType = 2
        }
        
        plugin.flutterChannel.invokeMethod(Constants.onDidFinishPlayingAudio, arguments: [
            Constants.releaseType: releaseType,
            Constants.playerKey: playerKey])

    }

    func startPlyer(result: @escaping FlutterResult) {
        player?.play()
        player?.delegate = self
        startListening()
        result(true)
    }


    func pausePlayer(result: @escaping FlutterResult) {
        stopListening()
        player?.pause()
        result(true)
    }
    
    func stopPlayer(result: @escaping FlutterResult) {
        stopListening()
        player?.stop()
        timer = nil
        result(true)
    }
    
    func release(result: @escaping FlutterResult) {
        player = nil
        result(true)
    }
    
    func getDuration(_ type: DurationType, _ result: @escaping FlutterResult) throws {
        if type == .Current {
            let ms = (player?.currentTime ?? 0) * 1000
            result(Int(ms))
        } else {
            let ms = (player?.duration ?? 0) * 1000
            result(Int(ms))
        }
    }
    
    func setVolume(_ volume: Double?, _ result: @escaping FlutterResult) {
        player?.volume = Float(volume ?? 1.0)
        result(true)
    }

    func setRate(_ rate: Double?, _ result: @escaping FlutterResult) {
        player?.rate = Float(rate ?? 1.0);
        result(true)
    }

    func seekTo(_ time: Int?, _ result: @escaping FlutterResult) {
        if(time != nil) {
            player?.currentTime = Double(time! / 1000)
            sendCurrentDuration()
            result(true)
        } else {
            result(false)
        }
    }
    
    func setReleaseMode(result : @escaping FlutterResult, releaseType : Int?){
        if(releaseType != nil && releaseType == 0){
            self.releaseMode = ReleaseMode.release
        }else if(releaseType != nil && releaseType == 1){
            self.releaseMode = ReleaseMode.loop
        }else{
            self.releaseMode = ReleaseMode.pause
        }
    }

    func startListening() {
        if #available(iOS 10.0, *) {
            timer = Timer.scheduledTimer(withTimeInterval: (Double(updateFrequency) / 1000), repeats: true, block: { _ in
                self.sendCurrentDuration()
            })
        } else {
            // Fallback on earlier versions
        }
    }
    
    func stopListening() {
        timer?.invalidate()
        timer = nil
        sendCurrentDuration()
    }

    func sendCurrentDuration() {
        let ms = (player?.currentTime ?? 0) * 1000
        flutterChannel.invokeMethod(Constants.onCurrentDuration, arguments: [Constants.current: Int(ms), Constants.playerKey: playerKey])
    }
}
