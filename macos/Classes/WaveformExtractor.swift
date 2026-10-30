import AVFoundation
import Accelerate

/// Extracts waveform data from audio files on macOS.
/// Processes audio frames and computes RMS values for visualization.

public class WaveformExtractor {

    public private(set) var audioFile: AVAudioFile?
    private var result: FlutterResult
    var flutterChannel: FlutterMethodChannel
    private var waveformData = [Float]()
    var progress: Float = 0.0
    var channelCount: Int = 1
    private var currentProgress: Float = 0.0
    private let abortWaveformDataQueue = DispatchQueue(
        label: "WaveformExtractor",
        attributes: .concurrent
    )

    private var _abortGetWaveformData: Bool = false

    /// Controls whether waveform extraction should be aborted.
    /// Uses a concurrent dispatch queue for thread-safe access.
    public var abortGetWaveformData: Bool {
        get {
            _abortGetWaveformData
        }
        set {
            abortWaveformDataQueue.async(flags: .barrier) {
                self._abortGetWaveformData = newValue
            }
        }
    }
    /// Initializes the extractor with an audio file URL.
    /// - Parameters:
    ///   - url: URL of the audio file
    ///   - flutterResult: Callback for completion or errors
    ///   - channel: Flutter method channel for progress updates
    /// - Throws: Throws if the audio file cannot be loaded

    public init(
        url: URL, flutterResult: @escaping FlutterResult,
        channel: FlutterMethodChannel
    ) throws {
        result = flutterResult
        self.flutterChannel = channel
        do {
            audioFile = try AVAudioFile(forReading: url)
        } catch {
            audioFile = nil
            result(
                FlutterError(
                    code: Constants.audioWaveforms,
                    message: error.localizedDescription,
                    details:
                        "Couldn't initialise AVAudioFile from \(url.absoluteString)"
                ))

        }
    }

    deinit {
        audioFile = nil
    }

    /// Extracts waveform data from the audio file asynchronously.
    /// Processes audio in chunks and calculates RMS values for visualization.
    /// - Parameters:
    ///   - samplesPerPixel: Number of samples to aggregate per pixel
    ///   - offset: Starting position in samples
    ///   - length: Number of samples to process
    ///   - playerKey: Identifier for the extraction task
    ///   - onExtractionComplete: Callback with the extracted waveform data

    public func extractWaveform(
        samplesPerPixel: Int?,
        offset: Int? = 0,
        length: UInt? = nil,
        playerKey: String,
        onExtractionComplete: ([Float]?) -> Void
    ) async {
        guard let audioFile = audioFile else {
            return
        }

        /// Prevent division by zero, + minimum resolution
        let samplesPerPixel = max(1, samplesPerPixel ?? 100)
        let currentFrame = audioFile.framePosition
        let totalFrames = AVAudioFrameCount(audioFile.length)
        var framesPerBuffer = totalFrames / AVAudioFrameCount(samplesPerPixel)

        guard
            let rmsBuffer = AVAudioPCMBuffer(
                pcmFormat: audioFile.processingFormat,
                frameCapacity: framesPerBuffer
            )
        else {
            return
        }

        let channelCount = Int(audioFile.processingFormat.channelCount)
        let waveformStorage = WaveformStorage(
            channelCount: channelCount,
            size: samplesPerPixel
        )

        let startIndex = max(
            0, offset ?? Int(currentFrame / Int64(framesPerBuffer))
        )
        let endIndex = min(
            samplesPerPixel,
            startIndex
                + (length.map {
                    Int($0)
                } ?? samplesPerPixel)
        )

        if startIndex > endIndex {
            sendErrorToFlutter(
                message: "Offset is larger than total length.",
                details: "Please select less number of samples"
            )
            return
        }

        var startFrame: AVAudioFramePosition =
            offset == nil
            ? currentFrame : Int64(startIndex * Int(framesPerBuffer))

        for i in startIndex..<endIndex {
            if abortGetWaveformData {
                audioFile.framePosition = currentFrame
                abortGetWaveformData = false
                return
            }

            do {
                audioFile.framePosition = startFrame
                try audioFile.read(into: rmsBuffer, frameCount: framesPerBuffer)
            } catch {
                sendErrorToFlutter(
                    message:
                        "Couldn't read buffer. \(error.localizedDescription)"
                )
                return
            }

            guard let floatData = rmsBuffer.floatChannelData else {
                return
            }

            for channel in 0..<channelCount {
                /// Calculating RMS(Root mean square)
                var rmsValue: Float = 0.0
                vDSP_rmsqv(
                    floatData[channel], 1, &rmsValue,
                    vDSP_Length(rmsBuffer.frameLength)
                )
                await waveformStorage.update(
                    channel: channel, index: i, value: rmsValue
                )
            }

            let progress =
                Float(i - startIndex + 1) / Float(endIndex - startIndex)
            await sendWaveformDataToFlutter(
                waveformStorage: waveformStorage,
                progress: progress,
                playerKey: playerKey
            )

            startFrame += AVAudioFramePosition(framesPerBuffer)
            if startFrame + AVAudioFramePosition(framesPerBuffer) > totalFrames
            {
                framesPerBuffer = totalFrames - AVAudioFrameCount(startFrame)
                if framesPerBuffer <= 0 {
                    break
                }
            }
        }

        audioFile.framePosition = currentFrame
        let waveformData = await waveformStorage.getData()
        let data = getChannelMean(data: waveformData)
        onExtractionComplete(data)
    }

    func getChannelMean(data: FloatChannelData) -> [Float] {
        var resultWaveform = [Float]()

        if channelCount == 2, !data[0].isEmpty, !data[1].isEmpty {
            resultWaveform = zip(data[0], data[1]).map {
                ($0 + $1) / 2
            }
        } else if !data[0].isEmpty {
            resultWaveform = data[0]
        } else if !data[1].isEmpty {
            resultWaveform = data[1]
        } else {
            sendErrorToFlutter(
                message: "Cannot get waveform mean",
                details: "Both audio channels are null"
            )
        }
        return resultWaveform
    }

    public func cancel() {
        abortGetWaveformData = true
    }

    private func sendWaveformDataToFlutter(
        waveformStorage: WaveformStorage,
        progress: Float,
        playerKey: String
    ) async {
        let waveformData = await waveformStorage.getData()
        let meanData = getChannelMean(data: waveformData)

        DispatchQueue.main.async {
            self.flutterChannel.invokeMethod(
                Constants.onCurrentExtractedWaveformData,
                arguments: [
                    Constants.waveformData: meanData,
                    Constants.progress: progress,
                    Constants.playerKey: playerKey,
                ]
            )
        }
    }

    private func sendErrorToFlutter(message: String, details: String? = nil) {
        DispatchQueue.main.async {
            self.result(
                FlutterError(
                    code: Constants.audioWaveforms,
                    message: message,
                    details: details
                )
            )
        }
    }
}

actor WaveformStorage {
    private var data: [[Float]]

    init(channelCount: Int, size: Int) {
        data = Array(
            repeating: [Float](repeating: 0, count: size), count: channelCount)
    }

    func update(channel: Int, index: Int, value: Float) {
        data[channel][index] = value
    }

    func getData() -> [[Float]] {
        return data
    }
}
