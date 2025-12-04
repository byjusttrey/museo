// Artifact.swift

import Foundation

struct Artifact: Identifiable, Codable, Hashable {
    let id: UUID
    var folderID: UUID
    var type: ArtifactType

    var title: String
    var body: String?

    var x: Double
    var y: Double

    var imageData: Data?
    var frameName: String?
    var imageScale: CGFloat?
    var imageOffsetX: CGFloat?
    var imageOffsetY: CGFloat?

    var createdAt: Date

    // NEW
    var videoURL: URL?
    var audioURL: URL?
    var audioDescription: String?
    var audioDuration: TimeInterval?

    init(id: UUID = UUID(),
         folderID: UUID,
         type: ArtifactType,
         title: String,
         body: String? = nil,
         x: Double = 0,
         y: Double = 0,
         imageData: Data? = nil,
         frameName: String? = nil,
         imageScale: CGFloat? = nil,
         imageOffsetX: CGFloat? = nil,
         imageOffsetY: CGFloat? = nil,
         createdAt: Date = Date(),
         videoURL: URL? = nil,
         audioURL: URL? = nil,
         audioDescription: String? = nil,
         audioDuration: TimeInterval? = nil) {
        self.id = id
        self.folderID = folderID
        self.type = type
        self.title = title
        self.body = body
        self.x = x
        self.y = y
        self.imageData = imageData
        self.frameName = frameName
        self.imageScale = imageScale
        self.imageOffsetX = imageOffsetX
        self.imageOffsetY = imageOffsetY
        self.createdAt = createdAt
        self.videoURL = videoURL
        self.audioURL = audioURL
        self.audioDescription = audioDescription
        self.audioDuration = audioDuration
    }
}
