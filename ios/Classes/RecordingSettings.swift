//
//  RecordingSettings.swift
//  audio_waveforms
//
//  Created by Manoj Padiya on 30/12/24.
//

import Foundation

struct RecordingSettings {
    var path: String?
    var encoder : Int?
    var sampleRate : Int?
    var bitRate : Int?
    var useLegacy : Bool?
    var overrideAudioSession : Bool
    var linearPCMBitDepth : Int
    var linearPCMIsBigEndian : Bool
    var linearPCMIsFloat : Bool
    
    static func fromJson(_ json: [String: Any]) -> RecordingSettings {
        let path = json[Constants.path] as? String
        let encoder = json[Constants.encoder] as? Int
        let sampleRate = json[Constants.sampleRate] as? Int
        let bitRate = json[Constants.bitRate] as? Int
        let useLegacy = json[Constants.useLegacyNormalization] as? Bool
        let overrideAudioSession = json[Constants.overrideAudioSession] as? Bool ?? true
        let linearPCMBitDepth = json[Constants.linearPCMBitDepth] as? Int ?? 16
        let linearPCMIsBigEndian = json[Constants.linearPCMIsBigEndian] as? Bool ?? false
        let linearPCMIsFloat = json[Constants.linearPCMIsFloat] as? Bool ?? false
        
        return RecordingSettings(
            path: path,
            encoder: encoder,
            sampleRate: sampleRate,
            bitRate: bitRate,
            useLegacy: useLegacy,
            overrideAudioSession: overrideAudioSession,
            linearPCMBitDepth: linearPCMBitDepth,
            linearPCMIsBigEndian: linearPCMIsBigEndian,
            linearPCMIsFloat: linearPCMIsFloat
        )
    }
}
