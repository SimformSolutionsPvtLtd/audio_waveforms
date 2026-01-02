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

    init(channel: FlutterMethodChannel) {
        flutterChannel = channel
    }

    func attach() throws {
        // Clean up any previous state
        if audioEngine.isRunning {
            detach()
        }
        
        let inputNode = audioEngine.inputNode
        
        // Get the input format from the input node
        audioFormat = inputNode.outputFormat(forBus: 0)
        
        // Install tap to capture audio data
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: audioFormat) { (buffer, time) in
            if self.paused {
                return
            }
            if let (convertedBytes, normalizedRms) = self.convertToFlutterType(buffer) {
                self.sendToFlutter(convertedBytes, normalizedRms: normalizedRms)
            }
        }
        
        // Prepare and start the audio engine
        audioEngine.prepare()
        try audioEngine.start()
    }

    func togglePause() {
        paused = !paused
    }

    func detach() {
        if audioEngine.isRunning {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
        }
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

    private func sendToFlutter(_ buffer: FlutterStandardTypedData, normalizedRms: Double) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            flutterChannel.invokeMethod(Constants.onAudioChunk, arguments: [
                Constants.bytes: buffer,
                Constants.normalisedRms: normalizedRms
            ])
        }
    }
}
