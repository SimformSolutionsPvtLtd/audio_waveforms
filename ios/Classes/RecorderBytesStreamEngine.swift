//
//  RecorderBytesStreamHandler.swift
//  audio_waveforms
//
//  Created by Ujas Majithiya on 10/04/25.
//

import Foundation
import AVFAudio

class RecorderBytesStreamEngine {
    private var audioEngine = AVAudioEngine()
    private var audioFormat: AVAudioFormat?
    private var flutterChannel: FlutterMethodChannel

    init(channel: FlutterMethodChannel) {
        flutterChannel = channel
    }

    func attach() {
        let inputNode = audioEngine.inputNode
        audioFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: audioFormat) { (buffer, time) in
            if let convertedBytes = self.convertToFlutterType(buffer) {
                self.sendToFlutter(convertedBytes)
            }
        }
        do {
            try audioEngine.start()
        } catch {
//            result(FlutterError(code: Constants.audioWaveforms, message: "Error starting Audio Engine", details: error.localizedDescription))
        }
    }

    func detach() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
    }

    private func convertToFlutterType(_ buffer: AVAudioPCMBuffer) -> FlutterStandardTypedData? {
        guard let channelData = buffer.floatChannelData?[0] else { return nil }
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
        return convertedBuffer

    }

    private func sendToFlutter(_ buffer: FlutterStandardTypedData) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            flutterChannel.invokeMethod(Constants.onAudioChunk, arguments: [
                Constants.bytes: buffer
            ])
        }
    }

    deinit {

    }
}
