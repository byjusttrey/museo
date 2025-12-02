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


struct QuickCaptureSheet: View {
    @EnvironmentObject var store: MuseoStore
    
    @State private var selectedType: ArtifactType = .note
    @State private var selectedFolder: Folder?
    @State private var titleText: String = ""
    @State private var bodyText: String = ""
    
    // Image
    @State private var imageSelection: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var selectedFrameName: String? = "frame-1"
    private let frameNames = ["frame-1", "frame-2", "frame-3", "frame-4"]
    
    // Video
    @State private var videoSelection: PhotosPickerItem?
    @State private var selectedVideoURL: URL?
    @State private var selectedVideoFrameName: String? = "frame-1"
    
    
    // Audio
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var recordedAudioURL: URL?
    @State private var audioTitle: String = ""
    
    
    
    var body: some View {
        NavigationStack {
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
                    .padding(.horizontal, 16)
                }
                
                // Folder picker
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
                    .padding(.horizontal, 16)
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
                
                
                Spacer()
                
                PrimaryButton(title: "Capture Idea") {
                    save()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .padding(.top, 16)
            .background(MuseoColors.background.ignoresSafeArea())
            .navigationTitle("Quick Capture")
            .font(MuseoFont.header(20))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        store.isShowingQuickCapture = false
                    }
                }
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
                        }
                    }
                }
            }
            
            if let selectedImage {
                // Preview with frame chooser
                    VStack(alignment: .leading, spacing: 8) {
                    Text("Preview")
                        .font(MuseoFont.paragraph(12))
                        .foregroundColor(MuseoColors.textSecondary)
                        .padding(.horizontal, 16)
                    
                    // ⬇️ This is the ZStack preview block
                    ZStack {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 150, height: 150)
                            .clipped()
                        
                        if let frameName = selectedFrameName {
                            Image(frameName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 170, height: 170)
                        }
                    }
                    .frame(width: 170, height: 170)  // keeps everything contained
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(frameNames, id: \.self) { frame in
                                Button {
                                    selectedFrameName = frame
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
        VStack(alignment: .leading, spacing: 12) {
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
                    if let url = try? await newItem.loadTransferable(type: URL.self) {
                        await MainActor.run {
                            self.selectedVideoURL = url
                            self.selectedVideoFrameName = frameNames.first
                        }
                    }
                }
            }
            
            if selectedVideoURL != nil {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Frame")
                        .font(MuseoFont.paragraph(12))
                        .foregroundColor(MuseoColors.textSecondary)
                        .padding(.horizontal, 16)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(frameNames, id: \.self) { frame in
                                Button {
                                    selectedVideoFrameName = frame
                                } label: {
                                    Image(frame)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 60, height: 60)
                                        .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                selectedVideoFrameName == frame ?
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
    
    private var audioInputs: some View {
        VStack(spacing: 20) {
            
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(MuseoFont.paragraph(12))
                    .foregroundColor(MuseoColors.textSecondary)
                
                TextField("Audio title", text: $audioTitle)
                    .font(MuseoFont.paragraph(16))
                    .foregroundColor(MuseoColors.textPrimary)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.horizontal, 16)
            
            // Record / stop controls
            VStack(spacing: 12) {
                Text(audioRecorder.isRecording ? "Recording…" : "Tap to record")
                    .font(MuseoFont.paragraph(12))
                    .foregroundColor(MuseoColors.textSecondary)
                
                Button {
                    if audioRecorder.isRecording {
                        // Stop and keep the URL
                        recordedAudioURL = audioRecorder.stopRecording()
                    } else {
                        recordedAudioURL = nil
                        audioRecorder.startRecording()
                    }
                } label: {
                    Image(systemName: audioRecorder.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(audioRecorder.isRecording ? .red : MuseoColors.accent)
                }
            }
            .frame(maxWidth: .infinity)
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
            guard let img = selectedImage,
                  let data = img.jpegData(compressionQuality: 0.8) else { return }
            store.addImageArtifact(imageData: data,
                                   in: folder,
                                   frameName: selectedFrameName)
            
        case .video:
            guard let url = selectedVideoURL else { return }
            store.addVideoArtifact(videoURL: url,
                                   in: folder,
                                   frameName: selectedVideoFrameName)
            
        case .audio:
            if audioRecorder.isRecording {
                recordedAudioURL = audioRecorder.stopRecording()
            }
            guard let audioURL = recordedAudioURL else { return }
            
            let trimmedTitle = audioTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            let finalTitle = trimmedTitle.isEmpty ? "Audio note" : trimmedTitle
            
            store.addAudioArtifact(audioURL: audioURL,
                                   in: folder,
                                   title: finalTitle)
            
        }
        store.isShowingQuickCapture = false

    }

}
