import Foundation

import AVKit



class AudioPlayer : NSObject, FlutterStreamHandler {
    static let sharedInstance = AudioPlayer()
    private var player: AVPlayer?
    private var sink: FlutterEventSink?
    private var item: AVPlayerItem?
    private var url: URL?
    private var observerToken: Any?
    private var didAudioEndObserver: Any?
    private var seekToStart = true
    
    
    func preparePlayer(path: String?, volume: Double?,result:  @escaping FlutterResult){
        if(!(path ?? "").isEmpty){
            url = URL.init(fileURLWithPath: path!)
            item = AVPlayerItem(url: url!)
            player = AVPlayer(playerItem: item!)
            player?.volume = Float(volume ?? 1.0)
            result(true)
        } else {
            result(FlutterError(code: "", message: "Path to file can't be empty or null", details: nil))
        }
    }
    
    func startPlayer(result:  @escaping FlutterResult , seekToStart: Bool){
        self.seekToStart = seekToStart
        didAudioEndObserver = NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        
        if(player?.status == .readyToPlay){
            player?.play()
            result(true)
        } else{
            result(false)
        }
    }
    
    @objc func playerDidFinishPlaying(playerItem: AVPlayerItem){
        let milliSeconds = (player?.currentItem?.duration.seconds ?? 0) * 1000
        sink!(Int(milliSeconds))
        if(seekToStart){
            player?.seek(to: CMTime(seconds: 0, preferredTimescale: 1))
        }
        
    }
    
    func getDuration(_ type:DurationType,_ result:  @escaping FlutterResult) throws {
        if type == .Current {
            let seconds = player?.currentItem?.currentTime().seconds
            guard !(seconds == nil || seconds!.isNaN || seconds!.isInfinite) else {
                throw ThrowError.runtimeError("Error")
            }
            let milliSeconds = (seconds ?? 0) * 1000
            result(Int(milliSeconds))
        }else{
            let seconds = player?.currentItem?.asset.duration.seconds
            guard !(seconds == nil || seconds!.isNaN || seconds!.isInfinite) else {
                throw ThrowError.runtimeError("Error")
            }
            let milliSeconds = (seconds ?? 0) * 1000
            result(Int(milliSeconds))
        }
    }
    
    func pausePlayer(_ result:  @escaping FlutterResult){
        player?.pause()
        result(true)
    }
    
    func stopPlayer(_ result:  @escaping FlutterResult){
        player?.replaceCurrentItem(with: nil)
        result(true)
    }
    
    func setVolume(_ volume: Double?,_ result : @escaping FlutterResult) {
        if(volume != nil){
            player?.volume = Float(volume!)
            result(true)
        }
        result(false)
    }
    
    func seekTo(_ time: Int?,_ result : @escaping FlutterResult) {
        if(time != nil){
            player?.seek(to: CMTime(seconds: Double(time!/1000), preferredTimescale: 1))
            result(true)
        } else {
            result(false)
        }
    }
    
    func startListening(){
        let interval = CMTimeMakeWithSeconds(0.2, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        observerToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .global(), using: {[weak self] time in
            let milliSeconds = (self?.player?.currentItem?.currentTime().seconds ?? 0) * 1000
            self?.sink!(Int(milliSeconds))
        })
    }
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        sink = events
        startListening()
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        if(observerToken != nil){
            player?.removeTimeObserver(observerToken!)
        }
        if(didAudioEndObserver != nil){
            NotificationCenter.default.removeObserver(didAudioEndObserver!)
        }
        sink = nil
        return nil
    }
}
