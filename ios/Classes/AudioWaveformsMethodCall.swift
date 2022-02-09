import AVFoundation

public class AudioWaveformsMethodCall: NSObject, AVAudioRecorderDelegate{
    var audioRecorder: AVAudioRecorder?
    var path: String?
    var hasPermission: Bool = false
    
    public func startRecording(_ result: @escaping FlutterResult,_ path: String?,_ encoder : Int?,_ sampleRate : Int?,_ fileNameFormat: String){
        let settings = [
            AVFormatIDKey: getEncoder(encoder ?? 0),
            AVSampleRateKey: sampleRate ?? 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        let options: AVAudioSession.CategoryOptions = [.defaultToSpeaker, .allowBluetooth]
        if (path == nil) {
            let directory = NSTemporaryDirectory()
            let date = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = fileNameFormat
            let fileName = dateFormatter.string(from: date) + ".aac"
            
            self.path = NSURL.fileURL(withPathComponents: [directory, fileName])?.absoluteString
        } else {
            self.path = path
        }
        
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, options: options)
            try AVAudioSession.sharedInstance().setActive(true)
            
            let url = URL(string: self.path!) ?? URL(fileURLWithPath: self.path!)
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            result(true)
        } catch {
            result(FlutterError(code: "", message: "Failed to start recording", details: nil))
        }
    }
    
    public func stopRecording(_ result: @escaping FlutterResult) {
        audioRecorder?.stop()
        audioRecorder = nil
        result(path)
    }
    
    public func pauseRecording(_ result: @escaping FlutterResult) {
        audioRecorder?.pause()
        result(false)
    }
    
    public func getDecibel(_ result: @escaping FlutterResult) {
        var amp = Float()
        audioRecorder?.updateMeters()
        amp = audioRecorder?.peakPower(forChannel: 0) ?? 0.0
        result(amp)
    }
    
    public func checkHasPermission(_ result: @escaping FlutterResult){
        switch AVAudioSession.sharedInstance().recordPermission{
            
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    self.hasPermission = allowed
                }
            }
            break
        case .denied:
            hasPermission = false
            break
        case .granted:
            hasPermission = true
            break
        @unknown default:
            hasPermission = false
            break
        }
        result(hasPermission)
    }
    public func getEncoder(_ enCoder: Int) -> Int {
        switch(enCoder) {
        case 1:
            return Int(kAudioFormatMPEG4AAC)
        case 2:
            return Int(kAudioFormatMPEGLayer1)
        case 3:
            return Int(kAudioFormatMPEGLayer2)
        case 4:
            return Int(kAudioFormatMPEGLayer3)
        case 5:
            return Int(kAudioFormatMPEG4AAC_ELD)
        case 6:
            return Int(kAudioFormatMPEG4AAC_HE)
        case 7:
            return Int(kAudioFormatOpus)
        case 8:
            return Int(kAudioFormatAMR)
        case 9:
            return Int(kAudioFormatAMR_WB)
        case 10:
            return Int(kAudioFormatLinearPCM)
        case 11:
            return Int(kAudioFormatAppleLossless)
        case 12:
            return Int(kAudioFormatMPEG4AAC_HE_V2)
        default:
            return Int(kAudioFormatMPEG4AAC)
        }
    }
}
