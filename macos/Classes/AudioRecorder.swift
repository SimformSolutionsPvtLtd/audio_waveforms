import AVFoundation
import Accelerate

/// Audio recorder implementation for macOS.
/// 
/// Note: On macOS, AVAudioEngine conflicts with AVAudioRecorder when both try to 
/// access the microphone simultaneously. Unlike iOS which has AVAudioSession to 
/// coordinate audio resources, macOS lacks this coordination layer. Therefore,
/// this implementation uses only AVAudioRecorder for recording, and waveform
/// visualization is provided through periodic polling of getDecibel() instead
/// of real-time byte streaming.
public class AudioRecorder: NSObject, AVAudioRecorderDelegate{
    var audioRecorder: AVAudioRecorder?
    var path: String?
    var useLegacyNormalization: Bool = false
    var audioUrl: URL?
    var recordedDuration: CMTime = CMTime.zero
    var flutterChannel: FlutterMethodChannel
    var bytesStreamEngine: RecorderBytesStreamEngine
    init(channel: FlutterMethodChannel){
        flutterChannel = channel
        bytesStreamEngine = RecorderBytesStreamEngine(channel: channel)
    }

    func startRecording(_ result: @escaping FlutterResult,_ recordingSettings: RecordingSettings){
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
    
    private func continueStartRecording(_ result: @escaping FlutterResult,_ recordingSettings: RecordingSettings){
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
        
        print("[AudioRecorder] Recording to path: \(self.path ?? "nil")")
        
        do {
            // macOS doesn't need audio session configuration like iOS
            audioUrl = URL(fileURLWithPath: self.path!)
            
            if(audioUrl == nil){
                print("[AudioRecorder] Failed to create audio URL")
                result(FlutterError(code: Constants.audioWaveforms, message: "Failed to initialise file URL", details: nil))
                return
            }
            
            // On macOS, use ONLY AVAudioRecorder for recording
            // AVAudioEngine conflicts with AVAudioRecorder on macOS
            audioRecorder = try AVAudioRecorder(url: audioUrl!, settings: settings as [String : Any])
            
            print("[AudioRecorder] AVAudioRecorder created successfully")
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            
            // Start recording
            let recordingStarted = audioRecorder?.record() ?? false
            print("[AudioRecorder] Recording started: \(recordingStarted)")
            
            if !recordingStarted {
                audioRecorder = nil
                result(FlutterError(code: Constants.audioWaveforms, message: "Failed to start audio recorder", details: "record() returned false"))
                return
            }
            
            // Note: On macOS, we skip AVAudioEngine (bytesStreamEngine) to avoid conflicts
            // Waveform visualization will use the getDecibel() method instead
            print("[AudioRecorder] Recording started successfully (without stream engine to avoid conflicts)")
            
            result(true)
        } catch {
            print("[AudioRecorder] Exception: \(error)")
            audioRecorder = nil
            result(FlutterError(code: Constants.audioWaveforms, message: "Failed to start recording", details: error.localizedDescription))
        }
    }
    
    public func stopRecording(_ result: @escaping FlutterResult) {
        audioRecorder?.stop()
        if(audioUrl != nil) {
            let asset = AVURLAsset(url:  audioUrl!)
            
            if #available(macOS 12.0, *) {
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
