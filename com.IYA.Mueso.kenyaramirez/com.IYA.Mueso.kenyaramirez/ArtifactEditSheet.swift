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
                
                Form {
                    Section {
                        Text("Created \(createdAtString)")
                            .font(MuseoFont.paragraph(12))
                            .foregroundColor(MuseoColors.textSecondary)
                    }

                contentSection

                Section {
                    Button(role: .destructive) {
                        store.delete(artifact: artifact)
                        store.editingArtifact = nil
                        dismiss()
                    } label: {
                        Text("Delete Artifact")
                    }
                }
                }
            }
            .navigationTitle("Edit Artifact")
            .font(MuseoFont.header(20))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        store.editingArtifact = nil
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.update(artifact: artifact)
                        store.editingArtifact = nil
                        dismiss()
                    }
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
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Text("Title")
                    .font(MuseoFont.paragraph(12))
                    .foregroundColor(MuseoColors.textSecondary)
                TextField("Title", text: $artifact.title)
                    .font(MuseoFont.paragraph(16))
                    .foregroundColor(MuseoColors.textPrimary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Content")
                    .font(MuseoFont.paragraph(12))
                    .foregroundColor(MuseoColors.textSecondary)
                TextField("Write your thoughts...", text: Binding(
                    get: { artifact.body ?? "" },
                    set: { artifact.body = $0.isEmpty ? nil : $0 }
                ), axis: .vertical)
                    .font(MuseoFont.paragraph(16))
                    .foregroundColor(MuseoColors.textPrimary)
            }
        }
    }

    // MARK: - Image editor

    private var imageEditor: some View {
        Section("Image & Frame") {
            if let data = artifact.imageData,
               let uiImage = UIImage(data: data) {
                ZStack {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 150)
                        .clipped()

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
            }
        }
    }
    private var videoEditor: some View {
        Section("Video") {
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
            }
        }
    }
    private var audioEditor: some View {
        Section("Audio") {

            // Title field
            VStack(alignment: .leading, spacing: 6) {
                Text("Title")
                    .font(MuseoFont.paragraph(12))
                    .foregroundColor(MuseoColors.textSecondary)

                TextField("Audio title", text: $artifact.title)
                    .font(MuseoFont.paragraph(16))
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
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(MuseoColors.accent.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func toggleAudioPlayback() {
        guard let url = artifact.audioURL else { return }

        if let player = audioPlayer, player.isPlaying {
            player.stop()
            isAudioPlaying = false
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            isAudioPlaying = true
        } catch {
            print("Audio playback error: \(error)")
        }
    }

}
