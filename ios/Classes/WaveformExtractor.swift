import Accelerate
import AVFoundation

public class WaveformExtractor {

    public private(set) var audioFile: AVAudioFile?
    private var result: FlutterResult
    var flutterChannel: FlutterMethodChannel
    private var waveformData = Array<Float>()
    var progress: Float = 0.0
    var channelCount: Int = 1
    private var currentProgress: Float = 0.0
    private let abortWaveformDataQueue = DispatchQueue(
        label: "WaveformExtractor",
        attributes: .concurrent
    )

    private var _abortGetWaveformData: Bool = false

    public var abortGetWaveformData: Bool {
        get { _abortGetWaveformData }
        set {
            abortWaveformDataQueue.async(flags: .barrier) {
                self._abortGetWaveformData = newValue
            }
        }
    }
    public init(url: URL, flutterResult: @escaping FlutterResult, channel: FlutterMethodChannel) throws {
        audioFile = try AVAudioFile(forReading: url)
        result = flutterResult
        self.flutterChannel = channel
    }

    deinit {
        audioFile = nil
    }

    public func extractWaveform(
        samplesPerPixel: Int?,
        offset: Int? = 0,
        length: UInt? = nil,
        playerKey: String
    ) async -> FloatChannelData? {
        guard let audioFile = audioFile else { return nil }
        
        /// Prevent division by zero, + minimum resolution
        let samplesPerPixel = max(1, samplesPerPixel ?? 100)
        let currentFrame = audioFile.framePosition
        let totalFrames = AVAudioFrameCount(audioFile.length)
        var framesPerBuffer = totalFrames / AVAudioFrameCount(samplesPerPixel)
        
        guard let rmsBuffer = AVAudioPCMBuffer(
            pcmFormat: audioFile.processingFormat,
            frameCapacity: framesPerBuffer
        ) else { return nil }
        
        let channelCount = Int(audioFile.processingFormat.channelCount)
        let waveformStorage = WaveformStorage(
            channelCount: channelCount,
            size: samplesPerPixel
        )
        
        let startIndex = max(
            0, offset ?? Int(currentFrame / Int64(framesPerBuffer))
        )
        let endIndex = min(
            samplesPerPixel, startIndex + (length.map { Int($0) } ?? samplesPerPixel)
        )
        
        if startIndex > endIndex {
            sendErrorToFlutter(
                message: "Offset is larger than total length.",
                details: "Please select less number of samples"
            )
            return nil
        }
        
        var startFrame: AVAudioFramePosition = offset == nil
        ? currentFrame
        : Int64(startIndex * Int(framesPerBuffer))
        
        for i in startIndex..<endIndex {
            if abortGetWaveformData {
                audioFile.framePosition = currentFrame
                abortGetWaveformData = false
                return nil
            }
            
            do {
                audioFile.framePosition = startFrame
                try audioFile.read(into: rmsBuffer, frameCount: framesPerBuffer)
            } catch {
                sendErrorToFlutter(
                    message: "Couldn't read buffer. \(error.localizedDescription)"
                )
                return nil
            }
            
            guard let floatData = rmsBuffer.floatChannelData else { return nil }
            
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
            
            progress = Float(i - startIndex + 1) / Float(endIndex - startIndex)
            await sendWaveformDataToFlutter(
                waveformStorage: waveformStorage,
                progress: progress,
                playerKey: playerKey
            )
            
            startFrame += AVAudioFramePosition(framesPerBuffer)
            if startFrame + AVAudioFramePosition(framesPerBuffer) > totalFrames {
                framesPerBuffer = totalFrames - AVAudioFrameCount(startFrame)
                if framesPerBuffer <= 0 { break }
            }
        }
        
        audioFile.framePosition = currentFrame
        return await waveformStorage.getData()
    }

    func getChannelMean(data: FloatChannelData) -> [Float] {
        var resultWaveform = [Float]()

        if channelCount == 2, !data[0].isEmpty, !data[1].isEmpty {
            resultWaveform = zip(data[0], data[1]).map { ($0 + $1) / 2 }
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
                    Constants.playerKey: playerKey
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
        data = Array(repeating: [Float](repeating: 0, count: size), count: channelCount)
    }

    func update(channel: Int, index: Int, value: Float) {
        data[channel][index] = value
    }

    func getData() -> [[Float]] {
        return data
    }
}
