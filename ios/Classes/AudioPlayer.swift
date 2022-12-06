import Foundation

import AVKit

class AudioPlayer: NSObject, AVAudioPlayerDelegate {
    private var seekToStart = true
    private var stopWhenCompleted = false
    private var timer: Timer?
    private var player: AVAudioPlayer?
    private var finishMode: FinishMode = FinishMode.stop
    var plugin: SwiftAudioWaveformsPlugin
    var playerKey: String
    var flutterChannel: FlutterMethodChannel
    private var waveformExtractor: WaveformExtractor?
    init(plugin: SwiftAudioWaveformsPlugin, playerKey: String, channel: FlutterMethodChannel) {
        self.plugin = plugin
        self.playerKey = playerKey
        flutterChannel = channel
    }

    func extractWaveformData(path: String?, result: @escaping FlutterResult, noOfSamples: Int?) {
        if(!(path ?? "").isEmpty) {
            do {
                let audioUrl = URL.init(fileURLWithPath: path!)
                waveformExtractor = try WaveformExtractor(url: audioUrl, flutterResult: result, channel: flutterChannel)
                if(waveformExtractor != nil) {
                    let data = waveformExtractor!.extractWaveform(samplesPerPixel: noOfSamples, playerKey: playerKey)
                    waveformExtractor!.cancel()
                    if(waveformExtractor!.progress == 1.0) {
                        let waveformData = waveformExtractor!.getChannelMean(data: data!)
                        result(waveformData)
                    }
                }
            } catch {
                result(FlutterError(code: Constants.audioWaveforms, message: "Failded to decode audio file", details: nil))
            }
        } else {
            result(FlutterError(code: Constants.audioWaveforms, message: "Audio file path can't be empty or null", details: nil))
        }
    }

    func preparePlayer(path: String?, volume: Double?, result: @escaping FlutterResult) {
        if(!(path ?? "").isEmpty) {
            let audioUrl = URL.init(fileURLWithPath: path!)
            do {
                player = try AVAudioPlayer(contentsOf: audioUrl)
            } catch {
                result(FlutterError(code: "", message: "Failed to prepare recording", details: nil))
            }
            
            player?.prepareToPlay()
            player?.volume = Float(volume ?? 1.0)
            result(true)
        } else {
            result(FlutterError(code: Constants.audioWaveforms, message: "Audio file path can't be empty or null", details: nil))
        }

    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer,
                                     successfully flag: Bool) {
        var finishType = 2
        switch self.finishMode {
        case .loop:
            self.player?.currentTime = 0
            self.player?.play()
            finishType = 0
        case .pause:
            self.player?.pause()
            stopListening()
            finishType = 1
        case .stop:
            self.player?.stop()
            stopListening()
            self.player = nil
            finishType = 2
        }
        plugin.flutterChannel.invokeMethod(Constants.onDidFinishPlayingAudio, arguments: [Constants.finishType: finishType, Constants.playerKey: playerKey])

    }

    func startPlyer(result: @escaping FlutterResult, finishMode: Int?) {
        if(finishMode != nil && finishMode == 0) {
            self.finishMode = FinishMode.loop
        } else if(finishMode != nil && finishMode == 1) {
            self.finishMode = FinishMode.pause
        } else {
            self.finishMode = FinishMode.stop
        }
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
        player = nil
        timer = nil
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

    func seekTo(_ time: Int?, _ result: @escaping FlutterResult) {
        if(time != nil) {
            player?.currentTime = Double(time! / 1000)
            result(true)
        } else {
            result(false)
        }
    }

    func startListening() {
        if #available(iOS 10.0, *) {
            timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { _ in
                let ms = (self.player?.currentTime ?? 0) * 1000
                self.flutterChannel.invokeMethod(Constants.onCurrentDuration, arguments: [Constants.current: Int(ms), Constants.playerKey: self.playerKey])
            })
        } else {
            // Fallback on earlier versions
        }
    }

    func stopListening() {
        timer?.invalidate()
        timer = nil
    }
}
