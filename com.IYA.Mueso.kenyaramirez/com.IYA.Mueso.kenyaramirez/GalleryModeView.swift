// GalleryModeView.swift

import SwiftUI
import UIKit
import AVFoundation

struct GalleryModeView: View {
    @EnvironmentObject var store: MuseoStore
    @State private var showAppearanceSheet = false
    
    // Zoom state (pinch-to-zoom only, no pan)
    @State private var currentScale: CGFloat = 1.0
    @State private var finalScale: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                galleryBackground
                    .ignoresSafeArea()
                
                ScrollView([.vertical, .horizontal]) {
                    ZStack {
                        Color.clear
                            .frame(width: geo.size.width * 1.5,
                                   height: geo.size.height * 1.5)
                        
                        ForEach(store.filteredArtifacts) { artifact in
                            DraggableArtifactCard(artifact: artifact,
                                                  canvasSize: geo.size,
                                                  canvasScale: currentScale)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scaleEffect(currentScale)
                }
                .gesture(magnification)
            }
            .onAppear {
                // Ensure initial state is neutral
                currentScale = 1.0
                finalScale = 1.0
            }
        }
    }
    
    // Magnification gesture for pinch-to-zoom
    private var magnification: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                currentScale = min(max(finalScale * value, 0.75), 2.5)
            }
            .onEnded { _ in
                finalScale = currentScale
            }
    }
    @AppStorage("galleryBackgroundColorKey") private var galleryBackgroundColorKey: String = GalleryBackgroundColor.cream.rawValue
    
    private var galleryBackground: some View {
        Group {
            if let name = store.galleryWallpaperName {
                Image(name)
                    .resizable()
                    .scaledToFill()
            } else {
                // Use stored background color, defaulting to cream
                (GalleryBackgroundColor(rawValue: galleryBackgroundColorKey) ?? .cream).color
            }
        }
    }
    
    
    struct DraggableArtifactCard: View {
        @EnvironmentObject var store: MuseoStore
        let artifact: Artifact
        let canvasSize: CGSize
        let canvasScale: CGFloat
        
        @GestureState private var dragOffset: CGSize = .zero
        
        var body: some View {
            let basePosition = canvasPosition(for: artifact, in: canvasSize)
            
            artifactView
                .position(x: basePosition.x + dragOffset.width,
                          y: basePosition.y + dragOffset.height)
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            // Adjust translation for canvas scale
                            state = CGSize(
                                width: value.translation.width / canvasScale,
                                height: value.translation.height / canvasScale
                            )
                        }
                        .onEnded { value in
                            // Update artifact position accounting for canvas scale
                            let scaledTranslation = CGSize(
                                width: value.translation.width / canvasScale,
                                height: value.translation.height / canvasScale
                            )
                            let newX = artifact.x + scaledTranslation.width
                            let newY = artifact.y + scaledTranslation.height
                            store.updatePosition(for: artifact.id, x: newX, y: newY)
                        }
                )
                .onTapGesture {
                    store.editingArtifact = artifact
                }
        }
        
        private func canvasPosition(for artifact: Artifact, in size: CGSize) -> CGPoint {
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            return CGPoint(x: center.x + artifact.x, y: center.y + artifact.y)
        }
        
        @ViewBuilder
        private var artifactView: some View {
            let folder = store.folder(for: artifact)
            switch artifact.type {
            case .note:
                NoteArtifactView(artifact: artifact, folder: folder)
            case .image:
                ImageArtifactView(artifact: artifact, folder: folder)
            case .video:
                VideoArtifactView(artifact: artifact, folder: folder)
            case .audio:
                AudioArtifactView(artifact: artifact, folder: folder)
            }
        }
        
    }
}

// MARK: - Artifact Views (Shared)

// Note-style card
struct NoteArtifactView: View {
    let artifact: Artifact
    let folder: Folder?

    var body: some View {
        // Normalize the optional body once
        let bodyText = (artifact.body ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        VStack(alignment: .leading, spacing: 6) {
            Text(artifact.title.isEmpty ? "Untitled" : artifact.title)
                .font(MuseoFont.bodyTitle(16))
                .foregroundColor(MuseoColors.textPrimary)

            // Only show body if it actually has content
            if !bodyText.isEmpty {
                Text(bodyText)
                    .font(MuseoFont.paragraph(14))
                    .foregroundColor(MuseoColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Metadata section - DATE + FOLDER, with only a TINY top padding
            ArtifactMetadataView(artifact: artifact, folder: folder)
                .padding(.top, 4)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08),
                        radius: 10,
                        y: 4)
        )
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Image card
struct ImageArtifactView: View {
    let artifact: Artifact
    let folder: Folder?

    var body: some View {
            ZStack(alignment: .bottomLeading) {
                ZStack {
                    if let data = artifact.imageData,
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 200, height: 200)
                            .clipped()
                    } else {
                        // Fallback placeholder
                        HStack {
                            Image(systemName: "photo")
                            Text("Image")
                        }
                        .frame(width: 200, height: 200)
                        .background(Color.white)
                    }

                    if let frameName = artifact.frameName {
                        Image(frameName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 220, height: 220)
                    }
                }
                
                // Metadata overlay on image
                ArtifactMetadataView(artifact: artifact, folder: folder)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.85))
                    )
            }
            .frame(width: 220, height: 220)
            .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        }
}

// MARK: - Video card
struct VideoArtifactView: View {
    let artifact: Artifact
    let folder: Folder?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Image(systemName: "video.fill")
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(artifact.title.isEmpty ? "Video" : artifact.title)
                        .font(MuseoFont.bodyTitle(16))
                        .foregroundColor(MuseoColors.textPrimary)
                    Text("Tap to edit")
                        .font(MuseoFont.paragraph(14))
                        .foregroundColor(MuseoColors.textSecondary)
                }
                
                Spacer()
            }
            
            // Metadata section - DATE + FOLDER, with only a TINY top padding
            ArtifactMetadataView(artifact: artifact, folder: folder)
                .padding(.top, 4)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        )
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Audio card
struct AudioArtifactView: View {
    let artifact: Artifact
    let folder: Folder?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "waveform.circle.fill")
                    .font(.headline)                 // smaller icon

                VStack(alignment: .leading, spacing: 2) {
                    Text(artifact.title.isEmpty ? "Audio note" : artifact.title)
                        .font(MuseoFont.bodyTitle(14))
                        .foregroundColor(MuseoColors.textPrimary)

                    Text("Tap to edit")
                        .font(MuseoFont.paragraph(12))
                        .foregroundColor(MuseoColors.textSecondary)
                }

                Spacer()
            }
            
            // Metadata section - DATE + FOLDER, with only a TINY top padding
            ArtifactMetadataView(artifact: artifact, folder: folder)
                .padding(.top, 4)
        }
        .padding(12)
        .frame(maxWidth: 280, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        )
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Artifact Metadata View
struct ArtifactMetadataView: View {
    let artifact: Artifact
    let folder: Folder?
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.string(from: artifact.createdAt)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text(formattedDate)
                .font(MuseoFont.paragraph(11))
                .foregroundColor(MuseoColors.textPrimary)
            
            if let folder = folder {
                Text(folder.name)
                    .font(MuseoFont.paragraph(11))
                    .foregroundColor(folder.color.swiftUIColor)
            } else {
                Text("Unassigned")
                    .font(MuseoFont.paragraph(11))
                    .foregroundColor(MuseoColors.textPrimary)
            }
        }
    }
}
