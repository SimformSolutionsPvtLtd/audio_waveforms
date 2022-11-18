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
    private let abortWaveformDataQueue = DispatchQueue(label: "WaveformExtractor",
                                                       attributes: .concurrent)

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

    public func extractWaveform(samplesPerPixel: Int?,
                                offset: Int? = 0,
                                length: UInt? = nil, playerKey: String) -> FloatChannelData?
    {
        guard let audioFile = audioFile else { return nil }

        /// prevent division by zero, + minimum resolution
        let samplesPerPixel = max(1, samplesPerPixel ?? 100)

        let currentFrame = audioFile.framePosition

        let totalFrameCount = AVAudioFrameCount(audioFile.length)
        var framesPerBuffer: AVAudioFrameCount = totalFrameCount / AVAudioFrameCount(samplesPerPixel)

        guard let rmsBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat,
                                               frameCapacity: AVAudioFrameCount(framesPerBuffer)) else { return nil }

        channelCount = Int(audioFile.processingFormat.channelCount)
        var data = Array(repeating: [Float](zeros: samplesPerPixel), count: channelCount)

        var start: Int
        if let offset = offset, offset >= 0 {
            start = offset
        } else {
            start = Int(currentFrame / Int64(framesPerBuffer))
            if let offset = offset, offset < 0 {
                start += offset
            }

            if start < 0 {
                start = 0
            }
        }
        var startFrame: AVAudioFramePosition = offset == nil ? currentFrame : Int64(start * Int(framesPerBuffer))

        var end = samplesPerPixel
        if let length = length {
            end = start + Int(length)
        }

        if end > samplesPerPixel {
            end = samplesPerPixel
        }
        if start > end {
            result(FlutterError(code: Constants.audioWaveforms, message: "offset is larger than total length.", details: "Please select less number of samples"))
            return nil
        }

        for i in start ..< end {

            if abortGetWaveformData {
                audioFile.framePosition = currentFrame
                abortGetWaveformData = false
                return nil
            }

            do {
                audioFile.framePosition = startFrame
                /// Read portion of the buffer
                try audioFile.read(into: rmsBuffer, frameCount: framesPerBuffer)

            } catch let err as NSError {
                result(FlutterError(code: Constants.audioWaveforms, message: "Couldn't read into buffer. \(err)", details: nil))
                return nil
            }

            guard let floatData = rmsBuffer.floatChannelData else { return nil }
            /// Calculating RMS(Root mean square)
            for channel in 0 ..< channelCount {
                var rms: Float = 0.0
                vDSP_rmsqv(floatData[channel], 1, &rms, vDSP_Length(rmsBuffer.frameLength))
                data[channel][i] = rms

            }

            /// Update progress
            currentProgress += 1
            progress = currentProgress / Float(samplesPerPixel)

            /// Send to flutter channel
            flutterChannel.invokeMethod(Constants.onCurrentExtractedWaveformData, arguments: [
                Constants.waveformData: getChannelMean(data: data) as Any,
                Constants.progress: progress,
                Constants.playerKey: playerKey
            ])

            startFrame += AVAudioFramePosition(framesPerBuffer)

            if startFrame + AVAudioFramePosition(framesPerBuffer) > totalFrameCount {
                framesPerBuffer = totalFrameCount - AVAudioFrameCount(startFrame)
                if framesPerBuffer <= 0 { break }
            }
        }

        audioFile.framePosition = currentFrame

        return data
    }

    func getChannelMean(data: FloatChannelData) -> [Float] {
        waveformData.removeAll()
        if(channelCount == 2 && data[0].isEmpty == false && data[1].isEmpty == false) {
            for (ele1, ele2) in zip(data[0], data[1]) {
                waveformData.append((ele1 + ele2) / 2)
            }
        } else if(data[0].isEmpty == false) {
            waveformData = data[0]
        }
        else if (data[1].isEmpty == false) {
            waveformData = data[1]
        } else {
            result(FlutterError(code: Constants.audioWaveforms, message: "Can not get waveform mean", details: "Both audio channels are null"))
        }
        return waveformData
    }

    public func cancel() {
        abortGetWaveformData = true
    }
}
