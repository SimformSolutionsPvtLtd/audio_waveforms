import AVFoundation
import Accelerate

public class AudioRecorder: NSObject, AVAudioRecorderDelegate{
    var audioRecorder: AVAudioRecorder?
    var path: String?
    var useLegacyNormalization: Bool = false
    var audioUrl: URL?
    private struct PendingStop {
        var results: [FlutterResult]
        /// Path exactly as the caller passed it, so the returned path keeps the existing contract.
        let path: String?
    }
    /// Stops waiting for `audioRecorderDidFinishRecording`, keyed by the stopping recorder, so we
    /// only read the file and return its path once the recorder has finalized it on disk. Keying
    /// by recorder keeps a stop of a new recording from joining a previous recording's results.
    private var pendingStops: [ObjectIdentifier: PendingStop] = [:]
    /// Recorder of the most recent stop; a repeated `stop()` with no new recording joins it.
    private var lastStoppedRecorder: ObjectIdentifier?
    var flutterChannel: FlutterMethodChannel
    var bytesStreamEngine: RecorderBytesStreamEngine
    init(channel: FlutterMethodChannel){
        flutterChannel = channel
        bytesStreamEngine = RecorderBytesStreamEngine(channel: channel)
    }

    func startRecording(_ result: @escaping FlutterResult,_ recordingSettings: RecordingSettings){
        useLegacyNormalization = recordingSettings.useLegacy ?? false

        var settings: [String: Any] = [
                AVFormatIDKey: getEncoder(recordingSettings.encoder ?? 0),
                AVSampleRateKey: recordingSettings.sampleRate ?? 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
        
        if (recordingSettings.bitRate != nil) {
            settings[AVEncoderBitRateKey] = recordingSettings.bitRate
        }

        if ((recordingSettings.encoder ?? 0) == Constants.kAudioFormatLinearPCM) {
            settings[AVLinearPCMBitDepthKey] = recordingSettings.linearPCMBitDepth
            settings[AVLinearPCMIsBigEndianKey] = recordingSettings.linearPCMIsBigEndian
            settings[AVLinearPCMIsFloatKey] = recordingSettings.linearPCMIsFloat
        }

        let options: AVAudioSession.CategoryOptions = [.defaultToSpeaker, .allowBluetooth]
        if (recordingSettings.path == nil) {
            let documentDirectory = getDocumentDirectory(result)
            let date = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = recordingSettings.fileNameFormat
            let fileName = dateFormatter.string(from: date) + ".m4a"
            self.path = "\(documentDirectory)/\(fileName)"
        } else {
            self.path = recordingSettings.path
        }
        
        
        do {
            if recordingSettings.overrideAudioSession {
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: options)
                try AVAudioSession.sharedInstance().setActive(true)
            }
            audioUrl = URL(fileURLWithPath: self.path!)
            
            if(audioUrl == nil){
                result(FlutterError(code: Constants.audioWaveforms, message: "Failed to initialise file URL", details: nil))
                return
            }
            audioRecorder = try AVAudioRecorder(url: audioUrl!, settings: settings as [String : Any])
            
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            bytesStreamEngine
                .attach(
                    result: result,
                    sampleRate:  recordingSettings.sampleRate ?? Constants.defaultSampleRate
                )
            result(true)
        } catch {
            result(FlutterError(code: Constants.audioWaveforms, message: "Failed to start recording", details: error.localizedDescription))
        }
    }
    
