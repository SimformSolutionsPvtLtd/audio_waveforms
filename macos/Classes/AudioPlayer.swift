import AVKit
import Foundation

/// Handles audio playback functionality on macOS.
/// Manages player lifecycle, playback controls, and progress tracking.
class AudioPlayer: NSObject, AVAudioPlayerDelegate {
    private var seekToStart = true
    private var stopWhenCompleted = false
    private var timer: Timer?
    private var player: AVAudioPlayer?
    private var finishMode: FinishMode = FinishMode.stop
    private var updateFrequency = 200
    var plugin: SwiftAudioWaveformsPlugin
    var playerKey: String
    var flutterChannel: FlutterMethodChannel

    /// Initializes the audio player.
    /// - Parameters:
    ///   - plugin: Reference to the main plugin instance
    ///   - playerKey: Unique identifier for this player
    ///   - channel: Flutter method channel for callbacks
    init(
        plugin: SwiftAudioWaveformsPlugin, playerKey: String,
        channel: FlutterMethodChannel
    ) {
        self.plugin = plugin
        self.playerKey = playerKey
        flutterChannel = channel
    }

    /// Prepares the audio player with the specified audio file.
    /// - Parameters:
    ///   - path: File path of the audio file
    ///   - volume: Playback volume (0.0 to 1.0)
    ///   - updateFrequency: Frequency of progress updates in milliseconds
    ///   - result: Callback with success/error status
    ///   - overrideAudioSession: Whether to override the audio session (macOS ignores this)
    func preparePlayer(
        path: String?, volume: Double?, updateFrequency: Int?,
        result: @escaping FlutterResult, overrideAudioSession: Bool
    ) {
        if !(path ?? "").isEmpty {
            self.updateFrequency = updateFrequency ?? 200
            let audioUrl = URL.init(string: path!)
            if audioUrl == nil {
                result(
                    FlutterError(
                        code: Constants.audioWaveforms,
                        message:
                            "Failed to initialise Url from provided audio file",
                        details: "If path contains `file://` try removing it"))
                return
            }
            do {
                stopPlayer()
                player = nil
                player = try AVAudioPlayer(contentsOf: audioUrl!)
                // macOS doesn't need AVAudioSession configuration
            } catch {
                result(
                    FlutterError(
                        code: Constants.audioWaveforms,
                        message: "Failed to prepare player",
                        details: error.localizedDescription))
                return
            }
            player?.enableRate = true
            player?.rate = 1.0
            player?.prepareToPlay()
            player?.volume = Float(volume ?? 1.0)
            result(true)
        } else {
            result(
                FlutterError(
                    code: Constants.audioWaveforms,
                    message: "Audio file path can't be empty or null",
                    details: nil))
        }
    }

    /// Called when audio playback finishes.
    /// Handles different finish modes (loop, pause, stop).
    func audioPlayerDidFinishPlaying(
        _ player: AVAudioPlayer, successfully flag: Bool
    ) {
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

        plugin.flutterChannel.invokeMethod(
            Constants.onDidFinishPlayingAudio,
            arguments: [
                Constants.finishType: finishType,
                Constants.playerKey: playerKey,
            ])

    }

    /// Starts audio playback.
    /// - Parameter result: Callback with success status
    func startPlayer(result: @escaping FlutterResult) {
        player?.play()
        player?.delegate = self
        startListening()
        result(true)
    }

    /// Pauses the current audio playback.
    func pausePlayer() {
        stopListening()
        player?.pause()
    }

    /// Stops the current audio playback.
    func stopPlayer() {
        stopListening()
        player?.stop()
        timer = nil
    }

    /// Releases audio player resources.
    /// - Parameter result: Callback with success status
    func release(result: @escaping FlutterResult) {
        player = nil
        result(true)
    }

    /// Retrieves the current or maximum duration of the audio file.
    /// - Parameters:
    ///   - type: DurationType.Current or DurationType.Max
    ///   - result: Callback with duration in milliseconds
    func getDuration(_ type: DurationType, _ result: @escaping FlutterResult)
        throws
    {
        if type == .Current {
            let ms = (player?.currentTime ?? 0) * 1000
            result(Int(ms))
        } else {
            let ms = (player?.duration ?? 0) * 1000
            result(Int(ms))
        }
    }

    /// Sets the playback volume.
    /// - Parameters:
    ///   - volume: Volume level (0.0 to 1.0)
    ///   - result: Callback with success status
    func setVolume(_ volume: Double?, _ result: @escaping FlutterResult) {
        player?.volume = Float(volume ?? 1.0)
        result(true)
    }

    /// Sets the playback rate (speed).
    /// - Parameters:
    ///   - rate: Playback rate (1.0 = normal speed)
    ///   - result: Callback with success status
    func setRate(_ rate: Double?, _ result: @escaping FlutterResult) {
        player?.rate = Float(rate ?? 1.0)
        result(true)
    }

    /// Seeks to a specific position in the audio.
    /// - Parameters:
    ///   - time: Time position in milliseconds
    ///   - result: Callback with success status
    func seekTo(_ time: Int?, _ result: @escaping FlutterResult) {
        if time != nil {
            player?.currentTime = Double(time! / 1000)
            sendCurrentDuration()
            result(true)
        } else {
            result(false)
        }
    }

    /// Sets the finish mode for playback.
    /// - Parameters:
    ///   - result: Callback with success status
    ///   - releaseType: 0=loop, 1=pause, 2=stop (default)
    func setFinishMode(result: @escaping FlutterResult, releaseType: Int?) {
        if releaseType != nil && releaseType == 0 {
            self.finishMode = FinishMode.loop
        } else if releaseType != nil && releaseType == 1 {
            self.finishMode = FinishMode.pause
        } else {
            self.finishMode = FinishMode.stop
        }
        result(nil)
    }

    /// Starts listening for duration updates.
    func startListening() {
        timer = Timer.scheduledTimer(
            withTimeInterval: (Double(updateFrequency) / 1000), repeats: true,
            block: { _ in
                self.sendCurrentDuration()
            })
    }

    /// Stops listening for duration updates.
    func stopListening() {
        timer?.invalidate()
        timer = nil
        sendCurrentDuration()
    }

    /// Sends the current playback duration to Flutter.
    func sendCurrentDuration() {
        let ms = (player?.currentTime ?? 0) * 1000
        flutterChannel.invokeMethod(
            Constants.onCurrentDuration,
            arguments: [
                Constants.current: Int(ms), Constants.playerKey: playerKey,
            ])
    }
}
