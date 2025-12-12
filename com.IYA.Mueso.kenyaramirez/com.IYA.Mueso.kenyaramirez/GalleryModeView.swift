import SwiftUI
import UIKit
import AVFoundation

struct GalleryModeView: View {
    @EnvironmentObject var store: MuseoStore
    @State private var showAppearanceSheet = false
    
    // Zoom state
    @State private var currentScale: CGFloat = 1.0
    @State private var finalScale: CGFloat = 1.0
    
    // Pan state (for the whole canvas)
    @State private var canvasOffset: CGSize = .zero
    @State private var lastPanOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                galleryBackground
                    .ignoresSafeArea()
                
                canvasLayer(in: geo.size)
                
                // Center-on-content button
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            centerOnContent()
                        } label: {
                            Image(systemName: "scope")
                                .font(.system(size: 18, weight: .medium))
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }
                        .padding(.top, 12)
                        .padding(.trailing, 12)
                    }
                    Spacer()
                }
                .zIndex(10_000)
            }
            .onAppear {
                currentScale = 1.0
                finalScale = 1.0
                canvasOffset = .zero
                lastPanOffset = .zero
            }
        }
    }
    
    // MARK: - Canvas Layer
    
    @ViewBuilder
    private func canvasLayer(in size: CGSize) -> some View {
        ZStack {
            // Invisible canvas filling the screen; artifacts are centered + offset by x/y.
            Color.clear
            
            ForEach(store.filteredArtifacts) { artifact in
                DraggableArtifactCard(
                    artifact: artifact,
                    canvasScale: currentScale
                )
            }
        }
        // Think of this as the Freeform sheet: you can zoom and pan the whole thing.
        .scaleEffect(currentScale)
        .offset(canvasOffset)
        .contentShape(Rectangle())
        .gesture(
            panGesture.simultaneously(with: magnification)
        )
    }
    
    // MARK: - Gestures
    
    private var magnification: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                currentScale = min(max(finalScale * value, 0.5), 3.0)
            }
            .onEnded { _ in
                finalScale = currentScale
            }
    }
    
    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                canvasOffset = CGSize(
                    width: lastPanOffset.width + value.translation.width,
                    height: lastPanOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastPanOffset = canvasOffset
            }
    }
    
    /// Centers the viewport on the bounding box of current artifacts.
    private func centerOnContent() {
        let artifacts = store.filteredArtifacts
        guard !artifacts.isEmpty else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentScale = 1.0
                finalScale = 1.0
                canvasOffset = .zero
                lastPanOffset = .zero
            }
            return
        }
        
        let xs = artifacts.map { $0.x }
        let ys = artifacts.map { $0.y }
        
        guard let minX = xs.min(),
              let maxX = xs.max(),
              let minY = ys.min(),
              let maxY = ys.max() else { return }
        
        let centerX = (minX + maxX) / 2.0
        let centerY = (minY + maxY) / 2.0
        
        // Because artifact.x/y are offsets around the screen center, we just shift opposite.
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            let offsetX = -centerX * currentScale
            let offsetY = -centerY * currentScale
            canvasOffset = CGSize(width: offsetX, height: offsetY)
            lastPanOffset = canvasOffset
        }
    }
    
    // MARK: - Background
    
    @AppStorage("galleryBackgroundColorKey")
    private var galleryBackgroundColorKey: String = GalleryBackgroundColor.cream.rawValue
    
    @AppStorage("galleryBackgroundMode")
    private var galleryBackgroundModeRawValue: String = GalleryBackgroundMode.color.rawValue
    
    private var galleryBackgroundMode: GalleryBackgroundMode {
        GalleryBackgroundMode(rawValue: galleryBackgroundModeRawValue) ?? .color
    }
    
    private var galleryBackground: some View {
        Group {
            if galleryBackgroundMode == .wallpaper,
               let name = store.galleryWallpaperName,
               !name.isEmpty {
                Image(name)
                    .resizable()
                    .scaledToFill()
            } else {
                (GalleryBackgroundColor(rawValue: galleryBackgroundColorKey) ?? .cream).color
            }
        }
    }
    
    
    // MARK: - Draggable Card (long-press + drag + layering)
    
    struct DraggableArtifactCard: View {
        @EnvironmentObject var store: MuseoStore

        let artifact: Artifact
        let canvasScale: CGFloat

        @GestureState private var dragOffset: CGSize = .zero
        @GestureState private var isPressing: Bool = false
        @State private var isDragging: Bool = false
        @State private var showingLayerActions: Bool = false

        var body: some View {
            ZStack(alignment: .topTrailing) {
                // Main card content
                artifactView
                    .contentShape(Rectangle()) // tap/drag hit area = artifact container
                    // Pickup feedback
                    .scaleEffect(isPressing || isDragging ? 1.08 : 1.0)
                    .shadow(
                        color: .black.opacity(isPressing || isDragging ? 0.20 : 0.08),
                        radius: isPressing || isDragging ? 16 : 10,
                        y: isPressing || isDragging ? 8 : 4
                    )
                    .animation(
                        .spring(response: 0.22, dampingFraction: 0.85),
                        value: isPressing || isDragging
                    )
                    // TAP TO EDIT (bound to the artifact container)
                    .onTapGesture {
                        store.editingArtifact = artifact
                    }
                    // LONG PRESS + DRAG with high priority so it beats the canvas pan
                    .highPriorityGesture(longPressDragGesture)

                // Small layers button in the corner
                Button {
                    showingLayerActions = true
                } label: {
                    Image(systemName: "rectangle.stack")
                        .font(.system(size: 12, weight: .medium))
                        .padding(6)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(4)
            }
            // Place around screen center using x/y
            .offset(
                x: artifact.x + dragOffset.width,
                y: artifact.y + dragOffset.height
            )
            // Layer ordering for overlap
            .zIndex(store.zIndex(for: artifact.id) + (isDragging ? 1000 : 0))
            // Layer actions sheet
            .confirmationDialog(
                "Layer actions",
                isPresented: $showingLayerActions,
                titleVisibility: .visible
            ) {
                Button("Bring to Front") {
                    store.bringToFront(artifact.id)
                }
                Button("Send to Back") {
                    store.sendToBack(artifact.id)
                }
                Button("Cancel", role: .cancel) { }
            }
        }

        // MARK: - Long press + drag (no haptics)

        private var longPressDragGesture: some Gesture {
            LongPressGesture(minimumDuration: 0.25)
                .sequenced(before: DragGesture())
                .updating($isPressing) { value, state, _ in
                    switch value {
                    case .first(true):
                        state = true
                    case .second(true, _):
                        state = true
                    default:
                        state = false
                    }
                }
                .updating($dragOffset) { value, state, _ in
                    if case .second(true, let drag?) = value {
                        let t = drag.translation
                        state = CGSize(
                            width: t.width / canvasScale,
                            height: t.height / canvasScale
                        )
                    }
                }
                .onChanged { value in
                    if case .second(true, _) = value {
                        if !isDragging {
                            isDragging = true
                            // Optional: bring to front when picked up
                            store.bringToFront(artifact.id)
                        }
                    }
                }
                .onEnded { value in
                    guard case .second(true, let drag?) = value else {
                        isDragging = false
                        return
                    }

                    let t = drag.translation
                    let scaledTranslation = CGSize(
                        width: t.width / canvasScale,
                        height: t.height / canvasScale
                    )

                    let newX = artifact.x + scaledTranslation.width
                    let newY = artifact.y + scaledTranslation.height

                    store.updatePosition(for: artifact.id, x: newX, y: newY)
                    isDragging = false
                }
        }

        // MARK: - Artifact content

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




// MARK: - Artifact Views (unchanged)

struct NoteArtifactView: View {
    let artifact: Artifact
    let folder: Folder?

    var body: some View {
        let bodyText = (artifact.body ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        VStack(alignment: .leading, spacing: 6) {
            Text(artifact.title.isEmpty ? "Untitled" : artifact.title)
                .font(MuseoFont.bodyTitle(16))
                .foregroundColor(MuseoColors.textPrimary)

            if !bodyText.isEmpty {
                Text(bodyText)
                    .font(MuseoFont.paragraph(14))
                    .foregroundColor(MuseoColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
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

struct ImageArtifactView: View {
    let artifact: Artifact
    let folder: Folder?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let data = artifact.imageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
            } else {
                HStack {
                    Image(systemName: "photo")
                    Text("Image")
                }
                .frame(width: 220, height: 220)
                .background(Color.white)
            }
            
            ArtifactMetadataView(artifact: artifact, folder: folder)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.85))
                )
        }
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }
}

struct VideoArtifactView: View {
    let artifact: Artifact
    let folder: Folder?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "video.fill")
                    .font(.title3)
                    .foregroundColor(MuseoColors.accent)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(artifact.title.isEmpty ? "Video" : artifact.title)
                        .font(MuseoFont.bodyTitle(14))
                        .foregroundColor(MuseoColors.textPrimary)

                    Text("Tap to edit")
                        .font(MuseoFont.paragraph(12))
                        .foregroundColor(MuseoColors.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            
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
        .contentShape(Rectangle())
    }
}

struct AudioArtifactView: View {
    let artifact: Artifact
    let folder: Folder?
    @StateObject private var playbackManager = AudioPlaybackManager()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(artifact.title.isEmpty ? "Audio note" : artifact.title)
                        .font(MuseoFont.bodyTitle(14))
                        .foregroundColor(MuseoColors.textPrimary)

                    if let description = artifact.audioDescription, !description.isEmpty {
                        Text(description)
                            .font(MuseoFont.paragraph(12))
                            .foregroundColor(MuseoColors.textSecondary)
                            .lineLimit(2)
                    } else {
                        Text("Audio • \(formattedDuration(artifact.audioDuration ?? 0))")
                            .font(MuseoFont.paragraph(12))
                            .foregroundColor(MuseoColors.textSecondary)
                    }
                }

                Spacer()

                if let audioURL = artifact.audioURL {
                    Button {
                        if playbackManager.isPlaying {
                            playbackManager.stop()
                        } else {
                            playbackManager.play(url: audioURL)
                        }
                    } label: {
                        Image(systemName: playbackManager.isPlaying ? "stop.circle.fill" : "play.circle.fill")
                            .font(.title3)
                            .foregroundColor(MuseoColors.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
            
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
        .contentShape(Rectangle())
    }
    
    private func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
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
