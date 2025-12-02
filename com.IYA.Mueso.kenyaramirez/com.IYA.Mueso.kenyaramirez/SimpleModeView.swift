//
//  SimpleModeView.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created by Trey Jennings on 12/1/25.
//


// SimpleModeView.swift

import SwiftUI

struct SimpleModeView: View {
    @EnvironmentObject var store: MuseoStore
    
    @State private var isPresentingNewFolderSheet = false


    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Search
            TextField("Search notes and folders...", text: $store.searchText)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)

            // Filters button (shows a stub filter view inline)
            FiltersStubView()
                .padding(.horizontal, 16)

            // Folder list
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(store.simpleViewFolders) { folder in
                        FolderRowView(folder: folder)
                            .padding(.horizontal, 16)
                    }

                    Button {
                        isPresentingNewFolderSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add Folder")
                        }
                        .font(.subheadline.weight(.semibold))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.secondary.opacity(0.3))
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 80)
                    }
                    .sheet(isPresented: $isPresentingNewFolderSheet) {
                        NewFolderSheet()
                    }
                }
            }
        }
    }
}


struct NewFolderSheet: View {
    @EnvironmentObject var store: MuseoStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Folder Name") {
                    TextField("Name", text: $name)
                }
            }
            .navigationTitle("New Folder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        store.addFolder(named: trimmed)
                        dismiss()
                    }
                }
            }
        }
    }
}


struct FolderDetailSheet: View {
    @EnvironmentObject var store: MuseoStore
    @Environment(\.dismiss) private var dismiss

    let folder: Folder
    @State private var name: String

    init(folder: Folder) {
        self.folder = folder
        _name = State(initialValue: folder.name)
    }

    private var itemsInFolder: [Artifact] {
        store.artifacts(in: folder)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {

                // MARK: Folder name
                VStack(alignment: .leading, spacing: 6) {
                    Text("Folder name")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextField("Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // MARK: Items list
                ScrollView {
                    VStack(spacing: 16) {
                        if itemsInFolder.isEmpty {
                            Text("No items in this folder yet.")
                                .foregroundStyle(.secondary)
                                .padding(.top, 24)
                        } else {
                            ForEach(itemsInFolder) { artifact in
                                Button {
                                    // open edit sheet used elsewhere
                                    store.editingArtifact = artifact
                                    dismiss()
                                } label: {
                                    Group {
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
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

                Spacer()

                // MARK: Delete folder
                Button(role: .destructive) {
                    store.deleteFolder(folder)
                    dismiss()
                } label: {
                    Text("Delete Folder")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.05))
                        )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .navigationTitle("Folder Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            store.renameFolder(folder, to: trimmed)
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}


// MARK: - Note card

struct NoteArtifactView: View {
    let artifact: Artifact

    var body: some View {
        // Normalize the optional body once
        let bodyText = (artifact.body ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return VStack(alignment: .leading, spacing: 6) {
            Text(artifact.title.isEmpty ? "Untitled" : artifact.title)
                .font(.headline)
                .foregroundStyle(.primary)

            // Only show body if it actually has content
            if !bodyText.isEmpty {
                Text(bodyText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
                    .frame(height: 160)
                    .clipped()
            } else {
                HStack {
                    Image(systemName: "photo")
                    Text("Image")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 80)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        )
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
                    .font(.headline)
                Text("Tap to edit")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
        HStack(spacing: 12) {
            Image(systemName: "waveform.circle.fill")
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(artifact.title.isEmpty ? "Audio note" : artifact.title)
                    .font(.headline)
                Text("Tap to edit")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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


struct FolderRowView: View {
    @EnvironmentObject var store: MuseoStore
    let folder: Folder

    var body: some View {
        let itemCount = store.artifacts(in: folder).count

        Button {
            store.activeFolderDetail = folder
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "folder")
                    .foregroundStyle(folder.color.swiftUIColor)
                    .font(.system(size: 24))

                VStack(alignment: .leading, spacing: 4) {
                    Text(folder.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("\(store.artifacts(in: folder).count) item\(store.artifacts(in: folder).count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }

    }
}

struct FiltersStubView: View {
    @EnvironmentObject var store: MuseoStore
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                    Text("Filters")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white)
                )
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Filter by Type:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        FilterChip(title: "All",
                                   isSelected: store.selectedTypeFilter == nil) {
                            store.selectedTypeFilter = nil
                        }
                        ForEach(ArtifactType.allCases) { type in
                            FilterChip(title: type.displayName,
                                       isSelected: store.selectedTypeFilter == type) {
                                store.selectedTypeFilter = type
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.purple.opacity(0.2) : Color.white)
                )
        }
    }
}
