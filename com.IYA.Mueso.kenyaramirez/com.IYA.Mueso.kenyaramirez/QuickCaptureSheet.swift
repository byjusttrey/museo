//
//  QuickCaptureSheet.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created by Trey Jennings on 12/1/25.
//


// QuickCaptureSheet.swift

import SwiftUI
import PhotosUI
import AVFoundation
import AVKit
import UniformTypeIdentifiers

// MARK: - Preview Audio Player Delegate

class PreviewAudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    let onFinish: () -> Void
    
    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish()
    }
}

// MARK: - Image Transform State

struct ImageTransformState {
    var scale: CGFloat = 1.0
    var offset: CGSize = .zero
    var rotation: Angle = .zero
}

struct QuickCaptureSheet: View {
    @EnvironmentObject var store: MuseoStore
    @Environment(\.dismiss) private var dismiss
    
    let initialType: ArtifactType?
    
    @State private var selectedType: ArtifactType
    
    init(initialType: ArtifactType? = nil) {
        self.initialType = initialType
        _selectedType = State(initialValue: initialType ?? .note)
    }
    @State private var selectedFolder: Folder?
    @State private var titleText: String = ""
    @State private var bodyText: String = ""
    
    // New folder creation
    @State private var showNewFolderField = false
    @State private var newFolderName: String = ""
    
    // Image
    @State private var imageSelection: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var selectedFrameName: String? = "frame-1"
    @State private var imageTransform = ImageTransformState()
    private let frameNames = ["frame-1", "frame-2", "frame-3", "frame-4"]
    
    // Helper to get aspect ratio for frame
    private func aspectRatio(for frameName: String) -> CGFloat {
        switch frameName {
        case "frame-1": return 0.78  // 896 × 1152
        case "frame-2": return 1.18  // 1012 × 858
        case "frame-3": return 1.12  // 1056 × 942
        case "frame-4": return 1.0   // 1352 × 1352
        default: return 1.0
        }
    }
    
    // Video
    @State private var videoSelection: PhotosPickerItem?
    @State private var videoTitle: String = ""
    @State private var selectedVideoURL: URL?
    @State private var selectedVideoFrameName: String? = "frame-1"
    
    
    // Audio
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var recordedAudioURL: URL?
    @State private var audioTitle: String = ""
    @State private var audioDescription: String = ""
    
    // Recorded clip info for preview
    struct RecordedClipInfo {
        let duration: TimeInterval
        let url: URL
    }
    @State private var lastRecordedClip: RecordedClipInfo?
    @State private var previewAudioPlayer: AVAudioPlayer?
    @State private var isPreviewPlaying = false
    
    
    
