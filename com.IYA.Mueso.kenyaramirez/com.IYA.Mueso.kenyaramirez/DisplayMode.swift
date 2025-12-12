//
//  DisplayMode.swift / MuseoStore.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created by Trey Jennings on 12/1/25.
//

import Foundation
import SwiftUI

// MARK: - Display Mode

enum DisplayMode {
    case gallery
    case simple
}

// MARK: - Store

@MainActor
final class MuseoStore: ObservableObject {

    // MARK: - Published state

    @Published var folders: [Folder]
    @Published var artifacts: [Artifact]

    @Published var displayMode: DisplayMode = .gallery

    // Filters
    @Published var searchText: String = ""
    @Published var selectedTypeFilter: ArtifactType? = nil
    @Published var selectedFolderFilter: Folder? = nil

    // Sheets / navigation
    @Published var isShowingQuickCapture = false
    @Published var isShowingSettings = false
    @Published var isShowingProfile = false
    @Published var isShowingGalleryEdit = false
    @Published var editingArtifact: Artifact? = nil
    @Published var activeFolderDetail: Folder? = nil

    // Layer actions modal (for Gallery)
    @Published var showingLayerActions: Bool = false
    @Published var layerActionsArtifactID: UUID? = nil

    // Gallery / wallpaper state – persisted
    @Published var galleryWallpaperName: String {
        didSet { save() }
    }

    @Published var galleryBackgroundModeRawValue: String {
        didSet { save() }
    }

    @Published var galleryBackgroundColorKey: String {
        didSet { save() }
    }

    // MARK: - Persistence snapshot

    private struct Snapshot: Codable {
        var folders: [Folder]
        var artifacts: [Artifact]
        var galleryWallpaperName: String
        var galleryBackgroundModeRawValue: String
        var galleryBackgroundColorKey: String
    }

    private static var saveURL: URL = {
        let docDir = FileManager.default.urls(for: .documentDirectory,
                                              in: .userDomainMask).first!
        return docDir.appendingPathComponent("museo-store.json")
    }()

    // MARK: - Init

    init() {
        // Reasonable defaults before load
        self.folders = []
        self.artifacts = []
        self.galleryWallpaperName = ""
        self.galleryBackgroundModeRawValue = GalleryBackgroundMode.color.rawValue
        self.galleryBackgroundColorKey = GalleryBackgroundColor.cream.rawValue

        load()
    }

    // MARK: - Derived collections

    var filteredArtifacts: [Artifact] {
        artifacts.filter { artifact in
            // Type filter
            if let typeFilter = selectedTypeFilter,
               artifact.type != typeFilter {
                return false
            }

            // Folder filter
            if let folderFilter = selectedFolderFilter,
               artifact.folderID != folderFilter.id {
                return false
            }

            // Search filter (title + body + folder name)
            if !searchText.isEmpty {
                let text = (artifact.title + " " + (artifact.body ?? ""))
                    .lowercased()
                let folderName = folder(for: artifact)?.name.lowercased() ?? ""
                let token = searchText.lowercased()

                if !text.contains(token) && !folderName.contains(token) {
                    return false
                }
            }

            return true
        }
    }

    var simpleViewFolders: [Folder] {
        folders
    }

    // MARK: - Helpers

    func folder(for artifact: Artifact) -> Folder? {
        folders.first { $0.id == artifact.folderID }
    }

    func artifacts(in folder: Folder) -> [Artifact] {
        artifacts.filter { $0.folderID == folder.id }
    }

    // MARK: - Mutations (folders)

    func addFolder(
        named name: String,
        color: Color = GalleryBackgroundColor.blue.color,
        priority: FolderPriority? = nil
    ) {
        let folder = Folder(name: name, color: color, priority: priority)
        folders.append(folder)
        save()
    }

    func renameFolder(_ folder: Folder, to newName: String) {
        guard let idx = folders.firstIndex(where: { $0.id == folder.id }) else { return }
        folders[idx].name = newName
        save()
    }

    func updateFolderPriority(_ folder: Folder, to priority: FolderPriority?) {
        guard let idx = folders.firstIndex(where: { $0.id == folder.id }) else { return }
        folders[idx].priority = priority
        save()
    }

    func updateFolderColor(_ folder: Folder, to color: Color) {
        guard let idx = folders.firstIndex(where: { $0.id == folder.id }) else { return }
        folders[idx].color = ColorData(color: color)
        save()
    }

    func deleteFolder(_ folder: Folder) {
        folders.removeAll { $0.id == folder.id }
        artifacts.removeAll { $0.folderID == folder.id }

        if activeFolderDetail?.id == folder.id {
            activeFolderDetail = nil
        }
        save()
    }

    // MARK: - Mutations (artifacts)

    func addNoteArtifact(
        title: String,
        body: String?,
        in folder: Folder
    ) {
        let x = Double.random(in: -120...120)
        let y = Double.random(in: -200...200)
        let artifact = Artifact(
            folderID: folder.id,
            type: .note,
            title: title,
            body: body,
            x: x,
            y: y
        )
        artifacts.append(artifact)
        save()
    }

