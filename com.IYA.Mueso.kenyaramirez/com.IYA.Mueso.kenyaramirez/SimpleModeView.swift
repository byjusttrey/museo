//
//  SimpleModeView.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created by Trey Jennings on 12/1/25.
//

import SwiftUI
import UIKit

// MARK: - Folder Sort Option

enum FolderSortOption: String, CaseIterable, Identifiable {
    case az = "A–Z"
    case za = "Z–A"
    case type = "Type"
    case priority = "Priority"
    
    var id: String { rawValue }
    
    var displayName: String {
        rawValue
    }
}

// MARK: - Brand Color Palette

enum FolderBrandColor: String, CaseIterable, Identifiable {
    case cream
    case accent
    case accentSoft
    case textSecondary
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .cream: "Cream"
        case .accent: "Terracotta"
        case .accentSoft: "Teal"
        case .textSecondary: "Dusty Rose"
        }
    }
    
    var color: Color {
        switch self {
        case .cream:
            return MuseoColors.background
        case .accent:
            return MuseoColors.accent
        case .accentSoft:
            return MuseoColors.accentSoft
        case .textSecondary:
            return MuseoColors.textSecondary
        }
    }
}

// MARK: - Simple Mode View

struct SimpleModeView: View {
    @EnvironmentObject var store: MuseoStore
    
    @State private var isPresentingNewFolderSheet = false
    @State private var sortOption: FolderSortOption = .az
    
    private var filteredAndSortedFolders: [Folder] {
        var folders = store.folders
        
        // Apply search filter
        if !store.searchText.isEmpty {
            folders = folders.filter { folder in
                folder.name.localizedCaseInsensitiveContains(store.searchText)
            }
        }
        
        // Apply sorting
        switch sortOption {
        case .az:
            folders.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .za:
            folders.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .type:
            // Sort by first character/type - simple alphabetical grouping
            folders.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .priority:
            // Sort by priority: High (!!!) > Medium (!!) > Low (!)
            folders.sort { $0.priority.sortIndex > $1.priority.sortIndex }
        }
        
        return folders
    }

    var body: some View {
        ZStack {
            MuseoColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Folders")
                        .font(MuseoFont.header(28))
                        .foregroundColor(MuseoColors.textPrimary)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 20)
                }
                
