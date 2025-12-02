// GalleryModeView.swift

import SwiftUI
import UIKit
import AVFoundation

struct GalleryModeView: View {
    @EnvironmentObject var store: MuseoStore
    @State private var showAppearanceSheet = false
    
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
                                                  canvasSize: geo.size)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
    private var galleryBackground: some View {
        Group {
            if let name = store.galleryWallpaperName {
                Image(name)
                    .resizable()
                    .scaledToFill()
            } else {
                MuseoColors.background
            }
        }
    }
    
    
    struct DraggableArtifactCard: View {
        @EnvironmentObject var store: MuseoStore
        let artifact: Artifact
        let canvasSize: CGSize
        
        @GestureState private var dragOffset: CGSize = .zero
        
        var body: some View {
            let basePosition = canvasPosition(for: artifact, in: canvasSize)
            
            artifactView
                .position(x: basePosition.x + dragOffset.width,
                          y: basePosition.y + dragOffset.height)
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation
                        }
                        .onEnded { value in
                            let newX = artifact.x + value.translation.width
                            let newY = artifact.y + value.translation.height
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
            switch artifact.type {
            case .note:
                NoteArtifactView(artifact: artifact)
            case .image:
                ImageArtifactView(artifact: artifact)
            case .video:
                VideoArtifactView(artifact: artifact)
            case .audio:
                AudioArtifactView(artifact: artifact)
            }
        }
        
    }
    
    // Note-style card
    // MARK: - Note card

    struct NoteArtifactView: View {
        let artifact: Artifact

        var body: some View {
            // Normalize the optional body once
            let bodyText = (artifact.body ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            return VStack(alignment: .leading, spacing: 6) {
                Text(artifact.title.isEmpty ? "Untitled" : artifact.title)
                    .font(MuseoFont.bodyTitle(16))
                    .foregroundColor(MuseoColors.textPrimary)

                // Only show body if it actually has content
                if !bodyText.isEmpty {
                    Text(bodyText)
                        .font(MuseoFont.paragraph(14))
                        .foregroundColor(MuseoColors.textSecondary)
                        .lineLimit(3)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.08),
                            radius: 10,
                            y: 4)
            )
        }
    }

    
    // MARK: - Image card
    struct ImageArtifactView: View {
        let artifact: Artifact

        var body: some View {
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
            .frame(width: 220, height: 220)
            .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        }
    }

    
    // MARK: - Video card
    
    struct VideoArtifactView: View {
        let artifact: Artifact
        
        var body: some View {
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
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
            )
        }
    }
    
    // MARK: - Audio card
    
    struct AudioArtifactView: View {
        let artifact: Artifact

        var body: some View {
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
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: 280, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
            )
        }
    }

}
