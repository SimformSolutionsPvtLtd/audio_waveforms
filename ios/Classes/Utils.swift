enum DurationType {
    case Current
    case Max
}

struct Constants {
    static let methodChannelName = "simform_audio_waveforms_plugin/methods"
    static let audioWaveforms = "AudioWaveforms"
    static let startRecording = "startRecording"
    static let pauseRecording = "pauseRecording"
    static let stopRecording = "stopRecording"
    static let getDecibel = "getDecibel"
    static let checkPermission = "checkPermission"
    static let path = "path"
    static let encoder = "encoder"
    static let sampleRate = "sampleRate"
    static let fileNameFormat = "YY-MM-dd-HH-mm-ss"
    static let resumeRecording = "resumeRecording"

    static let kAudioFormatMPEG4AAC = 1
    static let kAudioFormatMPEGLayer1 = 2
    static let kAudioFormatMPEGLayer2 = 3
    static let kAudioFormatMPEGLayer3 = 4
    static let kAudioFormatMPEG4AAC_ELD = 5
    static let kAudioFormatMPEG4AAC_HE = 6
    static let kAudioFormatOpus = 7
    static let kAudioFormatAMR = 8
    static let kAudioFormatAMR_WB = 9
    static let kAudioFormatLinearPCM = 10
    static let kAudioFormatAppleLossless = 11
    static let kAudioFormatMPEG4AAC_HE_V2 = 12

    static let readAudioFile = "readAudioFile"
    static let durationEventChannel = "durationEventChannel"
    static let startPlayer = "startPlayer"
    static let stopPlayer = "stopPlayer"
    static let pausePlayer = "pausePlayer"
    static let seekTo = "seekTo"
    static let progress = "progress"
    static let setVolume = "setVolume"
    static let volume = "volume"
    static let getDuration = "getDuration"
    static let durationType = "durationType"
    static let preparePlayer = "preparePlayer"
    static let onCurrentDuration = "onCurrentDuration"
    static let current = "current"
    static let playerKey = "playerKey"
    static let stopAllPlayers = "stopAllPlayers"
    static let onDidFinishPlayingAudio = "onDidFinishPlayingAudio"
    static let finishMode = "finishMode"
    static let finishType = "finishType"
}

enum FinishMode : Int{
    case loop = 0
    case pause = 1
    case stop = 2
}
