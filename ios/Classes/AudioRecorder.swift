import AVFoundation
import Accelerate

public class AudioRecorder: NSObject, AVAudioRecorderDelegate{
    var audioRecorder: AVAudioRecorder?
    var path: String?
    var useLegacyNormalization: Bool = false
    var audioUrl: URL?
    var recordedDuration: CMTime = CMTime.zero
    var flutterChannel: FlutterMethodChannel
    var bytesStreamEngine: RecorderBytesStreamEngine
    // Settings of the current recording, reused when recording resumes.
    private var recorderSettings: [String: Any] = [:]
    // After a resume, audio is recorded here and appended to `audioUrl`
    // on the next pause or stop.
    private var segmentUrl: URL?
    // Entered while a segment is being appended, so stop waits for it.
    private let appendGroup = DispatchGroup()
    // Whether the file is kept open on pause because it can't be appended to.
    private var isPausedInPlace = false
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
            recorderSettings = settings
            segmentUrl = nil
            isPausedInPlace = false
            
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
        audioRecorder?.stop()
        bytesStreamEngine.detach()
        audioRecorder = nil
        // A pause may still be appending the resumed audio.
        appendGroup.notify(queue: .main) {
            self.appendSegmentIfNeeded { error in
                if let error = error {
                    result(FlutterError(code: Constants.audioWaveforms, message: "Failed to save resumed recording", details: error.localizedDescription))
                    return
                }
                self.sendRecordingResult(result)
            }
        }
    }

    private func sendRecordingResult(_ result: @escaping FlutterResult) {
        if(audioUrl != nil) {
            let asset = AVURLAsset(url:  audioUrl!)
            
            if #available(iOS 15.0, *) {
                Task {
                    do {
                        recordedDuration = try await asset.load(.duration)
                        sendResult(result, duration: Int(recordedDuration.seconds * 1000))
                    } catch let err {
                        debugPrint(err.localizedDescription)
                        sendResult(result, duration: Int(CMTime.zero.seconds))
                    }
                }
            } else {
                recordedDuration = asset.duration
                sendResult(result, duration: Int(recordedDuration.seconds * 1000))
            }
        } else {
            sendResult(result, duration: Int(CMTime.zero.seconds))
        }
    }
    
    private func sendResult(_ result: @escaping FlutterResult, duration:Int){
        var params = [String:Any?]()
        params[Constants.resultFilePath] = path
        params[Constants.resultDuration] = duration
        result(params)
    }
    
    public func pauseRecording(_ result: @escaping FlutterResult) {
        guard let audioUrl = audioUrl, getFileType(audioUrl) != nil else {
            // Resumed audio can't be appended to this file type, so keep
            // recording into the same file, which isn't playable while paused.
            isPausedInPlace = true
            audioRecorder?.pause()
            bytesStreamEngine.togglePause()
            result(false)
            return
        }
        // AVAudioRecorder only finalises the file on stop, so stop instead of
        // pausing to keep the audio recorded so far playable while paused.
        audioRecorder?.stop()
        bytesStreamEngine.togglePause()
        appendSegmentIfNeeded { error in
            if let error = error {
                result(FlutterError(code: Constants.audioWaveforms, message: "Failed to save resumed recording", details: error.localizedDescription))
                return
            }
            result(false)
        }
    }
    
    public func resumeRecording(_ result: @escaping FlutterResult) {
        guard let audioUrl = audioUrl else {
            result(FlutterError(code: Constants.audioWaveforms, message: "Failed to resume recording", details: "Recording was never started"))
            return
        }
        if isPausedInPlace {
            isPausedInPlace = false
            audioRecorder?.record()
            bytesStreamEngine.togglePause()
            result(true)
            return
        }
        // Recording into `audioUrl` again would overwrite it, so record the
        // rest into a separate file and append it on pause or stop.
        let segmentUrl = FileManager.default.temporaryDirectory
            .appendingPathComponent("resumed_\(audioUrl.lastPathComponent)")
        do {
            audioRecorder = try AVAudioRecorder(url: segmentUrl, settings: recorderSettings)
        } catch {
            result(FlutterError(code: Constants.audioWaveforms, message: "Failed to resume recording", details: error.localizedDescription))
            return
        }
        self.segmentUrl = segmentUrl
        audioRecorder?.delegate = self
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.record()
        bytesStreamEngine.togglePause();
        result(true)
    }

    /// Appends the audio recorded since the last resume to the recording
    /// file. Runs in the background and calls `completion` on the main thread.
    /// If appending fails, the segment is kept so the resumed audio isn't lost.
    private func appendSegmentIfNeeded(_ completion: @escaping (Error?) -> Void) {
        guard let segmentUrl = segmentUrl, let audioUrl = audioUrl, let fileType = getFileType(audioUrl) else {
            completion(nil)
            return
        }
        self.segmentUrl = nil
        let mergedUrl = FileManager.default.temporaryDirectory
            .appendingPathComponent("merged_\(audioUrl.lastPathComponent)")
        appendGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            var mergeError: Error?
            do {
                try? FileManager.default.removeItem(at: mergedUrl)
                try self.writeSamples(of: [audioUrl, segmentUrl], to: mergedUrl, fileType: fileType)
                _ = try FileManager.default.replaceItemAt(audioUrl, withItemAt: mergedUrl)
                try? FileManager.default.removeItem(at: segmentUrl)
            } catch {
                try? FileManager.default.removeItem(at: mergedUrl)
                mergeError = self.appendError("\(error.localizedDescription) Resumed audio is kept at \(segmentUrl.path)")
            }
            DispatchQueue.main.async {
                completion(mergeError)
                self.appendGroup.leave()
            }
        }
    }

    /// Writes the encoded samples of each source, one after another, into a
    /// new file without re-encoding them.
    ///
    /// AVAssetExportSession can't pass AAC through here, as each recording
    /// carries encoder priming that may only be trimmed at the file edges.
    private func writeSamples(of sources: [URL], to url: URL, fileType: AVFileType) throws {
        var outputs: [(AVAssetReader, AVAssetReaderTrackOutput)] = []
        var formatHint: CMFormatDescription?
        for source in sources {
            let asset = AVURLAsset(url: source)
            guard let (track, formats) = try loadAudioTrack(of: asset) else { continue }
            let reader = try AVAssetReader(asset: asset)
            let output = AVAssetReaderTrackOutput(track: track, outputSettings: nil)
            reader.add(output)
            outputs.append((reader, output))
            if formatHint == nil {
                formatHint = formats.first
            }
        }
        guard let formatHint = formatHint else { throw appendError("Recording has no audio") }

        let writer = try AVAssetWriter(outputURL: url, fileType: fileType)
        let input = AVAssetWriterInput(mediaType: .audio, outputSettings: nil, sourceFormatHint: formatHint)
        input.expectsMediaDataInRealTime = false
        writer.add(input)
        guard writer.startWriting() else { throw writer.error ?? appendError("Unable to start writing") }
        writer.startSession(atSourceTime: .zero)
        for (reader, _) in outputs {
            guard reader.startReading() else { throw reader.error ?? appendError("Unable to read recording") }
        }

        var index = 0
        var offset = CMTime.zero
        var start: CMTime?
        var failure: Error?
        let done = DispatchSemaphore(value: 0)
        input.requestMediaDataWhenReady(on: DispatchQueue(label: "audio_waveforms.append")) {
            func finish(_ error: Error? = nil) {
                failure = error
                input.markAsFinished()
                done.signal()
            }
            while input.isReadyForMoreMediaData {
                let (reader, output) = outputs[index]
                guard let buffer = output.copyNextSampleBuffer() else {
                    if reader.status == .failed {
                        finish(reader.error ?? self.appendError("Unable to read recording"))
                        return
                    }
                    index += 1
                    start = nil
                    if index == outputs.count {
                        finish()
                        return
                    }
                    continue
                }
                // Skip marker buffers, as appending them ends the track early.
                guard CMSampleBufferGetNumSamples(buffer) > 0 else { continue }
                if start == nil {
                    start = CMSampleBufferGetPresentationTimeStamp(buffer)
                }
                let shifted: CMSampleBuffer
                do {
                    shifted = try self.shiftTiming(of: buffer, by: offset - start!)
                } catch {
                    finish(error)
                    return
                }
                // Priming may only be trimmed at the start and end of the file.
                if index > 0 {
                    CMRemoveAttachment(shifted, key: kCMSampleBufferAttachmentKey_TrimDurationAtStart)
                }
                if index < outputs.count - 1 {
                    CMRemoveAttachment(shifted, key: kCMSampleBufferAttachmentKey_TrimDurationAtEnd)
                }
                guard input.append(shifted) else {
                    finish(writer.error ?? self.appendError("Unable to append samples"))
                    return
                }
                offset = CMSampleBufferGetPresentationTimeStamp(shifted) + CMSampleBufferGetDuration(shifted)
            }
        }
        done.wait()
        if let failure = failure {
            writer.cancelWriting()
            throw failure
        }
        let finished = DispatchSemaphore(value: 0)
        writer.finishWriting { finished.signal() }
        finished.wait()
        if writer.status != .completed { throw writer.error ?? appendError("Unable to finish writing") }
    }

    /// Loads the first audio track of `asset` and its format descriptions.
    /// Blocks, so it must not be called on the main thread.
    private func loadAudioTrack(of asset: AVURLAsset) throws -> (AVAssetTrack, [CMFormatDescription])? {
        if #available(iOS 15.0, *) {
            final class Loaded { var result: Result<(AVAssetTrack, [CMFormatDescription])?, Error> = .success(nil) }
            let loaded = Loaded()
            let done = DispatchSemaphore(value: 0)
            Task {
                do {
                    if let track = try await asset.loadTracks(withMediaType: .audio).first {
                        loaded.result = .success((track, try await track.load(.formatDescriptions)))
                    }
                } catch {
                    loaded.result = .failure(error)
                }
                done.signal()
            }
            done.wait()
            return try loaded.result.get()
        }
        guard let track = asset.tracks(withMediaType: .audio).first else { return nil }
        return (track, track.formatDescriptions as? [CMFormatDescription] ?? [])
    }

    private func shiftTiming(of buffer: CMSampleBuffer, by offset: CMTime) throws -> CMSampleBuffer {
        var count: CMItemCount = 0
        CMSampleBufferGetSampleTimingInfoArray(buffer, entryCount: 0, arrayToFill: nil, entriesNeededOut: &count)
        var timing = [CMSampleTimingInfo](repeating: CMSampleTimingInfo(), count: count)
        CMSampleBufferGetSampleTimingInfoArray(buffer, entryCount: count, arrayToFill: &timing, entriesNeededOut: &count)
        for i in 0..<count {
            timing[i].presentationTimeStamp = timing[i].presentationTimeStamp + offset
            if timing[i].decodeTimeStamp.isValid {
                timing[i].decodeTimeStamp = timing[i].decodeTimeStamp + offset
            }
        }
        var shifted: CMSampleBuffer?
        let status = CMSampleBufferCreateCopyWithNewTiming(allocator: nil, sampleBuffer: buffer, sampleTimingEntryCount: count, sampleTimingArray: &timing, sampleBufferOut: &shifted)
        guard status == noErr, let shifted = shifted else { throw appendError("Unable to shift sample timing") }
        return shifted
    }

    private func appendError(_ message: String) -> NSError {
        return NSError(domain: Constants.audioWaveforms, code: -1, userInfo: [NSLocalizedDescriptionKey: message])
    }

    /// File type to append resumed audio with, or nil if AVAssetWriter can't
    /// write this file's format (e.g. ADTS `.aac`).
    private func getFileType(_ url: URL) -> AVFileType? {
        switch url.pathExtension.lowercased() {
        case "wav", "wave":
            return .wav
        case "caf":
            return .caf
        case "aif", "aiff":
            return .aiff
        case "aifc":
            return .aifc
        case "m4a":
            return .m4a
        case "mp4":
            return .mp4
        case "3gp":
            return .mobile3GPP
        case "3g2":
            return .mobile3GPP2
        default:
            return nil
        }
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
