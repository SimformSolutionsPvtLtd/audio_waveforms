import AVFoundation
import Accelerate

/// Handles audio recording functionality on macOS using AVAudioEngine.
public class AudioRecorder: NSObject {
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var audioConverter: AVAudioConverter?
    private var path: String?
    private var audioUrl: URL?
    private var recordedDuration: CMTime = CMTime.zero
    private var flutterChannel: FlutterMethodChannel

    // Recording state
    // 'isPaused' tracks if recording is currently paused. Recording is considered active when 'isPaused' is false.
    // We do not need a separate 'isRecording' variable because the recording state is managed by the AVAudioEngine lifecycle and 'isPaused'.
    private var isPaused: Bool = false
    private var recordingSettings: RecordingSettings?
    private var bufferProcessor: AudioBufferProcessor

    init(channel: FlutterMethodChannel) {
        flutterChannel = channel
        bufferProcessor = AudioBufferProcessor(channel: channel)
        super.init()
    }

    /// Initiates audio recording with the specified settings.
    /// Checks microphone permissions before starting.
    /// - Parameters:
    ///   - result: Callback to return success or error
    ///   - recordingSettings: Configuration for the recording session
    func startRecording(
        _ result: @escaping FlutterResult,
        _ recordingSettings: RecordingSettings
    ) {
        checkAndRequestMicrophonePermission { [weak self] granted in
            guard let self = self else { return }
            if !granted {
                result(false)
                return
            }

            self.recordingSettings = recordingSettings

            // Determine file path
            if recordingSettings.path == nil {
                let documentDirectory = self.getDocumentDirectory(result)
                let date = Date()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = recordingSettings.fileNameFormat
                let fileName = dateFormatter.string(from: date) + ".m4a"
                self.path = "\(documentDirectory)/\(fileName)"
            } else {
                self.path = recordingSettings.path
            }

            guard let filePath = self.path else {
                result(
                    FlutterError(
                        code: Constants.audioWaveforms,
                        message: "Invalid file path", details: nil))
                return
            }

            self.audioUrl = URL(fileURLWithPath: filePath)

            guard let audioUrl = self.audioUrl else {
                result(
                    FlutterError(
                        code: Constants.audioWaveforms,
                        message: "Failed to create audio URL", details: nil))
                return
            }

            do {
                // Create AVAudioEngine
                self.audioEngine = AVAudioEngine()

                guard let audioEngine = self.audioEngine else {
                    result(
                        FlutterError(
                            code: Constants.audioWaveforms,
                            message: "Failed to create audio engine",
                            details: nil))
                    return
                }

                let inputNode = audioEngine.inputNode
                let recordingFormat = inputNode.outputFormat(forBus: 0)

                // Validate format
                guard
                    recordingFormat.channelCount > 0
                        && recordingFormat.sampleRate > 0
                else {
                    result(
                        FlutterError(
                            code: Constants.audioWaveforms,
                            message: "Invalid input format",
                            details:
                                "Ensure microphone is connected and accessible"
                        ))
                    return
                }

                // Create output format based on settings
                let sampleRate = Double(
                    recordingSettings.sampleRate ?? Constants.defaultSampleRate)
                let channels: AVAudioChannelCount = 1

                // Create the file format
                let audioFileSettings = self.getAudioFileSettings(
                    recordingSettings, sampleRate: sampleRate,
                    channels: channels)

                // For PCM formats, we need to specify more details
                let formatID = self.getEncoder(recordingSettings.encoder ?? 0)
                var fileFormat: AVAudioFormat?

                if formatID == Int(kAudioFormatLinearPCM) {
                    // PCM format
                    let bitDepth = recordingSettings.linearPCMBitDepth
                    let isFloat = recordingSettings.linearPCMIsFloat

                    let commonFormat: AVAudioCommonFormat
                    if isFloat {
                        if bitDepth == 64 {
                            commonFormat = .pcmFormatFloat64
                        } else {
                            commonFormat = .pcmFormatFloat32
                        }
                    } else if bitDepth == 32 {
                        commonFormat = .pcmFormatInt32
                    } else {
                        commonFormat = .pcmFormatInt16
                    }

                    // AVAudioFormat does not directly take isBigEndian, but we can document its use for file writing if needed
                    fileFormat = AVAudioFormat(
                        commonFormat: commonFormat,
                        sampleRate: sampleRate,
                        channels: channels,
                        interleaved: true
                    )
                    // Note: isBigEndian is handled in file settings, not AVAudioFormat constructor
                } else {
                    // Compressed format (AAC, etc.)
                    fileFormat = AVAudioFormat(
                        settings: audioFileSettings
                    )
                }

                guard fileFormat != nil else {
                    result(
                        FlutterError(
                            code: Constants.audioWaveforms,
                            message: "Failed to create audio format",
                            details: nil))
                    return
                }

                // Create AVAudioFile for writing
                // For compressed formats, we write PCM and the file handles compression
                do {
                    self.audioFile = try AVAudioFile(
                        forWriting: audioUrl,
                        settings: audioFileSettings
                    )
                } catch {
                    throw error
                }

                guard let audioFile = self.audioFile else {
                    result(
                        FlutterError(
                            code: Constants.audioWaveforms,
                            message: "Failed to create audio file", details: nil
                        ))
                    return
                }

                // Create intermediate PCM format for conversion
                // Use the file's processing format as target (this is PCM even for compressed files)
                let targetFormat = audioFile.processingFormat

                // Store target format for later converter creation
                let storedTargetFormat = targetFormat

                // Start the engine BEFORE installing tap to establish hardware format
                do {
                    try audioEngine.start()
                } catch {
                    self.cleanup()
                    result(
                        FlutterError(
                            code: Constants.audioWaveforms,
                            message: "Failed to start audio engine",
                            details: error.localizedDescription
                        )
                    )
                    return
                }

                // Attach a tap to the input node to receive real-time audio buffers from the microphone.
                // This is required for capturing, processing, and saving audio input in custom ways.
                // Use nil format to use the input node's actual hardware format
                let bufferSize: AVAudioFrameCount = 4096
                inputNode.installTap(
                    onBus: 0, bufferSize: bufferSize, format: nil
                ) { [weak self] (buffer: AVAudioPCMBuffer, time: AVAudioTime) in
                    // Only process buffer if not paused. Recording is active when 'isPaused' is false.
                    guard let self = self, !self.isPaused else {
                        return
                    }

                    do {
                        // Create or verify converter with actual buffer format
                        if self.audioConverter == nil
                            || self.audioConverter!.inputFormat != buffer.format
                        {
                            guard
                                let newConverter = AVAudioConverter(
                                    from: buffer.format, to: storedTargetFormat)
                            else {
                                return
                            }
                            self.audioConverter = newConverter
                        }

                        // Convert buffer to intermediate PCM format
                        guard let converter = self.audioConverter else {
                            return
                        }

                        let outputFormat = converter.outputFormat

                        // Calculate the output buffer capacity
                        let capacity = AVAudioFrameCount(
                            Double(buffer.frameLength)
                                * (outputFormat.sampleRate
                                    / buffer.format.sampleRate))
                        guard
                            let convertedBuffer = AVAudioPCMBuffer(
                                pcmFormat: outputFormat, frameCapacity: capacity
                            )
                        else {
                            return
                        }

                        var convError: NSError?
                        let inputBlock: AVAudioConverterInputBlock = {
                            inNumPackets, outStatus in
                            outStatus.pointee = .haveData
                            return buffer
                        }

                        converter.convert(
                            to: convertedBuffer, error: &convError,
                            withInputFrom: inputBlock)

                        if let convError {
                            throw convError
                        }

                        // Write converted buffer to file
                        do {
                            try self.audioFile?.write(from: convertedBuffer)
                        } catch {
                            throw error
                        }

                        // Use AudioBufferProcessor to handle amplitude and byte sending
                        self.bufferProcessor.processAndSend(
                            buffer: buffer, convertedBuffer: convertedBuffer)

                    } catch {
                        result(
                            FlutterError(
                                code: Constants.audioWaveforms,
                                message:
                                    "Recording error during buffer processing",
                                details: error.localizedDescription
                            )
                        )
                    }
                }

                // Recording starts when AVAudioEngine is started and 'isPaused' is false.
                self.isPaused = false
                result(true)

            } catch {
                self.cleanup()
                result(
                    FlutterError(
                        code: Constants.audioWaveforms,
                        message: "Failed to start recording",
                        details: error.localizedDescription))
            }
        }
    }

