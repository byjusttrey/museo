//
//  DisplayMode.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created by Trey Jennings on 12/1/25.
//


// MuseoStore.swift

import Foundation
import SwiftUI

enum DisplayMode {
    case gallery
    case simple
}

final class MuseoStore: ObservableObject {

    // MARK: - Published State

    @Published var folders: [Folder]
    @Published var artifacts: [Artifact]

    @Published var displayMode: DisplayMode = .gallery

    // Filters (simple stub for now)
    @Published var searchText: String = ""
    @Published var selectedTypeFilter: ArtifactType? = nil
    @Published var selectedFolderFilter: Folder? = nil

    // Sheet state
    @Published var isShowingQuickCapture = false
    @Published var isShowingSettings = false
    @Published var isShowingProfile = false
    @Published var isShowingGalleryEdit = false
    @Published var editingArtifact: Artifact? = nil
    
    // Detail state
    @Published var activeFolderDetail: Folder? = nil
    @Published var galleryWallpaperName: String? = nil



    // MARK: - Init with sample data

    init() {
        // Sample folders
        let photography = Folder(name: "Photography", color: .purple.opacity(0.6))
        let ideas = Folder(name: "Ideas", color: .orange.opacity(0.7))

        self.folders = [photography, ideas]

        self.artifacts = [
            Artifact(folderID: photography.id,
                     type: .note,
                     title: "December shoot",
                     body: "Wear the black dress you thrifted on Sunday",
                     x: -60, y: -40),
            Artifact(folderID: photography.id,
                     type: .note,
                     title: "Golden hour",
                     body: "Aim for 4:15–4:45pm for best light",
                     x: 40, y: 60),
            Artifact(folderID: ideas.id,
                     type: .note,
                     title: "COMP onboarding idea",
                     body: "Waitlist + referral like Polymarket",
                     x: -30, y: 110)
        ]
    }

    // MARK: - Derived collections

    var filteredArtifacts: [Artifact] {
        artifacts.filter { artifact in
            // Type filter
            if let typeFilter = selectedTypeFilter, artifact.type != typeFilter {
                return false
            }

            // Folder filter
            if let folderFilter = selectedFolderFilter,
               artifact.folderID != folderFilter.id {
                return false
            }

            // Search filter (check title & body & folder name)
            if !searchText.isEmpty {
                let text = (artifact.title + " " + (artifact.body ?? "")).lowercased()
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
        // In future can sort & filter; for now just all folders
        folders
    }

    // MARK: - Helpers

    func folder(for artifact: Artifact) -> Folder? {
        folders.first { $0.id == artifact.folderID }
    }

    func artifacts(in folder: Folder) -> [Artifact] {
        artifacts.filter { $0.folderID == folder.id }
    }

    // MARK: - Mutations

    func addFolder(named name: String, priority: FolderPriority = .low) {
        let folder = Folder(name: name, priority: priority)
        folders.append(folder)
    }
    
    func updateFolderPriority(_ folder: Folder, to priority: FolderPriority) {
        guard let idx = folders.firstIndex(where: { $0.id == folder.id }) else { return }
        folders[idx].priority = priority
    }

    func addNoteArtifact(title: String,
                         body: String?,
                         in folder: Folder) {
        // simple random-ish placement on canvas for now
        let x = Double.random(in: -120...120)
        let y = Double.random(in: -200...200)
        let artifact = Artifact(folderID: folder.id,
                                type: .note,
                                title: title,
                                body: body,
                                x: x,
                                y: y)
        artifacts.append(artifact)
    }

    func update(artifact: Artifact) {
        guard let idx = artifacts.firstIndex(where: { $0.id == artifact.id }) else { return }
        artifacts[idx] = artifact
    }

    func delete(artifact: Artifact) {
        artifacts.removeAll { $0.id == artifact.id }
    }
    
    func updatePosition(for artifactID: UUID, x: Double, y: Double) {
        guard let index = artifacts.firstIndex(where: { $0.id == artifactID }) else { return }
        artifacts[index].x = x
        artifacts[index].y = y
    }
    
    func addImageArtifact(imageData: Data,
                          in folder: Folder,
                          frameName: String?) {
        let x = Double.random(in: -120...120)
        let y = Double.random(in: -200...200)
        let artifact = Artifact(folderID: folder.id,
                                type: .image,
                                title: "Image",
                                body: nil,
                                x: x,
                                y: y,
                                imageData: imageData,
                                frameName: frameName)
        artifacts.append(artifact)
    }
    
    func renameFolder(_ folder: Folder, to newName: String) {
        guard let idx = folders.firstIndex(where: { $0.id == folder.id }) else { return }
        folders[idx].name = newName
    }
    
    func updateFolderColor(_ folder: Folder, to color: Color) {
        guard let idx = folders.firstIndex(where: { $0.id == folder.id }) else { return }
        folders[idx].color = ColorData(color: color)
    }

    func deleteFolder(_ folder: Folder) {
        folders.removeAll { $0.id == folder.id }
        artifacts.removeAll { $0.folderID == folder.id }

        if activeFolderDetail?.id == folder.id {
            activeFolderDetail = nil
        }
    }

    func addVideoArtifact(videoURL: URL,
                          in folder: Folder,
                          frameName: String?) {
        let x = Double.random(in: -120...120)
        let y = Double.random(in: -200...200)
        let artifact = Artifact(folderID: folder.id,
                                type: .video,
                                title: "Video",
                                body: nil,
                                x: x,
                                y: y,
                                imageData: nil,
                                frameName: frameName,
                                videoURL: videoURL)
        artifacts.append(artifact)
    }

    func addAudioArtifact(audioURL: URL,
                          in folder: Folder,
                          title: String = "Audio note") {
        let x = Double.random(in: -120...120)
        let y = Double.random(in: -200...200)
        let artifact = Artifact(folderID: folder.id,
                                type: .audio,
                                title: title,
                                body: nil,
                                x: x,
                                y: y,
                                audioURL: audioURL)
        artifacts.append(artifact)
    }

    func setGalleryWallpaper(name: String?) {
        galleryWallpaperName = name
    }

}