                // Controls section
                VStack(spacing: 12) {
                    // Search field and Filter control
                    HStack(spacing: 12) {
                        // Search field
                        TextField("Search folders", text: $store.searchText)
                            .font(MuseoFont.paragraph(16))
                            .foregroundColor(MuseoColors.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(MuseoColors.borderMuted, lineWidth: 1)
                                    )
                            )
                        
                        // Filter menu
                        Menu {
                            ForEach(FolderSortOption.allCases) { option in
                                Button {
                                    sortOption = option
                                } label: {
                                    HStack {
                                        Text(option.displayName)
                                        if sortOption == option {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                    .font(.system(size: 16))
                                Text("Filter")
                                    .font(MuseoFont.paragraph(14))
                            }
                            .foregroundColor(MuseoColors.textPrimary)
                            .padding(.horizontal, 12)
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
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 16)
                
                // Folder list
                if filteredAndSortedFolders.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Text("No folders found")
                            .font(MuseoFont.bodyTitle(16))
                            .foregroundColor(MuseoColors.textSecondary)
                        if !store.searchText.isEmpty {
                            Text("Try a different search term")
                                .font(MuseoFont.paragraph(14))
                                .foregroundColor(MuseoColors.textSecondary)
                        }
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(filteredAndSortedFolders) { folder in
                                FolderRowView(folder: folder)
                                    .padding(.horizontal, 20)
                            }
                            
                            // Add folder button
                            Button {
                                isPresentingNewFolderSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("Add Folder")
                                }
                                .font(MuseoFont.bodyTitle(14))
                                .foregroundColor(MuseoColors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(MuseoColors.borderMuted, lineWidth: 1)
                                )
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 80)
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
        .sheet(isPresented: $isPresentingNewFolderSheet) {
            NewFolderSheet()
        }
    }
}

// MARK: - Folder Row View

struct FolderRowView: View {
    @EnvironmentObject var store: MuseoStore
    let folder: Folder
    @State private var showingColorPicker = false
    
    var body: some View {
        let itemCount = store.artifacts(in: folder).count

        Button {
            store.activeFolderDetail = folder
        } label: {
            HStack(spacing: 12) {
                // Folder icon with color - tappable for color change
                Button {
                    showingColorPicker.toggle()
                } label: {
                    Image(systemName: "folder.fill")
                        .foregroundColor(folder.color.swiftUIColor)
                        .font(.system(size: 24))
                }
                .buttonStyle(.plain)
                
                // Folder name, priority, and count
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(folder.name)
                            .font(MuseoFont.bodyTitle(16))
                            .foregroundColor(MuseoColors.textPrimary)
                        
                        Text(folder.priority.rawValue)
                            .font(MuseoFont.paragraph(12))
                            .foregroundColor(MuseoColors.textSecondary)
                    }
                    
                    Text("\(itemCount) item\(itemCount == 1 ? "" : "s")")
                        .font(MuseoFont.paragraph(14))
                        .foregroundColor(MuseoColors.textSecondary)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(MuseoFont.bodyTitle(14))
                    .foregroundColor(MuseoColors.textSecondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingColorPicker) {
            FolderColorPickerSheet(folder: folder)
        }
    }
}

// MARK: - Folder Color Picker Sheet

struct FolderColorPickerSheet: View {
    @EnvironmentObject var store: MuseoStore
    @Environment(\.dismiss) private var dismiss
    let folder: Folder
    
    var body: some View {
        NavigationStack {
            ZStack {
                MuseoColors.background.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Choose a color for \(folder.name)")
                        .font(MuseoFont.bodyTitle(16))
                        .foregroundColor(MuseoColors.textPrimary)
                        .padding(.top, 24)
                    
                    HStack(spacing: 16) {
                        ForEach(FolderBrandColor.allCases) { brandColor in
                            Button {
                                store.updateFolderColor(folder, to: brandColor.color)
                                dismiss()
                            } label: {
                                VStack(spacing: 8) {
                                    Circle()
                                        .fill(brandColor.color)
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Circle()
                                                .stroke(MuseoColors.borderMuted, lineWidth: 2)
                                        )
                                    
                                    Text(brandColor.displayName)
                                        .font(MuseoFont.paragraph(12))
                                        .foregroundColor(MuseoColors.textPrimary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Folder Color")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - New Folder Sheet

struct NewFolderSheet: View {
    @EnvironmentObject var store: MuseoStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var selectedPriority: FolderPriority = .low

    var body: some View {
        NavigationStack {
            ZStack {
                MuseoColors.background.ignoresSafeArea()
                
                Form {
                    Section("Folder Name") {
                        TextField("Name", text: $name)
                            .font(MuseoFont.paragraph(16))
                            .foregroundColor(MuseoColors.textPrimary)
                    }
                    
                    Section("Priority") {
                        Picker("Priority", selection: $selectedPriority) {
                            ForEach(FolderPriority.allCases) { priority in
                                HStack {
                                    Text(priority.rawValue)
                                    Text(priority.displayName)
                                }
                                .tag(priority)
                            }
                        }
                        .font(MuseoFont.paragraph(16))
                        .foregroundColor(MuseoColors.textPrimary)
                    }
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
                        store.addFolder(named: trimmed, priority: selectedPriority)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Folder Detail Sheet

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
            ZStack {
                MuseoColors.background.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 16) {
                    // MARK: Folder name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Folder name")
                            .font(MuseoFont.paragraph(12))
                            .foregroundColor(MuseoColors.textSecondary)

                        TextField("Name", text: $name)
                            .font(MuseoFont.paragraph(16))
                            .foregroundColor(MuseoColors.textPrimary)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    // MARK: Items list
                    ScrollView {
                        VStack(spacing: 16) {
                            if itemsInFolder.isEmpty {
                                Text("No items in this folder yet.")
                                    .font(MuseoFont.paragraph(14))
                                    .foregroundColor(MuseoColors.textSecondary)
                                    .padding(.top, 24)
                            } else {
                                ForEach(itemsInFolder) { artifact in
                                    Button {
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
                            .font(MuseoFont.bodyTitle(16))
                            .foregroundColor(.red)
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

// MARK: - Artifact Views

struct NoteArtifactView: View {
    let artifact: Artifact

    var body: some View {
        let bodyText = (artifact.body ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return VStack(alignment: .leading, spacing: 6) {
            Text(artifact.title.isEmpty ? "Untitled" : artifact.title)
                .font(MuseoFont.bodyTitle(16))
                .foregroundColor(MuseoColors.textPrimary)

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
                .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        )
    }
}

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

struct AudioArtifactView: View {
    let artifact: Artifact
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "waveform.circle.fill")
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(artifact.title.isEmpty ? "Audio note" : artifact.title)
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
