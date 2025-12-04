// ArtifactEditSheet.swift

import SwiftUI
import UIKit
import AVKit
import AVFoundation


struct ArtifactEditSheet: View {
    @EnvironmentObject var store: MuseoStore
    @Environment(\.dismiss) private var dismiss

    @State var artifact: Artifact
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isAudioPlaying = false


    private var createdAtString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: artifact.createdAt)
    }

    private let frameNames = ["frame-1", "frame-2", "frame-3", "frame-4"]

    var body: some View {
        NavigationStack {
            ZStack {
                MuseoColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Created chip
                        HStack {
                            Text("Created \(createdAtString)")
                                .font(MuseoFont.paragraph(12))
                                .foregroundColor(MuseoColors.textPrimary.opacity(0.7))
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                        )
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        
                        // Content section
                        contentSection
                        
                        // Delete button
                        Button(role: .destructive) {
                            store.delete(artifact: artifact)
                            store.editingArtifact = nil
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete Artifact")
                                    .font(MuseoFont.bodyTitle(16))
                                    .foregroundColor(MuseoColors.accent)
                                Spacer()
                            }
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Edit Artifact")
                        .font(MuseoFont.header(32))
                        .foregroundColor(MuseoColors.textPrimary)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        store.editingArtifact = nil
                        dismiss()
                    }
                    .font(MuseoFont.bodyTitle(16))
                    .foregroundColor(MuseoColors.textPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.update(artifact: artifact)
                        store.editingArtifact = nil
                        dismiss()
                    }
                    .font(MuseoFont.bodyTitle(16))
                    .foregroundColor(MuseoColors.accent)
                }
            }
        }
        .onDisappear {
            audioPlayer?.stop()
            isAudioPlaying = false
        }
    }

    @ViewBuilder
    private var contentSection: some View {
        switch artifact.type {
        case .note:
            noteEditor
        case .image:
            imageEditor
        case .video:
            videoEditor
        case .audio:
            audioEditor
        }
    }


    // MARK: - Note editor

    private var noteEditor: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title field
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(MuseoFont.bodyTitle(16))
                    .foregroundColor(MuseoColors.textPrimary)
                
                TextField("Title", text: Binding(
                    get: { artifact.title },
                    set: { newValue in
                        artifact.title = newValue
                    }
                ))
                    .font(MuseoFont.paragraph(16))
                    .foregroundColor(MuseoColors.textPrimary)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                    )
            }
            
            // Content field
            VStack(alignment: .leading, spacing: 8) {
                Text("Content")
                    .font(MuseoFont.bodyTitle(16))
                    .foregroundColor(MuseoColors.textPrimary)
                
                TextField("Write your thoughts...", text: Binding(
                    get: { artifact.body ?? "" },
                    set: { newValue in
                        artifact.body = newValue.isEmpty ? nil : newValue
                    }
                ), axis: .vertical)
                    .font(MuseoFont.paragraph(16))
                    .foregroundColor(MuseoColors.textPrimary)
                    .lineLimit(6, reservesSpace: true)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                    )
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Image editor

    private var imageEditor: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Image & Frame")
                .font(MuseoFont.bodyTitle(16))
                .foregroundColor(MuseoColors.textPrimary)
            
            if let data = artifact.imageData,
               let uiImage = UIImage(data: data) {
                ZStack {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 150)
                        .clipped()
                        .cornerRadius(12)

                    if let frameName = artifact.frameName {
                        Image(frameName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 170, height: 170)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Text("No image data.")
                    .font(MuseoFont.paragraph(14))
                    .foregroundColor(MuseoColors.textSecondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(frameNames, id: \.self) { frame in
                        Button {
                            artifact.frameName = frame
                        } label: {
                            Image(frame)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(artifact.frameName == frame ? MuseoColors.accent : .clear,
                                                lineWidth: 2)
                                )
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, 24)
    }
    private var videoEditor: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Video")
                .font(MuseoFont.bodyTitle(16))
                .foregroundColor(MuseoColors.textPrimary)
            
            if let url = artifact.videoURL {
                VideoPlayer(player: AVPlayer(url: url))
                    .frame(height: 220)
                    .cornerRadius(12)
            } else {
                Text("No video file.")
                    .font(MuseoFont.paragraph(14))
                    .foregroundColor(MuseoColors.textSecondary)
            }

            // Optional: frame picker, re-using same concept as images
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(frameNames, id: \.self) { frame in
                        Button {
                            artifact.frameName = frame
                        } label: {
                            Image(frame)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            artifact.frameName == frame ? MuseoColors.accent : .clear,
                                            lineWidth: 2
                                        )
                                )
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, 24)
    }
    private var audioEditor: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Audio")
                .font(MuseoFont.bodyTitle(16))
                .foregroundColor(MuseoColors.textPrimary)

            // Title field
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(MuseoFont.bodyTitle(16))
                    .foregroundColor(MuseoColors.textPrimary)

                TextField("Audio title", text: Binding(
                    get: { artifact.title },
                    set: { newValue in
                        artifact.title = newValue
                    }
                ))
                    .font(MuseoFont.paragraph(16))
                    .foregroundColor(MuseoColors.textPrimary)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                    )
            }
            
            // Audio description field
            VStack(alignment: .leading, spacing: 4) {
                Text("Audio description (optional)")
                    .font(MuseoFont.bodyTitle(14))
                    .foregroundColor(MuseoColors.textPrimary)
                
                TextEditor(text: Binding(
                    get: { artifact.audioDescription ?? "" },
                    set: { newValue in
                        artifact.audioDescription = newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : newValue
                    }
                ))
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

            // Playback button
            if artifact.audioURL == nil {
                Text("No audio file.")
                    .font(MuseoFont.paragraph(14))
                    .foregroundColor(MuseoColors.textSecondary)
            } else {
                Button {
                    toggleAudioPlayback()
                } label: {
                    HStack {
                        Image(systemName: isAudioPlaying ? "stop.fill" : "play.fill")
                            .foregroundColor(MuseoColors.accent)
                        Text(isAudioPlaying ? "Stop playback" : "Play audio note")
                            .font(MuseoFont.bodyTitle(16))
                            .foregroundColor(MuseoColors.textPrimary)
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
    }

    private func toggleAudioPlayback() {
        guard let url = artifact.audioURL else { return }

        if let player = audioPlayer, player.isPlaying {
            player.stop()
            isAudioPlaying = false
            return
        }

        do {
            // Configure audio session for speaker playback
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
            
            // Override to ensure speaker output
            try session.overrideOutputAudioPort(.speaker)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            isAudioPlaying = true
        } catch {
            print("Audio playback error: \(error)")
        }
    }

}
