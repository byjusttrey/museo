//
//  ArtifactType.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created by Trey Jennings on 12/1/25.
//


// ArtifactType.swift

import Foundation

enum ArtifactType: String, Codable, CaseIterable, Identifiable {
    case note
    case image
    case video
    case audio

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .note: return "Note"
        case .image: return "Image"
        case .video: return "Video"
        case .audio: return "Audio"
        }
    }

    var systemImageName: String {
        switch self {
        case .note: return "note.text"
        case .image: return "photo"
        case .video: return "video"
        case .audio: return "waveform"
        }
    }
}
