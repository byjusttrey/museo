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
            // Sort by priority: High (!!!) > Medium (!!) > Low (!) > nil (no priority)
            folders.sort { folder1, folder2 in
                let index1 = folder1.priority?.sortIndex ?? 0
                let index2 = folder2.priority?.sortIndex ?? 0
                return index1 > index2
            }
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
                        
                        if let priority = folder.priority {
                            Text(priority.label)
                                .font(MuseoFont.paragraph(12))
                                .foregroundColor(MuseoColors.textSecondary)
                        }
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
    
    @State private var selectedColorIndex: Int = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                MuseoColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title
                        Text("Choose a color for \(folder.name)")
                            .font(MuseoFont.header(28))
                            .foregroundColor(MuseoColors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 16)
                        
                        // Color picker
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(MuseoPalette.folderColors.enumerated()), id: \.offset) { index, color in
                                    Button {
                                        selectedColorIndex = index
                                        store.updateFolderColor(folder, to: color)
                                    } label: {
                                        VStack(spacing: 8) {
                                            Circle()
                                                .fill(color)
                                                .frame(width: 50, height: 50)
                                                .overlay(
                                                    Circle()
                                                        .stroke(
                                                            selectedColorIndex == index ? MuseoColors.accent : MuseoColors.borderMuted,
                                                            lineWidth: selectedColorIndex == index ? 3 : 1
                                                        )
                                                )
                                            
                                            // Show color name if available
                                            if let colorKey = MuseoPalette.colorKey(for: color),
                                               let bgColor = GalleryBackgroundColor(rawValue: colorKey) {
                                                Text(bgColor.displayName)
                                                    .font(MuseoFont.paragraph(12))
                                                    .foregroundColor(MuseoColors.textPrimary)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(MuseoFont.bodyTitle(16))
                    .foregroundColor(MuseoColors.accent)
                }
            }
            .onAppear {
                // Find current folder color in palette
                let currentFolderColor = folder.color.swiftUIColor
                for (index, paletteColor) in MuseoPalette.folderColors.enumerated() {
                    if MuseoPalette.areColorsEqual(paletteColor, currentFolderColor) {
                        selectedColorIndex = index
                        break
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
    @State private var selectedPriority: FolderPriority? = nil
    @State private var selectedColorIndex: Int = 0

    var body: some View {
        NavigationStack {
            ZStack {
                MuseoColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title
                        Text("New folder")
                            .font(MuseoFont.header(28))
                            .foregroundColor(MuseoColors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 8)
                        
                        // Folder name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Folder name")
                                .font(MuseoFont.bodyTitle(14))
                                .foregroundColor(MuseoColors.textPrimary)
                            
                            TextField("Enter folder name", text: $name)
                                .font(MuseoFont.paragraph(16))
                                .foregroundColor(MuseoColors.textPrimary)
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
                        
                        // Priority
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Priority (optional)")
                                .font(MuseoFont.bodyTitle(14))
                                .foregroundColor(MuseoColors.textPrimary)
                            
                            HStack(spacing: 8) {
                                ForEach(FolderPriority.allCases) { priority in
                                    Button {
                                        if selectedPriority == priority {
                                            // Allow deselect
                                            selectedPriority = nil
                                        } else {
                                            selectedPriority = priority
                                        }
                                    } label: {
                                        Text(priority.label)
                                            .font(MuseoFont.paragraph(14))
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 10)
                                            .background(
                                                (selectedPriority == priority)
                                                ? MuseoColors.accent.opacity(0.15)
                                                : Color.white
                                            )
                                            .foregroundColor(
                                                selectedPriority == priority
                                                ? MuseoColors.accent
                                                : MuseoColors.textSecondary
                                            )
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(
                                                        selectedPriority == priority
                                                        ? MuseoColors.accent
                                                        : MuseoColors.borderMuted,
                                                        lineWidth: 1
                                                    )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        // Folder color
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Folder color")
                                .font(MuseoFont.bodyTitle(14))
                                .foregroundColor(MuseoColors.textPrimary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(Array(MuseoPalette.folderColors.enumerated()), id: \.offset) { index, color in
                                        Button {
                                            selectedColorIndex = index
                                        } label: {
                                            Circle()
                                                .fill(color)
                                                .frame(width: 40, height: 40)
                                                .overlay(
                                                    Circle()
                                                        .stroke(
                                                            selectedColorIndex == index ? MuseoColors.accent : MuseoColors.borderMuted,
                                                            lineWidth: selectedColorIndex == index ? 3 : 1
                                                        )
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        
                        // Create button
                        PrimaryButton(title: "Create folder") {
                            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            let selectedColor = MuseoPalette.folderColors[selectedColorIndex]
                            store.addFolder(named: trimmed, color: selectedColor, priority: selectedPriority)
                            dismiss()
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(MuseoFont.bodyTitle(16))
                    .foregroundColor(MuseoColors.textPrimary)
                }
            }
        }
    }
}

// MARK: - Artifact Card View (used in Simple / Folder detail lists)

struct ArtifactCardView: View {
    let artifact: Artifact
    let folder: Folder?
    /// Optional external audio handler – currently unused where we pass `nil`,
    /// but kept for API compatibility if you want list-level audio control later.
    let playAudio: ((URL) -> Void)?
    
    var body: some View {
        Group {
            switch artifact.type {
            case .note:
                NoteArtifactView(artifact: artifact, folder: folder)
                
            case .image:
                ImageArtifactView(artifact: artifact, folder: folder)
                
            case .video:
                VideoArtifactView(artifact: artifact, folder: folder)
                
            case .audio:
                // For now we ignore `playAudio` and just use the inline player.
                AudioArtifactView(artifact: artifact, folder: folder)
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
        ZStack {
            MuseoColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Text("Close")
                            .font(MuseoFont.bodyTitle(16))
                            .foregroundColor(MuseoColors.textPrimary)
                    }
                    
                    Spacer()
                    
                    Text("Folder Details")
                        .font(MuseoFont.header(32))
                        .foregroundColor(MuseoColors.textPrimary)
                    
                    Spacer()
                    
                    Button {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            store.renameFolder(folder, to: trimmed)
                        }
                        dismiss()
                    } label: {
                        Text("Save")
                            .font(MuseoFont.bodyTitle(16))
                            .foregroundColor(MuseoColors.accent)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 12)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // MARK: Folder name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Folder name")
                                .font(MuseoFont.bodyTitle(16))
                                .foregroundColor(MuseoColors.textPrimary)
                            
                            HStack(spacing: 12) {
                                TextField("Name", text: $name)
                                    .font(MuseoFont.paragraph(16))
                                    .foregroundColor(MuseoColors.textPrimary)
                            }
                            .padding(.vertical, 8)
                            
                            // Bottom border
                            Rectangle()
                                .fill(MuseoColors.borderMuted)
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                        // MARK: Items list
                        if itemsInFolder.isEmpty {
                            VStack(spacing: 8) {
                                Text("No items in this folder yet.")
                                    .font(MuseoFont.paragraph(14))
                                    .foregroundColor(MuseoColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 24)
                            .padding(.horizontal, 24)
                        } else {
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(itemsInFolder) { artifact in
                                    Button {
                                        store.editingArtifact = artifact
                                        dismiss()
                                    } label: {
                                        ArtifactCardView(
                                            artifact: artifact,
                                            folder: store.folder(for: artifact),
                                            playAudio: nil
                                        )
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                        }
                        
                        // MARK: Delete folder button
                        Button(role: .destructive) {
                            store.deleteFolder(folder)
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete Folder")
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
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
    }
}