    public func stopRecording(_ result: @escaping FlutterResult) {
        bytesStreamEngine.detach()
        // `stop()` finalizes the file async; reading it early yields a truncated
        // container. Defer to the delegate; finalize now only if there is no recorder.
        guard let recorder = audioRecorder else {
            // Repeated stop with no new recording: join the stop still in flight so it
            // resolves with the same finalized path/duration instead of an empty map.
            if let key = lastStoppedRecorder, pendingStops[key] != nil {
                pendingStops[key]?.results.append(result)
                return
            }
            finalizeRecording([result], url: audioUrl, path: path)
            return
        }
        let key = ObjectIdentifier(recorder)
        pendingStops[key] = PendingStop(results: [result], path: path)
        lastStoppedRecorder = key
        // Detach so a subsequent `startRecording` can't mutate the URL/path this
        // stop finalizes; the watchdog closure keeps the recorder alive meanwhile.
        audioRecorder = nil
        recorder.stop()
        // The delegate isn't guaranteed to fire, so force-finalize after a timeout
        // or Dart's `stop()` hangs forever. Whoever removes the entry first wins, so
        // the loser of delegate-vs-watchdog is a no-op.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self,
                  let pending = self.pendingStops.removeValue(forKey: key) else { return }
            self.finalizeRecording(pending.results, url: recorder.url, path: pending.path)
        }
    }

    /// Reads the file's duration and returns its path; call only after writing
    /// finished. URL/path passed in (not from `self`) to avoid a re-recording race.
    /// All queued `results` resolve with the same path/duration.
    private func finalizeRecording(_ results: [FlutterResult], url: URL?, path: String?) {
        guard let url = url else {
            sendResult(results, duration: 0, path: path)
            return
        }
        let asset = AVURLAsset(url: url)
        if #available(iOS 15.0, *) {
            Task {
                var durationMs = 0
                do {
                    let seconds = try await asset.load(.duration).seconds
                    // `seconds` is NaN/infinite for an invalid or unfinished
                    // container; `Int(NaN)` crashes, so only convert when finite.
                    if seconds.isFinite { durationMs = Int(seconds * 1000) }
                } catch let err {
                    debugPrint(err.localizedDescription)
                }
                // FlutterResult must be invoked on the platform (main) thread;
                // the Task continuation resumes on a background executor.
                DispatchQueue.main.async {
                    self.sendResult(results, duration: durationMs, path: path)
                }
            }
        } else {
            // `seconds` is NaN for an invalid container; `Int(NaN)` crashes.
            let seconds = asset.duration.seconds
            sendResult(results, duration: seconds.isFinite ? Int(seconds * 1000) : 0, path: path)
        }
    }

    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        // Hop to main: `pendingStops` is only mutated there and `FlutterResult`
        // must run on the platform thread.
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let pending = self.pendingStops.removeValue(forKey: ObjectIdentifier(recorder)) else { return }
            // `flag == false`: recorder couldn't write a valid file. finalize still
            // returns the path (zero duration) since Dart doesn't catch errors here.
            if !flag {
                debugPrint("audioRecorderDidFinishRecording reported failure for \(recorder.url)")
            }
            // Use the finishing recorder's own URL so a re-recording can't redirect us.
            self.finalizeRecording(pending.results, url: recorder.url, path: pending.path)
        }
    }

    private func sendResult(_ results: [FlutterResult], duration: Int, path: String?) {
        var params = [String:Any?]()
        params[Constants.resultFilePath] = path
        params[Constants.resultDuration] = duration
        for result in results { result(params) }
    }
    
    public func pauseRecording(_ result: @escaping FlutterResult) {
        audioRecorder?.pause()
        bytesStreamEngine.togglePause()
        result(false)
    }
    
    public func resumeRecording(_ result: @escaping FlutterResult) {
        audioRecorder?.record()
        bytesStreamEngine.togglePause();
        result(true)
    }
    
    public func getDecibel(_ result: @escaping FlutterResult) {
        audioRecorder?.updateMeters()
        if(useLegacyNormalization){
            let amp = audioRecorder?.averagePower(forChannel: 0) ?? 0.0
            result(amp)
        } else {
            let amp = audioRecorder?.peakPower(forChannel: 0) ?? 0.0
            let linear = pow(10, amp / 20);
            result(linear)
        }
    }
    
    public func checkHasPermission(_ result: @escaping FlutterResult){
        switch AVAudioSession.sharedInstance().recordPermission{
            
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    result(allowed)
                }
            }
        case .denied:
            result(false)
        case .granted:
            result(true)
        @unknown default:
            result(false)
        }
    }
    public func getEncoder(_ enCoder: Int) -> Int {
        switch(enCoder) {
        case Constants.kAudioFormatMPEG4AAC:
            return Int(kAudioFormatMPEG4AAC)
        case Constants.kAudioFormatMPEGLayer1:
            return Int(kAudioFormatMPEGLayer1)
        case Constants.kAudioFormatMPEGLayer2:
            return Int(kAudioFormatMPEGLayer2)
        case Constants.kAudioFormatMPEGLayer3:
            return Int(kAudioFormatMPEGLayer3)
        case Constants.kAudioFormatMPEG4AAC_ELD:
            return Int(kAudioFormatMPEG4AAC_ELD)
        case Constants.kAudioFormatMPEG4AAC_HE:
            return Int(kAudioFormatMPEG4AAC_HE)
        case Constants.kAudioFormatOpus:
            return Int(kAudioFormatOpus)
        case Constants.kAudioFormatAMR:
            return Int(kAudioFormatAMR)
        case Constants.kAudioFormatAMR_WB:
            return Int(kAudioFormatAMR_WB)
        case Constants.kAudioFormatLinearPCM:
            return Int(kAudioFormatLinearPCM)
        case Constants.kAudioFormatAppleLossless:
            return Int(kAudioFormatAppleLossless)
        case Constants.kAudioFormatMPEG4AAC_HE_V2:
            return Int(kAudioFormatMPEG4AAC_HE_V2)
        default:
            return Int(kAudioFormatMPEG4AAC)
        }
    }
    
    private func getDocumentDirectory(_ result: @escaping FlutterResult) -> String {
        let directory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let ifExists = FileManager.default.fileExists(atPath: directory)
        if(directory.isEmpty){
            result(FlutterError(code: Constants.audioWaveforms, message: "The document directory path is empty", details: nil))
            return ""
        } else if(!ifExists) {
            result(FlutterError(code: Constants.audioWaveforms, message: "The document directory does't exists", details: nil))
            return ""
        }
        return directory
    }
}
