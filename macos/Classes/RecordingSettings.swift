//
//  RecordingSettings.swift
//  audio_waveforms
//
//  Created by Manoj Padiya on 30/12/24.
//

import Foundation

/// Configuration settings for audio recording.
/// Encapsulates all parameters needed to configure the audio recorder.
struct RecordingSettings {
    var path: String?
    var encoder: Int?
    var sampleRate: Int?
    var bitRate: Int?
    var fileNameFormat: String
    var overrideAudioSession: Bool
    var linearPCMBitDepth: Int
    var linearPCMIsBigEndian: Bool
    var linearPCMIsFloat: Bool
    
    /// Creates RecordingSettings from a JSON dictionary.
    /// - Parameter json: Dictionary containing recording configuration parameters
    /// - Returns: RecordingSettings instance with parsed values
    static func fromJson(_ json: [String: Any]) -> RecordingSettings {
        let path = json[Constants.path] as? String
        let encoder = json[Constants.encoder] as? Int
        let sampleRate = json[Constants.sampleRate] as? Int
        let bitRate = json[Constants.bitRate] as? Int
        let fileNameFormat = Constants.fileNameFormat
        let overrideAudioSession = json[Constants.overrideAudioSession] as? Bool ?? true
        let linearPCMBitDepth = json[Constants.linearPCMBitDepth] as? Int ?? 16
        let linearPCMIsBigEndian = json[Constants.linearPCMIsBigEndian] as? Bool ?? false
        let linearPCMIsFloat = json[Constants.linearPCMIsFloat] as? Bool ?? false
        
        return RecordingSettings(
            path: path,
            encoder: encoder,
            sampleRate: sampleRate,
            bitRate: bitRate,
            fileNameFormat: fileNameFormat,
            overrideAudioSession: overrideAudioSession,
            linearPCMBitDepth: linearPCMBitDepth,
            linearPCMIsBigEndian: linearPCMIsBigEndian,
            linearPCMIsFloat: linearPCMIsFloat
        )
    }
}
