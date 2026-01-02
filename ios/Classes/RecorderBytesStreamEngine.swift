//
//  RecorderBytesStreamHandler.swift
//  audio_waveforms
//
//  Created by Ujas Majithiya on 10/04/25.
//

import Foundation
import AVFAudio
import Accelerate

class RecorderBytesStreamEngine {
    private var audioEngine = AVAudioEngine()
    private var audioFormat: AVAudioFormat?
    private var flutterChannel: FlutterMethodChannel
    private var paused: Bool = false
    private var totalFrames: AVAudioFramePosition = 0

    init(channel: FlutterMethodChannel) {
        flutterChannel = channel
    }

    func attach(result: @escaping FlutterResult, sampleRate: Int) {
        let inputNode = audioEngine.inputNode
        audioFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: audioFormat) { (buffer, time) in
            if self.paused {
                return
            }
            if let (convertedBytes, normalizedRms) = self.convertToFlutterType(buffer) {
                self.totalFrames += AVAudioFramePosition(buffer.frameLength)
                let effectiveSampleRate = buffer.format.sampleRate > 0 ? buffer.format.sampleRate : Double(sampleRate)
                let duration = Double(self.totalFrames) / effectiveSampleRate
                let milliseconds = Int(duration * 1000)
                self.sendToFlutter(
                    convertedBytes,
                    normalizedRms: normalizedRms,
                    milliSeconds: milliseconds
                )
            }
        }
        do {
            try audioEngine.start()
        } catch {
           result(FlutterError(code: Constants.audioWaveforms, message: "Error starting Audio Engine", details: error.localizedDescription))
        }
    }

    func togglePause() {
        paused = !paused
    }

    func detach() {
        totalFrames = 0
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
    }

    private func convertToFlutterType(_ buffer: AVAudioPCMBuffer) -> (FlutterStandardTypedData, Double)? {
        guard let channelData = buffer.floatChannelData?[0] else { return nil }
        let frameLength = Int(buffer.frameLength)

        // Convert Float32 buffer to UInt8 (byte array)
        var audioSamples = [Float32](repeating: 0.0, count: frameLength)
        var sumOfSquares: Float = 0.0

        for i in 0..<frameLength {
            audioSamples[i] = channelData[i]
            sumOfSquares += channelData[i] * channelData[i]
        }

        // Calculate RMS
        var rms: Float = 0.0
        vDSP_rmsqv(
            audioSamples, 1, &rms,
            vDSP_Length(frameLength)
        )

        // Normalize RMS to 0-1 range (assuming max amplitude is 1.0 for Float32)
        let normalizedRms = Double(min(rms, 1.0))

        let byteBuffer = audioSamples.withUnsafeBufferPointer { bufferPointer in
            return Data(buffer: bufferPointer)
        }
        let convertedBuffer = FlutterStandardTypedData(bytes: byteBuffer)
        return (convertedBuffer, normalizedRms)

    }

    private func sendToFlutter(_ buffer: FlutterStandardTypedData, normalizedRms: Double, milliSeconds: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            flutterChannel.invokeMethod(Constants.onAudioChunk, arguments: [
                Constants.bytes: buffer,
                Constants.normalisedRms: normalizedRms,
                Constants.recordedDuration: milliSeconds,
            ])
        }
    }
}
