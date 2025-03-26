import Foundation
import AVFAudio

class Recorder {
    private let audioEngine = AVAudioEngine()
        private let inputNode: AVAudioInputNode
        private let format: AVAudioFormat
        private var audioFile: AVAudioFile?

        init() {
            self.inputNode = audioEngine.inputNode

            // PCM format settings
            let sampleRate: Double = 44100.0
            let channels: AVAudioChannelCount = 1


            self.format = inputNode.outputFormat(forBus: 0)
            print(self.format.sampleRate)
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,  // PCM format
                AVSampleRateKey: format.sampleRate,
                AVNumberOfChannelsKey: channels,
                AVLinearPCMBitDepthKey: 16,  // 16-bit depth
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsNonInterleaved: false
            ]
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentDirectory.appendingPathComponent("audio.wav")

            do {
                self.audioFile = try AVAudioFile(forWriting: fileURL, settings: format.settings)
            } catch {
                print(error)
            }

            do {
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print(error)
            }
        }

        func startRecording() {
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { (buffer, time) in
                do {
                    try self.audioFile?.write(from: buffer)
                } catch {
                    print("Error writing audio buffer: \(error)")
                }
            }

            do {
                try audioEngine.start()
                print("Recording started...")
            } catch {
                print(error)
            }

        }

        func stopRecording() {
            inputNode.removeTap(onBus: 0)
            audioEngine.stop()
            print("Recording stopped.")
        }

    func pauseRecording() {
        audioEngine.pause()
    }

    func resumeRecording() {
        do {
            try audioEngine.start()
        } catch {
            print(error.localizedDescription)
        }
    }
}
