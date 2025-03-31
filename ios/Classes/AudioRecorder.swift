import AVFoundation
import Accelerate

public class AudioRecorder: NSObject, AVAudioRecorderDelegate, FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink : @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = eventSink
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }

    var audioRecorder: AVAudioRecorder?
    var path: String?
    var useLegacyNormalization: Bool = false
    var audioUrl: URL?
    var recordedDuration: CMTime = CMTime.zero
    private var audioEngine = AVAudioEngine()
    private var audioFormat: AVAudioFormat?
    private var flutterChannel: FlutterEventChannel
    private var eventSink: FlutterEventSink?

    init(messenger: FlutterBinaryMessenger){
        flutterChannel = FlutterEventChannel(name: "onBufferData", binaryMessenger: messenger)
        super.init()
        flutterChannel.setStreamHandler(self)
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
            dateFormatter.dateFormat = Constants.fileNameFormat
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
            }
            audioRecorder = try AVAudioRecorder(url: audioUrl!, settings: settings as [String : Any])

            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            attachAudioEngineNode()
            result(true)
        } catch {
            result(FlutterError(code: Constants.audioWaveforms, message: "Failed to start recording", details: error.localizedDescription))
        }
    }

    public func stopRecording(_ result: @escaping FlutterResult) {
        audioRecorder?.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()

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
        audioRecorder = nil
    }

    private func sendResult(_ result: @escaping FlutterResult, duration:Int){
        var params = [String:Any?]()
        params[Constants.resultFilePath] = path
        params[Constants.resultDuration] = duration
        result(params)
    }

    public func pauseRecording(_ result: @escaping FlutterResult) {
        audioRecorder?.pause()
        result(false)
    }

    public func resumeRecording(_ result: @escaping FlutterResult) {
        audioRecorder?.record()
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
        } else if(!ifExists) {
            result(FlutterError(code: Constants.audioWaveforms, message: "The document directory does't exists", details: nil))
        }
        return directory
    }

    func attachAudioEngineNode(_ result: @escaping FlutterResult) {
        let inputNode = audioEngine.inputNode
        audioFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: audioFormat) { (buffer, time) in
            self.convertToFlutterType(buffer)
        }
        do {
            try audioEngine.start()
        } catch {
            result(FlutterError(code: Constants.audioWaveforms, message: "Error starting Audio Engine", details: error.localizedDescription))
        }
    }

    private func convertToFlutterType(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)

        // Convert Float32 buffer to UInt8 (byte array)
        var audioSamples = [Float32](repeating: 0.0, count: frameLength)
        for i in 0..<frameLength {
            audioSamples[i] = channelData[i]
        }

        let byteCount = frameLength * MemoryLayout<Float32>.size
        let byteBuffer = audioSamples.withUnsafeBufferPointer { bufferPointer in
            return Data(buffer: bufferPointer)
        }
        let convertedBuffer = FlutterStandardTypedData(bytes: byteBuffer)
        sendToFlutter(convertedBuffer)

    }

    private func sendToFlutter(_ buffer: FlutterStandardTypedData){
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            eventSink?(["buffer":buffer])
        }
    }
}
