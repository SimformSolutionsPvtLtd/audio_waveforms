import AVFoundation
import Accelerate

/// Handles audio recording functionality on macOS using AVAudioEngine.
public class AudioRecorder: NSObject {
    var audioEngine: AVAudioEngine?
    var audioFile: AVAudioFile?
    var audioConverter: AVAudioConverter?
    var path: String?
    var audioUrl: URL?
    var recordedDuration: CMTime = CMTime.zero
    var flutterChannel: FlutterMethodChannel
    var isRecording: Bool = false
    var isPaused: Bool = false
    
    // For amplitude monitoring
    var currentAmplitude: Float = 0.0
    let amplitudeQueue = DispatchQueue(label: "com.simform.audiowaveforms.amplitude")
    
    // Audio format settings
    var recordingSettings: RecordingSettings?
    
    init(channel: FlutterMethodChannel) {
        flutterChannel = channel
        super.init()
    }
    
    /// Initiates audio recording with the specified settings.
    /// Checks microphone permissions before starting.
    /// - Parameters:
    ///   - result: Callback to return success or error
    ///   - recordingSettings: Configuration for the recording session
    func startRecording(_ result: @escaping FlutterResult, _ recordingSettings: RecordingSettings) {
        // Check microphone permission first on macOS 10.14+
        if #available(macOS 10.14, *) {
            let status = AVCaptureDevice.authorizationStatus(for: .audio)
            
            if status == .notDetermined {
                AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                    DispatchQueue.main.async {
                        if granted {
                            self?.continueStartRecording(result, recordingSettings)
                        } else {
                            result(FlutterError(code: Constants.audioWaveforms, message: "Microphone permission denied", details: nil))
                        }
                    }
                }
                return
            } else if status == .denied || status == .restricted {
                result(FlutterError(code: Constants.audioWaveforms, message: "Microphone permission denied. Please enable it in System Preferences > Security & Privacy > Privacy > Microphone", details: nil))
                return
            }
        }
        
        continueStartRecording(result, recordingSettings)
    }
    
    /// Continues the recording setup after permission check.
    /// Creates the audio engine, file, and starts recording.
    /// - Parameters:
    ///   - result: Callback to return success or error
    ///   - recordingSettings: Configuration for the recording session
    /// Continues the recording setup after permission check.
    /// Creates the audio engine, file, and starts recording.
    /// - Parameters:
    ///   - result: Callback to return success or error
    ///   - recordingSettings: Configuration for the recording session
    private func continueStartRecording(_ result: @escaping FlutterResult, _ recordingSettings: RecordingSettings) {
        self.recordingSettings = recordingSettings
        
        // Determine file path
        if recordingSettings.path == nil {
            let documentDirectory = getDocumentDirectory(result)
            let date = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = recordingSettings.fileNameFormat
            let fileName = dateFormatter.string(from: date) + ".m4a"
            self.path = "\(documentDirectory)/\(fileName)"
        } else {
            self.path = recordingSettings.path
        }
        
        guard let filePath = self.path else {
            result(FlutterError(code: Constants.audioWaveforms, message: "Invalid file path", details: nil))
            return
        }
        
        audioUrl = URL(fileURLWithPath: filePath)
        
        guard let audioUrl = audioUrl else {
            result(FlutterError(code: Constants.audioWaveforms, message: "Failed to create audio URL", details: nil))
            return
        }
        
        do {
            // Create AVAudioEngine
            audioEngine = AVAudioEngine()
            
            guard let audioEngine = audioEngine else {
                result(FlutterError(code: Constants.audioWaveforms, message: "Failed to create audio engine", details: nil))
                return
            }
            
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            // Validate format
            guard recordingFormat.channelCount > 0 && recordingFormat.sampleRate > 0 else {
                result(FlutterError(code: Constants.audioWaveforms, message: "Invalid input format", details: "Ensure microphone is connected and accessible"))
                return
            }
            
            // Create output format based on settings
            let sampleRate = Double(recordingSettings.sampleRate ?? 44100)
            let channels: AVAudioChannelCount = 1
            
            // Create the file format
            let audioFileSettings = getAudioFileSettings(recordingSettings, sampleRate: sampleRate, channels: channels)
            
            // For PCM formats, we need to specify more details
            let formatID = getEncoder(recordingSettings.encoder ?? 0)
            var fileFormat: AVAudioFormat?
            
            if formatID == Int(kAudioFormatLinearPCM) {
                // PCM format
                let commonFormat: AVAudioCommonFormat = recordingSettings.linearPCMIsFloat ? .pcmFormatFloat32 : .pcmFormatInt16
                fileFormat = AVAudioFormat(
                    commonFormat: commonFormat,
                    sampleRate: sampleRate,
                    channels: channels,
                    interleaved: true
                )
            } else {
                // Compressed format (AAC, etc.)
                fileFormat = AVAudioFormat(
                    settings: audioFileSettings
                )
            }
            
            guard fileFormat != nil else {
                result(FlutterError(code: Constants.audioWaveforms, message: "Failed to create audio format", details: nil))
                return
            }
            
            // Create AVAudioFile for writing
            // For compressed formats, we write PCM and the file handles compression
            audioFile = try AVAudioFile(
                forWriting: audioUrl,
                settings: audioFileSettings
            )
            
            guard let audioFile = audioFile else {
                result(FlutterError(code: Constants.audioWaveforms, message: "Failed to create audio file", details: nil))
                return
            }
            
            // Create intermediate PCM format for conversion
            // Use the file's processing format as target (this is PCM even for compressed files)
            let targetFormat = audioFile.processingFormat
            
            // Create audio converter from input format to file's processing format
            guard let converter = AVAudioConverter(from: recordingFormat, to: targetFormat) else {
                result(FlutterError(code: Constants.audioWaveforms, message: "Failed to create audio converter", details: nil))
                return
            }
            audioConverter = converter
            
            // Install tap on input node to capture audio
            let bufferSize: AVAudioFrameCount = 4096
            
            inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: recordingFormat) { [weak self] (buffer, time) in
                guard let self = self, self.isRecording, !self.isPaused else { return }
                
                do {
                    // Convert buffer to intermediate PCM format
                    guard let converter = self.audioConverter else {
                        return
                    }
                    
                    let outputFormat = converter.outputFormat
                    
                    // Calculate the output buffer capacity
                    let capacity = AVAudioFrameCount(Double(buffer.frameLength) * (outputFormat.sampleRate / buffer.format.sampleRate))
                    guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: capacity) else {
                        return
                    }
                    
                    var error: NSError?
                    let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
                        outStatus.pointee = .haveData
                        return buffer
                    }
                    
                    converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputBlock)
                    
                    if error != nil {
                        return
                    }
                    
                    // Write converted buffer to file
                    try self.audioFile?.write(from: convertedBuffer)
                    
                    // Calculate amplitude and send chunk data (use original buffer for amplitude)
                    self.sendAmplitudeAndChunkData(buffer: buffer, convertedBuffer: convertedBuffer)
                    
                } catch {
                }
            }
            
            // Start the engine
            try audioEngine.start()
            
            isRecording = true
            isPaused = false
            
            result(true)
            
        } catch {
            cleanup()
            result(FlutterError(code: Constants.audioWaveforms, message: "Failed to start recording", details: error.localizedDescription))
        }
    }
    
    /// Sends amplitude and audio chunk data to Flutter.
    /// Calculates RMS from buffer and sends both audio bytes and normalized RMS.
    /// - Parameters:
    ///   - buffer: Original audio buffer for amplitude calculation
    ///   - convertedBuffer: Converted audio buffer for byte data
    private func sendAmplitudeAndChunkData(buffer: AVAudioPCMBuffer, convertedBuffer: AVAudioPCMBuffer) {
        // Get the first channel data from original buffer for amplitude calculation
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        
        // Calculate RMS using Accelerate framework (like iOS)
        var audioSamples = [Float32](repeating: 0.0, count: frameLength)
        for i in 0..<frameLength {
            audioSamples[i] = channelData[i]
        }
        
        var rms: Float = 0.0
        vDSP_rmsqv(
            audioSamples, 1, &rms,
            vDSP_Length(frameLength)
        )
        
        // Store amplitude
        amplitudeQueue.async { [weak self] in
            self?.currentAmplitude = rms
        }
        
        // Normalize RMS (like iOS: min with 1.0)
        let normalizedRms = Double(min(rms, 1.0))
        
        // Convert Float32 buffer to UInt8 bytes (like iOS)
        guard let convertedChannelData = convertedBuffer.floatChannelData?[0] else { return }
        let convertedFrameLength = Int(convertedBuffer.frameLength)
        
        var convertedSamples = [Float32](repeating: 0.0, count: convertedFrameLength)
        for i in 0..<convertedFrameLength {
            convertedSamples[i] = convertedChannelData[i]
        }
        
        let byteBuffer = convertedSamples.withUnsafeBufferPointer { bufferPointer in
            return Data(buffer: bufferPointer)
        }
        let convertedByteBuffer = FlutterStandardTypedData(bytes: byteBuffer)
        
        // Send both amplitude and bytes in a single call (like iOS)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.flutterChannel.invokeMethod(Constants.onAudioChunk, arguments: [
                Constants.bytes: convertedByteBuffer,
                Constants.normalisedRms: normalizedRms
            ])
        }
    }
    
    /// Stops the current recording session and returns file information.
    /// - Parameter result: Callback with file path and duration
    public func stopRecording(_ result: @escaping FlutterResult) {
        guard isRecording else {
            result(FlutterError(code: Constants.audioWaveforms, message: "Not recording", details: nil))
            return
        }
        
        isRecording = false
        isPaused = false
        
        // Stop the engine
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        // Close the file
        audioFile = nil
        audioConverter = nil
        
        // Get duration
        if let audioUrl = audioUrl {
            let asset = AVURLAsset(url: audioUrl)
            
            if #available(macOS 12.0, *) {
                Task {
                    do {
                        recordedDuration = try await asset.load(.duration)
                        sendResult(result, duration: Int(recordedDuration.seconds * 1000))
                    } catch {
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
    
    /// Pauses the current recording session.
    /// - Parameter result: Callback to return success status
    public func pauseRecording(_ result: @escaping FlutterResult) {
        guard isRecording && !isPaused else {
            result(false)
            return
        }
        
        isPaused = true
        result(false) // Return false to indicate paused state
    }
    
    /// Resumes a paused recording session.
    /// - Parameter result: Callback to return success status
    public func resumeRecording(_ result: @escaping FlutterResult) {
        guard isRecording && isPaused else {
            result(false)
            return
        }
        
        isPaused = false
        result(true)
    }
    
    /// Retrieves the current audio amplitude during recording.
    /// - Parameter result: Callback with the amplitude value
    public func getDecibel(_ result: @escaping FlutterResult) {
        var amplitude: Float = 0.0
        
        amplitudeQueue.sync {
            amplitude = currentAmplitude
        }
        
        // Convert RMS to linear like iOS does: pow(10, peakPower / 20)
        // Since we have RMS (0-1 range), just return it directly
        result(Double(amplitude))
    }
    
    /// Checks and requests microphone recording permission.
    /// - Parameter result: Callback with permission status (true/false)
    /// Checks and requests microphone recording permission.
    /// - Parameter result: Callback with permission status (true/false)
    public func checkHasPermission(_ result: @escaping FlutterResult) {
        // On macOS 10.14+, check microphone permission
        if #available(macOS 10.14, *) {
            let status = AVCaptureDevice.authorizationStatus(for: .audio)
            switch status {
            case .authorized:
                result(true)
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    DispatchQueue.main.async {
                        result(granted)
                    }
                }
            case .denied, .restricted:
                result(false)
            @unknown default:
                result(false)
            }
        } else {
            // On older macOS versions, assume permission is granted
            result(true)
        }
    }
    
    private func getAudioFileSettings(_ recordingSettings: RecordingSettings, sampleRate: Double, channels: AVAudioChannelCount) -> [String: Any] {
        var settings: [String: Any] = [
            AVFormatIDKey: getEncoder(recordingSettings.encoder ?? 0),
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channels,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        if let bitRate = recordingSettings.bitRate {
            settings[AVEncoderBitRateKey] = bitRate
        }
        
        let formatID = recordingSettings.encoder ?? 0
        if formatID == Constants.kAudioFormatLinearPCM {
            settings[AVLinearPCMBitDepthKey] = recordingSettings.linearPCMBitDepth
            settings[AVLinearPCMIsBigEndianKey] = recordingSettings.linearPCMIsBigEndian
            settings[AVLinearPCMIsFloatKey] = recordingSettings.linearPCMIsFloat
        }
        
        return settings
    }
    
    /// Converts encoder identifier to Core Audio format ID.
    /// - Parameter enCoder: Encoder type identifier
    /// - Returns: Core Audio format ID for the specified encoder
    public func getEncoder(_ encoder: Int) -> Int {
        switch encoder {
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
    
    /// Retrieves the document directory path for storing audio files.
    /// - Parameter result: Callback for error handling if directory is invalid
    /// - Returns: Document directory path or empty string on error
    /// Retrieves the document directory path for storing audio files.
    /// - Parameter result: Callback for error handling if directory is invalid
    /// - Returns: Document directory path or empty string on error
    private func getDocumentDirectory(_ result: @escaping FlutterResult) -> String {
        let directory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let ifExists = FileManager.default.fileExists(atPath: directory)
        if directory.isEmpty {
            result(FlutterError(code: Constants.audioWaveforms, message: "The document directory path is empty", details: nil))
            return ""
        } else if !ifExists {
            result(FlutterError(code: Constants.audioWaveforms, message: "The document directory doesn't exists", details: nil))
            return ""
        }
        return directory
    }
    
    /// Cleans up audio recording resources.
    private func cleanup() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        audioFile = nil
        audioConverter = nil
        isRecording = false
        isPaused = false
        currentAmplitude = 0.0
    }
    
    deinit {
        cleanup()
    }
}