    func addImageArtifact(
        imageData: Data,
        in folder: Folder,
        frameName: String?,
        imageScale: CGFloat? = nil,
        imageOffset: CGSize? = nil
    ) {
        let x = Double.random(in: -120...120)
        let y = Double.random(in: -200...200)
        let artifact = Artifact(
            folderID: folder.id,
            type: .image,
            title: "Image",
            body: nil,
            x: x,
            y: y,
            imageData: imageData,
            frameName: frameName,
            imageScale: imageScale,
            imageOffsetX: imageOffset?.width,
            imageOffsetY: imageOffset?.height
        )
        artifacts.append(artifact)
        save()
    }

    func addVideoArtifact(
        videoURL: URL,
        in folder: Folder,
        title: String? = nil
    ) {
        // Copy into app sandbox
        guard let persistedURL = persistMediaFile(from: videoURL) else {
            print("❌ Could not persist video file, skipping artifact creation")
            return
        }

        let x = Double.random(in: -120...120)
        let y = Double.random(in: -200...200)
        let artifact = Artifact(
            folderID: folder.id,
            type: .video,
            title: (title?.isEmpty == false) ? title! : "Video",
            body: nil,
            x: x,
            y: y,
            imageData: nil,
            frameName: nil,
            videoURL: persistedURL
        )
        artifacts.append(artifact)
        save()
    }


    func addAudioArtifact(
        audioURL: URL,
        in folder: Folder,
        title: String = "Audio note",
        audioDescription: String? = nil,
        audioDuration: TimeInterval? = nil
    ) {
        // Copy into app sandbox
        guard let persistedURL = persistMediaFile(from: audioURL) else {
            print("❌ Could not persist audio file, skipping artifact creation")
            return
        }

        let x = Double.random(in: -120...120)
        let y = Double.random(in: -200...200)
        let artifact = Artifact(
            folderID: folder.id,
            type: .audio,
            title: title,
            body: nil,
            x: x,
            y: y,
            audioURL: persistedURL,
            audioDescription: audioDescription,
            audioDuration: audioDuration
        )
        artifacts.append(artifact)
        save()
    }

    func update(artifact: Artifact) {
        guard let idx = artifacts.firstIndex(where: { $0.id == artifact.id }) else { return }
        artifacts[idx] = artifact
        save()
    }

    func delete(artifact: Artifact) {
        artifacts.removeAll { $0.id == artifact.id }
        save()
    }

    func updatePosition(for artifactID: UUID, x: Double, y: Double) {
        guard let index = artifacts.firstIndex(where: { $0.id == artifactID }) else { return }
        artifacts[index].x = x
        artifacts[index].y = y
        save()
    }
    
    private func persistMediaFile(from sourceURL: URL) -> URL? {
            do {
                let fileManager = FileManager.default
                let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

                let ext = sourceURL.pathExtension.isEmpty ? "dat" : sourceURL.pathExtension
                let fileName = UUID().uuidString + "." + ext
                let destURL = docsDir.appendingPathComponent(fileName)

                // If file already there, remove then copy to avoid errors
                if fileManager.fileExists(atPath: destURL.path) {
                    try fileManager.removeItem(at: destURL)
                }

                try fileManager.copyItem(at: sourceURL, to: destURL)
                return destURL
            } catch {
                print("❌ Failed to persist media file: \(error)")
                return nil
            }
        }

    // MARK: - Gallery wallpaper helpers

    func setGalleryWallpaper(name: String?) {
        galleryWallpaperName = name ?? ""
        // didSet on galleryWallpaperName calls save()
    }

    // MARK: - Layering (z-order)

    /// zIndex based on backing array order (later = on top).
    func zIndex(for artifactID: UUID) -> Double {
        guard let index = artifacts.firstIndex(where: { $0.id == artifactID }) else {
            return 0
        }
        return Double(index)
    }

    /// Move the artifact to the end of the array so it renders on top.
    func bringToFront(_ artifactID: UUID) {
        guard let index = artifacts.firstIndex(where: { $0.id == artifactID }) else { return }
        let item = artifacts.remove(at: index)
        artifacts.append(item)
        save()
    }

    /// Move the artifact to the beginning of the array so it renders behind others.
    func sendToBack(_ artifactID: UUID) {
        guard let index = artifacts.firstIndex(where: { $0.id == artifactID }) else { return }
        let item = artifacts.remove(at: index)
        artifacts.insert(item, at: 0)
        save()
    }

    // MARK: - Persistence

    private func load() {
        let url = Self.saveURL
        guard FileManager.default.fileExists(atPath: url.path) else { return }

        do {
            let data = try Data(contentsOf: url)
            let snapshot = try JSONDecoder().decode(Snapshot.self, from: data)

            self.folders = snapshot.folders
            self.artifacts = snapshot.artifacts
            self.galleryWallpaperName = snapshot.galleryWallpaperName
            self.galleryBackgroundModeRawValue = snapshot.galleryBackgroundModeRawValue
            self.galleryBackgroundColorKey = snapshot.galleryBackgroundColorKey
        } catch {
            print("❌ Failed to load MuseoStore snapshot:", error)
        }
    }

    private func save() {
        let snapshot = Snapshot(
            folders: folders,
            artifacts: artifacts,
            galleryWallpaperName: galleryWallpaperName,
            galleryBackgroundModeRawValue: galleryBackgroundModeRawValue,
            galleryBackgroundColorKey: galleryBackgroundColorKey
        )

        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: Self.saveURL, options: [.atomic])
        } catch {
            print("❌ Failed to save MuseoStore snapshot:", error)
        }
    }
}
