import AVFoundation
import Accelerate

/// Processes audio buffers: calculates amplitude (RMS) and sends audio bytes to Flutter.
/// This class is responsible for real-time audio buffer processing during recording,
/// including RMS calculation and data transmission to Flutter.
public class AudioBufferProcessor {
    private var flutterChannel: FlutterMethodChannel

    public init(channel: FlutterMethodChannel) {
        self.flutterChannel = channel
    }

    /// Processes the buffer, calculates amplitude, and sends bytes to Flutter.
    /// This method:
    /// 1. Calculates RMS (Root Mean Square) from the original buffer for amplitude monitoring
    /// 2. Converts the processed buffer to bytes
    /// 3. Sends both the audio bytes and normalized RMS to Flutter
    ///
    /// - Parameters:
    ///   - buffer: Original audio buffer for amplitude calculation
    ///   - convertedBuffer: Converted audio buffer for byte data
    public func processAndSend(
        buffer: AVAudioPCMBuffer, convertedBuffer: AVAudioPCMBuffer
    ) {
        // Get the first channel data from original buffer for amplitude calculation
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)

        // Calculate RMS using Accelerate framework
        var audioSamples = [Float32](repeating: 0.0, count: frameLength)
        for i in 0..<frameLength {
            audioSamples[i] = channelData[i]
        }

        var rms: Float = 0.0
        vDSP_rmsqv(audioSamples, 1, &rms, vDSP_Length(frameLength))

        // Normalize RMS to 0-1 range (clamped at 1.0)
        let normalizedRms = Double(min(rms, 1.0))

        // Convert Float32 buffer to bytes for transmission to Flutter
        guard let convertedChannelData = convertedBuffer.floatChannelData?[0]
        else { return }
        let convertedFrameLength = Int(convertedBuffer.frameLength)

        var convertedSamples = [Float32](
            repeating: 0.0, count: convertedFrameLength)
        for i in 0..<convertedFrameLength {
            convertedSamples[i] = convertedChannelData[i]
        }

        let byteBuffer = convertedSamples.withUnsafeBufferPointer {
            bufferPointer in
            return Data(buffer: bufferPointer)
        }
        let convertedByteBuffer = FlutterStandardTypedData(bytes: byteBuffer)

        // Send both amplitude and bytes in a single call to Flutter
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.flutterChannel.invokeMethod(
                Constants.onAudioChunk,
                arguments: [
                    Constants.bytes: convertedByteBuffer,
                    Constants.normalisedRms: normalizedRms,
                ])
        }
    }
}