    /// Stops the current recording session and returns file information.
    /// - Parameter result: Callback with file path and duration
    public func stopRecording(_ result: @escaping FlutterResult) {
        // Stop recording by stopping AVAudioEngine and marking as paused.
        isPaused = false

        // Stop the engine
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)

        audioFile = nil
        audioConverter = nil

        // Get duration
        if let audioUrl = audioUrl {
            let asset = AVURLAsset(url: audioUrl)

            if #available(macOS 12.0, *) {
                Task {
                    do {
                        recordedDuration = try await asset.load(.duration)
                        sendResult(
                            result,
                            duration: Int(recordedDuration.seconds * 1000))
                    } catch {
                        sendResult(result, duration: Int(CMTime.zero.seconds))
                    }
                }
            } else {
                recordedDuration = asset.duration
                sendResult(
                    result, duration: Int(recordedDuration.seconds * 1000))
            }
        } else {
            sendResult(result, duration: Int(CMTime.zero.seconds))
        }
    }

    private func sendResult(_ result: @escaping FlutterResult, duration: Int) {
        var params = [String: Any?]()
        params[Constants.resultFilePath] = path
        params[Constants.resultDuration] = duration
        result(params)
    }

    /// Pauses the current recording session.
    /// - Parameter result: Callback to return success status
    public func pauseRecording(_ result: @escaping FlutterResult) {
        isPaused = true
        result(false)  // Return false to indicate paused state (not actively recording)
    }

    /// Resumes a paused recording session.
    /// - Parameter result: Callback to return success status
    public func resumeRecording(_ result: @escaping FlutterResult) {
        isPaused = false
        result(true)
    }

    /// Checks and requests microphone recording permission.
    /// - Parameter result: Callback with permission status (true/false)
    public func checkHasPermission(_ result: @escaping FlutterResult) {
        checkAndRequestMicrophonePermission { granted in
            result(granted)
        }
    }

    /// Centralized function to check and request microphone permission.
    /// - Parameter completion: Callback with permission status (true/false)
    private func checkAndRequestMicrophonePermission(
        _ completion: @escaping (Bool) -> Void
    ) {
        if #available(macOS 10.14, *) {
            let status = AVCaptureDevice.authorizationStatus(for: .audio)
            switch status {
            case .authorized:
                completion(true)
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    DispatchQueue.main.async {
                        completion(granted)
                    }
                }
            case .denied, .restricted:
                completion(false)
            @unknown default:
                completion(false)
            }
        } else {
            // For macOS versions below 10.14, assume permission is granted
            completion(true)
        }
    }

    private func getAudioFileSettings(
        _ recordingSettings: RecordingSettings, sampleRate: Double,
        channels: AVAudioChannelCount
    ) -> [String: Any] {
        var settings: [String: Any] = [
            AVFormatIDKey: getEncoder(recordingSettings.encoder ?? 0),
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channels,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        if let bitRate = recordingSettings.bitRate {
            settings[AVEncoderBitRateKey] = bitRate
        }

        let formatID = recordingSettings.encoder ?? 0
        if formatID == Constants.kAudioFormatLinearPCM {
            settings[AVLinearPCMBitDepthKey] =
                recordingSettings.linearPCMBitDepth
            settings[AVLinearPCMIsBigEndianKey] =
                recordingSettings.linearPCMIsBigEndian
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
    private func getDocumentDirectory(_ result: @escaping FlutterResult)
        -> String
    {
        let directory = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true)[0]
        let ifExists = FileManager.default.fileExists(atPath: directory)
        if directory.isEmpty {
            result(
                FlutterError(
                    code: Constants.audioWaveforms,
                    message: "The document directory path is empty",
                    details: nil))
            return ""
        } else if !ifExists {
            result(
                FlutterError(
                    code: Constants.audioWaveforms,
                    message: "The document directory doesn't exist",
                    details: nil))
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
        isPaused = false
    }

    deinit {
        cleanup()
    }
}