    var body: some View {
        ZStack {
            // Background
            MuseoColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom header
                HStack {
                    Button {
                        // Clean up preview player if playing
                        previewAudioPlayer?.stop()
                        previewAudioPlayer = nil
                        isPreviewPlaying = false
                        dismiss()
                    } label: {
                        Text("Close")
                            .font(MuseoFont.bodyTitle(16))
                            .foregroundColor(MuseoColors.textPrimary)
                    }
                    
                    Spacer()
                    
                    Text("Quick Capture")
                        .font(MuseoFont.header(24))
                        .foregroundColor(MuseoColors.textPrimary)
                    
                    Spacer()
                    
                    // Invisible spacer to balance the Close button
                    Text("Close")
                        .font(MuseoFont.bodyTitle(16))
                        .foregroundColor(.clear)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 12)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Type tabs
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(ArtifactType.allCases) { type in
                                    Button {
                                        selectedType = type
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: type.systemImageName)
                                            Text(type.displayName)
                                        }
                                        .font(MuseoFont.bodyTitle(14))
                                        .foregroundColor(selectedType == type ? MuseoColors.accent : MuseoColors.textPrimary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(selectedType == type
                                                      ? MuseoColors.accent.opacity(0.2)
                                                      : Color.white)
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        .padding(.top, 8)
                
                        // Folder picker section
                        VStack(alignment: .leading, spacing: 8) {
                            // Folder label with required indicator
                            Text("Folder *")
                                .font(MuseoFont.bodyTitle(16))
                                .foregroundColor(MuseoColors.textPrimary)
                                .padding(.horizontal, 24)
                            
                            // Folder picker menu
                            Menu {
                                ForEach(store.folders) { folder in
                                    Button(folder.name) {
                                        selectedFolder = folder
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedFolder?.name ?? "Choose folder")
                                        .font(MuseoFont.paragraph(16))
                                        .foregroundColor(selectedFolder == nil ? MuseoColors.textSecondary : MuseoColors.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(MuseoColors.textSecondary)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                )
                            }
                            .padding(.horizontal, 24)
                    
                            // Create new folder button
                            Button {
                                withAnimation {
                                    showNewFolderField.toggle()
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle")
                                        .font(.system(size: 14))
                                    Text("Create new folder")
                                        .font(MuseoFont.paragraph(14))
                                }
                                .foregroundColor(MuseoColors.accent)
                            }
                            .padding(.horizontal, 24)
                            
                            // New folder input field (shown when creating)
                            if showNewFolderField {
                                VStack(alignment: .leading, spacing: 8) {
                                    TextField("New folder name", text: $newFolderName)
                                        .font(MuseoFont.paragraph(16))
                                        .foregroundColor(MuseoColors.textPrimary)
                                        .padding(12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.white)
                                                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                                        )
                                    
                                    HStack(spacing: 12) {
                                        Button {
                                            withAnimation {
                                                showNewFolderField = false
                                                newFolderName = ""
                                            }
                                        } label: {
                                            Text("Cancel")
                                                .font(MuseoFont.bodyTitle(14))
                                                .foregroundColor(MuseoColors.textPrimary)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 10)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color.white)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 12)
                                                                .stroke(MuseoColors.borderMuted, lineWidth: 1)
                                                        )
                                                )
                                        }
                                        
                                        Button {
                                            createQuickCaptureFolder()
                                        } label: {
                                            Text("Add folder")
                                                .font(MuseoFont.bodyTitle(14))
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 10)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(MuseoColors.accent)
                                                )
                                        }
                                        .disabled(newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 4)
                            }
                        }
                
                        // Content for the selected type
                        Group {
                            switch selectedType {
                            case .note:
                                noteInputs
                            case .image:
                                imageInputs
                            case .video:
                                videoInputs
                            case .audio:
                                audioInputs
                            }
                        }
                        
                        // Capture Idea button - disabled until folder is selected
                        Button {
                            save()
                        } label: {
                            Text("Capture Idea")
                                .font(MuseoFont.bodyTitle(18))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    selectedFolder != nil
                                        ? MuseoColors.accent
                                        : MuseoColors.accent.opacity(0.4)
                                )
                                .cornerRadius(8)
                        }
                        .disabled(selectedFolder == nil)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
            .onDisappear {
                // Clean up preview player when sheet disappears
                previewAudioPlayer?.stop()
                previewAudioPlayer = nil
                isPreviewPlaying = false
            }
        }
    }
    
    // MARK: - Subviews
    
    private var noteInputs: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Title", text: $titleText)
                .font(MuseoFont.paragraph(16))
                .foregroundColor(MuseoColors.textPrimary)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                )
            
            TextField("Write your thoughts...", text: $bodyText, axis: .vertical)
                .font(MuseoFont.paragraph(16))
                .foregroundColor(MuseoColors.textPrimary)
                .lineLimit(4, reservesSpace: true)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                )
        }
        .padding(.horizontal, 16)
    }
    
    private var imageInputs: some View {
        VStack(alignment: .leading, spacing: 12) {
            PhotosPicker(selection: $imageSelection, matching: .images) {
                HStack {
                    Image(systemName: "photo")
                        .foregroundColor(MuseoColors.textSecondary)
                    Text(selectedImage == nil ? "Select photo" : "Change photo")
                        .font(MuseoFont.paragraph(16))
                        .foregroundColor(MuseoColors.textPrimary)
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                )
            }
            .padding(.horizontal, 16)
            .onChange(of: imageSelection) { newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        await MainActor.run {
                            self.selectedImage = uiImage
                            self.selectedFrameName = frameNames.first
                            // Reset transform when new image is selected
                            self.imageTransform = ImageTransformState()
                        }
                    }
                }
            }
            
            if let selectedImage, let frameName = selectedFrameName {
                // Preview with frame chooser
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preview")
                        .font(MuseoFont.paragraph(12))
                        .foregroundColor(MuseoColors.textSecondary)
                        .padding(.horizontal, 16)
                    
                    // Interactive framed image editor
                    FramedImageEditorView(
                        frameImageName: frameName,
                        frameAspectRatio: aspectRatio(for: frameName),
                        backgroundColor: MuseoColors.background,
                        uiImage: $selectedImage,
                        transform: $imageTransform
                    )
                    .padding(.vertical, 16)
                    .frame(height: 300)
                    
                    // Frame selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(frameNames, id: \.self) { frame in
                                Button {
                                    selectedFrameName = frame
                                    // Reset transform when frame changes
                                    imageTransform = ImageTransformState()
                                } label: {
                                    Image(frame)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 60, height: 60)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(
                                                    selectedFrameName == frame ?
                                                    MuseoColors.accent : .clear,
                                                    lineWidth: 2
                                                )
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
        }
    }
    
    private var videoInputs: some View {
        VStack(alignment: .leading, spacing: 16) {

            // TITLE FIELD
            VStack(alignment: .leading, spacing: 6) {
                Text("Title")
                    .font(MuseoFont.bodyTitle(14))
                    .foregroundColor(MuseoColors.textPrimary)

                TextField("Video title", text: $videoTitle)
                    .font(MuseoFont.paragraph(16))
                    .foregroundColor(MuseoColors.textPrimary)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                    )
            }
            .padding(.horizontal, 16)

            // PICKER ROW
            PhotosPicker(selection: $videoSelection, matching: .videos) {
                HStack {
                    Image(systemName: "video")
                        .foregroundColor(MuseoColors.textSecondary)
                    Text(selectedVideoURL == nil ? "Select video" : "Change video")
                        .font(MuseoFont.paragraph(16))
                        .foregroundColor(MuseoColors.textPrimary)
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                )
            }
            .padding(.horizontal, 16)
            .onChange(of: videoSelection) { newItem in
                guard let newItem else { return }

                Task {
                    do {
                        print("📹 supported types:", newItem.supportedContentTypes)

                        guard let data = try await newItem.loadTransferable(type: Data.self) else {
                            print("❌ Failed to load video DATA from PhotosPickerItem")
                            return
                        }

                        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                        let destURL = docs.appendingPathComponent(UUID().uuidString + ".mov")

                        try data.write(to: destURL)

                        await MainActor.run {
                            configureVideoAudioSession()        // if you added this
                            self.selectedVideoURL = destURL
                            // ❌ no more selectedVideoFrameName here
                        }
                    } catch {
                        print("❌ Error loading video from PhotosPickerItem:", error)
                    }
                }
            }

            // INLINE VIDEO PREVIEW
            if let url = selectedVideoURL {
                VideoPlayer(player: AVPlayer(url: url))
                    .frame(height: 220)
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
            }
        }
    }


    
    private var audioInputs: some View {
        VStack(spacing: 20) {
            
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(MuseoFont.bodyTitle(14))
                    .foregroundColor(MuseoColors.textPrimary)
                
                TextField("Audio title", text: $audioTitle)
                    .font(MuseoFont.paragraph(16))
                    .foregroundColor(MuseoColors.textPrimary)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                    )
            }
            .padding(.horizontal, 16)
            
            // Audio description (optional)
            VStack(alignment: .leading, spacing: 4) {
                Text("Audio description (optional)")
                    .font(MuseoFont.bodyTitle(14))
                    .foregroundColor(MuseoColors.textPrimary)
                
                TextEditor(text: $audioDescription)
                    .frame(minHeight: 60)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(MuseoColors.borderMuted, lineWidth: 1)
                            )
                    )
                    .font(MuseoFont.paragraph(14))
                    .foregroundColor(MuseoColors.textPrimary)
            }
            .padding(.horizontal, 16)
            
            // Record / stop controls
            VStack(spacing: 16) {
                // Recording status and timer
                if audioRecorder.isRecording {
                    VStack(spacing: 12) {
                        // Recording indicator
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text("Recording…")
                                .font(MuseoFont.bodyTitle(14))
                                .foregroundColor(MuseoColors.textPrimary)
                        }
                        
                        // Timer
                        Text(audioRecorder.formattedDuration)
                            .font(MuseoFont.bodyTitle(24))
                            .foregroundColor(MuseoColors.textPrimary)
                            .monospacedDigit()
                        
                        // Waveform visualization
                        RecordingLevelView(level: audioRecorder.averagePower)
                            .padding(.horizontal, 16)
                    }
                } else {
                    Text("Tap to record")
                        .font(MuseoFont.paragraph(12))
                        .foregroundColor(MuseoColors.textSecondary)
                }
                
                // Record/Stop button
                Button {
                    if audioRecorder.isRecording {
                        // Capture duration before stopping
                        let duration = audioRecorder.finalDuration
                        // Stop and get the URL
                        if let url = audioRecorder.stopRecording() {
                            recordedAudioURL = url
                            lastRecordedClip = RecordedClipInfo(duration: duration, url: url)
                        }
                    } else {
                        // Start new recording - clear previous clip and description
                        recordedAudioURL = nil
                        lastRecordedClip = nil
                        audioDescription = ""
                        previewAudioPlayer?.stop()
                        isPreviewPlaying = false
                        audioRecorder.startRecording()
                    }
                } label: {
                    Image(systemName: audioRecorder.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(audioRecorder.isRecording ? .red : MuseoColors.accent)
                }
                
                // Recorded clip summary
                if let clip = lastRecordedClip, !audioRecorder.isRecording {
                    HStack(spacing: 12) {
                        Image(systemName: "waveform.circle.fill")
                            .font(.title3)
                            .foregroundColor(MuseoColors.accent)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Recorded audio")
                                .font(MuseoFont.bodyTitle(14))
                                .foregroundColor(MuseoColors.textPrimary)
                            
                            Text(formattedDuration(clip.duration))
                                .font(MuseoFont.paragraph(12))
                                .foregroundColor(MuseoColors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            togglePreviewPlayback(url: clip.url)
                        } label: {
                            Image(systemName: isPreviewPlaying ? "stop.fill" : "play.fill")
                                .font(.body)
                                .foregroundColor(MuseoColors.accent)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(MuseoColors.borderMuted, lineWidth: 1)
                            )
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Audio Preview Helper
    
    private func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func togglePreviewPlayback(url: URL) {
        if let player = previewAudioPlayer, player.isPlaying {
            player.stop()
            isPreviewPlaying = false
            previewAudioPlayer = nil
            return
        }
        
        do {
            // Configure audio session for speaker playback
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
            try session.overrideOutputAudioPort(.speaker)
            
            previewAudioPlayer = try AVAudioPlayer(contentsOf: url)
            previewAudioPlayer?.play()
            isPreviewPlaying = true
            
            // Stop when playback finishes
            previewAudioPlayer?.delegate = PreviewAudioPlayerDelegate {
                isPreviewPlaying = false
                previewAudioPlayer = nil
            }
        } catch {
            print("Preview playback error: \(error)")
        }
    }
    
    
    // MARK: - Folder Creation
    
    private func createQuickCaptureFolder() {
        let trimmed = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Create folder using the store's method (use default blue color, no priority)
        store.addFolder(named: trimmed, color: GalleryBackgroundColor.blue.color, priority: nil)
        
        // Find the newly created folder and select it
        if let newFolder = store.folders.first(where: { $0.name == trimmed }) {
            selectedFolder = newFolder
        }
        
        // Reset the form
        newFolderName = ""
        withAnimation {
            showNewFolderField = false
        }
    }
    
    // MARK: - Save
    
    private func save() {
        guard let folder = selectedFolder else { return }
        
        switch selectedType {
        case .note:
            let trimmed = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            store.addNoteArtifact(title: trimmed, body: bodyText, in: folder)
            
        case .image:
            guard let baseImage = selectedImage,
                  let frameName = selectedFrameName else { return }
            
            // Render composited framed image using the same transform state
            let compositedImage = renderFramedImage(
                baseImage: baseImage,
                frameName: frameName,
                frameAspectRatio: aspectRatio(for: frameName),
                transform: imageTransform,
                backgroundColor: UIColor(red: 253/255, green: 242/255, blue: 213/255, alpha: 1.0)
            )
            
            guard let finalImage = compositedImage,
                  let data = finalImage.jpegData(compressionQuality: 0.8) else { return }
            
            store.addImageArtifact(imageData: data,
                                   in: folder,
                                   frameName: frameName)
            
        case .video:
            guard let url = selectedVideoURL else { return }
            store.addVideoArtifact(
                videoURL: url,
                in: folder,
                title: videoTitle
            )

            
        case .audio:
            // Use the URL from lastRecordedClip if available, otherwise fall back to recordedAudioURL
            let audioURL: URL?
            let audioDuration: TimeInterval?
            
            if let clip = lastRecordedClip {
                audioURL = clip.url
                audioDuration = clip.duration
            } else if audioRecorder.isRecording {
                // If still recording, stop it first
                let duration = audioRecorder.finalDuration
                if let url = audioRecorder.stopRecording() {
                    audioURL = url
                    audioDuration = duration
                    lastRecordedClip = RecordedClipInfo(duration: duration, url: url)
                } else {
                    audioURL = recordedAudioURL
                    audioDuration = nil
                }
            } else {
                audioURL = recordedAudioURL
                audioDuration = nil
            }
            
            guard let finalAudioURL = audioURL else { return }
            
            let trimmedTitle = audioTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            let finalTitle = trimmedTitle.isEmpty ? "Audio note" : trimmedTitle
            let trimmedDescription = audioDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            let finalDescription = trimmedDescription.isEmpty ? nil : trimmedDescription
            
            store.addAudioArtifact(audioURL: finalAudioURL,
                                   in: folder,
                                   title: finalTitle,
                                   audioDescription: finalDescription,
                                   audioDuration: audioDuration)
            
        }
        dismiss()
    }
    
    private func configureVideoAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .moviePlayback, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            print("⚠️ Video audio session error:", error)
        }
    }

    
    // MARK: - Image Compositing Helper
    
    private func renderFramedImage(
        baseImage: UIImage,
        frameName: String,
        frameAspectRatio: CGFloat,
        transform: ImageTransformState,
        backgroundColor: UIColor
    ) -> UIImage? {
        // Get frame image
        guard let frameImage = UIImage(named: frameName) else { return nil }
        
        // Determine output size based on frame aspect ratio
        // Use 1200 as base size for high quality
        let baseSize: CGFloat = 1200
        let outputWidth: CGFloat
        let outputHeight: CGFloat
        
        if frameAspectRatio <= 1.0 {
            // Portrait or square
            outputWidth = baseSize
            outputHeight = baseSize / frameAspectRatio
        } else {
            // Landscape
            outputWidth = baseSize * frameAspectRatio
            outputHeight = baseSize
        }
        
        let size = CGSize(width: outputWidth, height: outputHeight)
        
        return UIGraphicsImageRenderer(size: size).image { context in
            let cgContext = context.cgContext
            
            // Fill background
            backgroundColor.setFill()
            cgContext.fill(CGRect(origin: .zero, size: size))
            
            // Center point for transformations
            let centerX = size.width / 2
            let centerY = size.height / 2
            
            // Calculate scaled image size
            let imageSize = baseImage.size
            let scaledSize = CGSize(
                width: imageSize.width * transform.scale,
                height: imageSize.height * transform.scale
            )
            
            // Apply transforms in correct order: translate -> rotate -> scale -> translate offset
            cgContext.saveGState()
            
            // 1. Translate to center
            cgContext.translateBy(x: centerX, y: centerY)
            
            // 2. Apply rotation
            cgContext.rotate(by: CGFloat(transform.rotation.radians))
            
            // 3. Apply offset
            cgContext.translateBy(x: transform.offset.width, y: transform.offset.height)
            
            // 4. Draw image centered (scale is already applied to size calculation)
            let imageRect = CGRect(
                x: -scaledSize.width / 2,
                y: -scaledSize.height / 2,
                width: scaledSize.width,
                height: scaledSize.height
            )
            
            baseImage.draw(in: imageRect)
            
            cgContext.restoreGState()
            
            // Draw frame on top (full canvas)
            frameImage.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
