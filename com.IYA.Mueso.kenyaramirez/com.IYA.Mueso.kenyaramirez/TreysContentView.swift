//
//  TreysContentView.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Reworked Museo: Gallery → Exhibits → Running Boards
//

import SwiftUI
import PhotosUI
import UIKit
import AVKit
import Combine
import AVFoundation
import AVFAudio
import LinkPresentation
import UniformTypeIdentifiers

// MARK: - Sheet Router

enum ActiveSheet: Identifiable, Equatable {
    case capture
    case note
    case link
    case folders
    case detail(BoardItem)

    var id: String {
        switch self {
        case .capture: return "capture"
        case .note:    return "note"
        case .link:    return "link"
        case .folders: return "folders"
        case .detail(let item): return "detail-\(item.id.uuidString)"
        }
    }

    static func == (lhs: ActiveSheet, rhs: ActiveSheet) -> Bool {
        switch (lhs, rhs) {
        case (.capture, .capture),
             (.note, .note),
             (.link, .link),
             (.folders, .folders):
            return true
        case let (.detail(a), .detail(b)):
            return a.id == b.id
        default:
            return false
        }
    }
}

// MARK: - Root View (Gallery + Folder Detail + Quick Capture)

struct TreysContentView: View {
    @StateObject private var store = AppStore()

    // Navigation / context
    @State private var activeSheet: ActiveSheet? = nil
    @State private var currentFolder: MuseoFolder? = nil      // nil = gallery
    @State private var sheetFolder: MuseoFolder? = nil        // capture target folder

    // Note state
    @State private var newNote = ""
    @State private var noteStyle = NoteStyle()
    @State private var noteTags: [String] = []
    @State private var noteFolder: MuseoFolder? = nil

    // Link state
    @State private var linkURLString: String = ""
    @State private var linkTags: [String] = []
    @State private var linkFolder: MuseoFolder? = nil
    @State private var isFetchingLink = false

    // Media pickers
    @State private var photoItem: PhotosPickerItem?
    @State private var videoItem: PhotosPickerItem?

    // Audio record
    @State private var recorder: AVAudioRecorder?
    @State private var isRecording = false
    @State private var audioTags: [String] = []
    @State private var audioFolder: MuseoFolder? = nil
    @State private var recordingStartedAt: Date?
    @State private var elapsed: TimeInterval = 0
    @State private var ticker = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack {
                // Background theme
                Image("wallpaper-1")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                // Main content: Gallery OR Folder Detail
                Group {
                    if let folder = currentFolder {
                        FolderDetailView(
                            folder: folder,
                            store: store,
                            activeSheet: $activeSheet,
                            sheetFolder: $sheetFolder
                        )
                    } else {
                        GalleryView(
                            store: store,
                            currentFolder: $currentFolder,
                            activeSheet: $activeSheet,
                            sheetFolder: $sheetFolder
                        )
                    }
                }

                // Floating Quick Capture (global)
                Button {
                    sheetFolder = currentFolder   // default capture target to current folder (if any)
                    activeSheet = .capture
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 70, height: 70)
                        .background(.black.opacity(0.9))
                        .clipShape(Circle())
                        .shadow(radius: 10, y: 4)
                }
                .accessibilityLabel("Quick Capture")
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 26)

                // Recording banner
                if isRecording {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                            .overlay(Circle().stroke(.white, lineWidth: 1))
                        Text("Recording \(formatted(elapsed))")
                            .monospacedDigit()
                            .bold()
                        Spacer()
                        Button(role: .destructive) { stopRecording() } label: {
                            Text("Stop")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.red.opacity(0.9), in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 110)
                    .onReceive(ticker) { _ in
                        if let start = recordingStartedAt {
                            elapsed = Date().timeIntervalSince(start)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // When inside a folder, show a back-to-gallery button
                ToolbarItem(placement: .topBarLeading) {
                    if currentFolder != nil {
                        Button {
                            currentFolder = nil
                        } label: {
                            Label("Gallery", systemImage: "square.grid.2x2")
                        }
                    }
                }

                // Folder manager (optional, separate from gallery UI)
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        activeSheet = .folders
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                    .accessibilityLabel("Folder & Project Organizer")
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .capture:
                    captureSheet

                case .note:
                    noteEditor

                case .link:
                    linkCapture

                case .folders:
                    FoldersManagerView(
                        store: store,
                        isPresented: Binding(
                            get: { activeSheet == .folders },
                            set: { if !$0 { activeSheet = nil } }
                        )
                    )

                case .detail(let item):
                    NavigationStack {
                        ItemDetailView(item: item, store: store)
                    }
                }
            }
        }
    }
}

// MARK: - Gallery View (Folders as Frame Cards)

// MARK: - Gallery View (Simple Card Grid)

private struct GalleryView: View {
    @ObservedObject var store: AppStore
    @Binding var currentFolder: MuseoFolder?
    @Binding var activeSheet: ActiveSheet?
    @Binding var sheetFolder: MuseoFolder?

    // 2×2 responsive grid
    private let columns = [
        GridItem(.flexible(minimum: 140), spacing: 12),
        GridItem(.flexible(minimum: 140), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerBar

                if store.folders.isEmpty {
                    emptyHint
                        .padding(.top, 20)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 16) {
                            ForEach(store.folders) { folder in
                                Button {
                                    currentFolder = folder
                                    sheetFolder = folder
                                } label: {
                                    SimpleFolderCard(
                                        emoji: folder.emoji,
                                        name: folder.name,
                                        subtitle: folderSubtitle(folder)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding(.top, 12)
        }
    }

    // Top header bar
    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("museo")
                    .font(.system(size: 28, weight: .semibold))
                Text("Your creative gallery")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
        .background(.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.35), lineWidth: 0.5)
        )
    }

    private var emptyHint: some View {
        VStack(spacing: 14) {
            Text("Your gallery is empty")
                .font(.headline)
            Text("Create a folder to start an exhibit, then use the + button to drop notes, photos, videos, voice memos, and links into it.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, minHeight: 240)
    }

    private func folderSubtitle(_ folder: MuseoFolder) -> String {
        let count = store.items.filter { $0.folderID == folder.id }.count
        if count == 0 { return "No items yet" }
        if count == 1 { return "1 item" }
        return "\(count) items"
    }
}

// MARK: - Simple Folder Card

private struct SimpleFolderCard: View {
    let emoji: String
    let name: String
    let subtitle: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.4), lineWidth: 1)
                )

            VStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 24))
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(10)
        }
        // 👇 much smaller tile
        .frame(height: 120)
        .frame(width: 180)
        .shadow(radius: 3, y: 1)
    }
}


// MARK: - Folder Card (Frame + Folder Info)

private struct FolderCard: View {
    let frameAsset: String
    let emoji: String
    let name: String
    let subtitle: String

    var body: some View {
        ZStack {
            // Frame image as the border
            Image(frameAsset)
                .resizable()
                .scaledToFill()
                .clipped()

            // Folder info inside the frame
            VStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 28))
                Text(name)
                    .font(.headline)
                    .lineLimit(1)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(12)
            .multilineTextAlignment(.center)
        }
        // Responsive card: grid decides width, aspect ratio controls height
        .aspectRatio(3/4, contentMode: .fit)
        .shadow(radius: 4, y: 2)
    }
}

// MARK: - Folder Detail View (Running Board)

private struct FolderDetailView: View {
    let folder: MuseoFolder
    @ObservedObject var store: AppStore

    @Binding var activeSheet: ActiveSheet?
    @Binding var sheetFolder: MuseoFolder?

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header

                let items = store.items
                    .filter { $0.folderID == folder.id }
                    .sorted(by: { $0.date > $1.date })

                if items.isEmpty {
                    emptyHint
                } else {
                    ForEach(items) { item in
                        FrameCard(frameAsset: item.frameAsset) {
                            centerFor(item)
                        } title: {
                            titleFor(item)
                        } subtitle: {
                            subtitleFor(item)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipped()
                        .onTapGesture {
                            activeSheet = .detail(item)
                        }
                    }
                }
            }
            .padding(.top, 12)
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button {
                    sheetFolder = folder
                    activeSheet = .capture
                } label: {
                    Label("Add to \(folder.name)", systemImage: "plus.circle.fill")
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("\(folder.emoji) \(folder.name)")
                .font(.title2.bold())
            Text("Your \(folder.name) exhibit")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.bottom, 4)
    }

    private var emptyHint: some View {
        VStack(spacing: 12) {
            Text("This exhibit is empty")
                .font(.headline)
            Text("Use the + button to drop your first note, photo, video, voice memo, or link into this folder.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
    }

    @ViewBuilder
    private func centerFor(_ item: BoardItem) -> some View {
        switch item.kind {
        case .note:
            Text(item.text ?? "")
                .font(.system(size: item.style?.fontSize ?? 18))
                .multilineTextAlignment(item.style?.alignment ?? .center)
                .foregroundStyle(Color.mz_hex(item.style?.hexColor ?? "#111111"))
                .padding(8)

        case .photo:
            if let ui = store.image(for: item.fileName) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.clear
            }

        case .video:
            if let fileName = item.fileName {
                let url = store.urlForNewFile(named: fileName)
                VideoPlayerView(url: url)
                    .frame(maxWidth: 200, maxHeight: 140)
                    .cornerRadius(10)
            } else {
                Image(systemName: "play.rectangle.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(18)
            }

        case .audio:
            if let file = item.fileName {
                let url = store.urlForNewFile(named: file)
                AudioPlayerBar(url: url)
                    .frame(maxWidth: 220)
            } else {
                Image(systemName: "waveform")
                    .resizable()
                    .scaledToFit()
                    .padding(18)
            }

        case .link:
            if let ui = store.image(for: item.linkThumb) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "link")
                    .resizable()
                    .scaledToFit()
                    .padding(18)
            }
        }
    }

    private func titleFor(_ item: BoardItem) -> String {
        switch item.kind {
        case .note:  return "Note"
        case .photo: return "Photo"
        case .video: return "Video"
        case .audio: return "Voice Memo"
        case .link:  return item.linkTitle ?? "Link"
        }
    }

    private func subtitleFor(_ item: BoardItem) -> String {
        switch item.kind {
        case .note:
            return (item.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        case .photo:
            return "Captured image"
        case .video:
            return "Saved video"
        case .audio:
            return "Recorded audio"
        case .link:
            if let u = item.urlString, let host = URL(string: u)?.host {
                return host
            }
            return item.urlString ?? ""
        }
    }
}

// MARK: - Capture Sheet

extension TreysContentView {
    private var captureSheet: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        noteFolder = sheetFolder
                        noteTags = []
                        newNote = ""
                        noteStyle = NoteStyle()
                        activeSheet = .note
                    } label: {
                        captureRow(icon: "note.text", title: "Note")
                    }

                    PhotosPicker(selection: $photoItem, matching: .images) {
                        captureRow(icon: "photo", title: "Photo")
                    }
                    .onChange(of: photoItem) { _, newItem in
                        Task { await handleSelectedPhoto(newItem, folder: sheetFolder, tags: []) }
                        activeSheet = nil
                    }

                    PhotosPicker(selection: $videoItem, matching: .videos) {
                        captureRow(icon: "video", title: "Video")
                    }
                    .onChange(of: videoItem) { _, newItem in
                        Task { await handleSelectedVideo(newItem, folder: sheetFolder, tags: []) }
                        activeSheet = nil
                    }

                    Button {
                        audioFolder = sheetFolder
                        audioTags = []
                        Task { await handleVoiceMemo() }
                    } label: {
                        captureRow(
                            icon: isRecording ? "stop.circle.fill" : "waveform",
                            title: isRecording ? "Stop Recording" : "Voice Memo"
                        )
                    }

                    Button {
                        linkURLString = ""
                        linkTags = []
                        linkFolder = sheetFolder
                        activeSheet = .link
                    } label: {
                        captureRow(icon: "link", title: "Link")
                    }
                }
            }
            .navigationTitle("Quick Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { activeSheet = nil }
                }
            }
        }
        .presentationDetents([.height(380), .medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func captureRow(icon: String, title: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .frame(width: 24)
            Text(title)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Note Editor

extension TreysContentView {
    private var noteEditor: some View {
        NavigationStack {
            VStack(spacing: 12) {
                GroupBox("Style") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Font")
                                .frame(width: 60, alignment: .leading)
                            Slider(
                                value: Binding(
                                    get: { Double(noteStyle.fontSize) },
                                    set: { noteStyle.fontSize = CGFloat($0) }
                                ),
                                in: 12...36,
                                step: 1
                            )
                            Text("\(Int(noteStyle.fontSize))")
                        }
                        HStack {
                            Text("Align")
                                .frame(width: 60, alignment: .leading)
                            Picker("", selection: $noteStyle.alignment) {
                                Text("Left").tag(TextAlignment.leading)
                                Text("Center").tag(TextAlignment.center)
                                Text("Right").tag(TextAlignment.trailing)
                            }
                            .pickerStyle(.segmented)
                        }
                        HStack {
                            Text("Color")
                                .frame(width: 60, alignment: .leading)
                            TextField("#111111", text: $noteStyle.hexColor)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.asciiCapable)
                            Circle()
                                .fill(Color.mz_hex(noteStyle.hexColor))
                                .frame(width: 20, height: 20)
                                .overlay(Circle().stroke(.black.opacity(0.1)))
                        }
                    }
                }

                GroupBox("Organize") {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Folder", selection: Binding(
                            get: {
                                noteFolder?.id
                                ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
                            },
                            set: { id in
                                noteFolder = store.folders.first(where: { $0.id == id })
                            }
                        )) {
                            Text("None")
                                .tag(UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
                            ForEach(store.folders) { f in
                                Text("\(f.emoji) \(f.name)").tag(f.id)
                            }
                        }
                        TagEditor(tags: $noteTags)
                    }
                }

                TextEditor(text: $newNote)
                    .padding()
                    .frame(maxHeight: .infinity)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.black.opacity(0.05))
                    )
                    .padding(.top, 4)

                FrameCard(frameAsset: previewFrame()) {
                    Text(newNote.isEmpty ? "Start typing…" : newNote)
                        .font(.system(size: noteStyle.fontSize))
                        .multilineTextAlignment(noteStyle.alignment)
                        .foregroundStyle(Color.mz_hex(noteStyle.hexColor))
                        .padding(8)
                } title: {
                    "Note"
                } subtitle: {
                    newNote.isEmpty ? "" : "Preview"
                }
                .padding(.top, 4)
            }
            .padding()
            .navigationTitle("New Note")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { activeSheet = nil }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let text = newNote.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !text.isEmpty else { activeSheet = nil; return }

                        let item = BoardItem(
                            kind: .note,
                            text: text,
                            style: noteStyle,
                            fileName: nil,
                            urlString: nil,
                            linkTitle: nil,
                            linkThumb: nil,
                            date: Date(),
                            frameAsset: previewFrame(),
                            folderID: noteFolder?.id,
                            tags: noteTags
                        )
                        store.items.insert(item, at: 0)
                        newNote = ""
                        noteTags = []
                        noteFolder = nil
                        activeSheet = nil
                    }
                    .bold()
                }
            }
        }
    }
}

// MARK: - Link Capture

extension TreysContentView {
    private var linkCapture: some View {
        NavigationStack {
            Form {
                Section("URL") {
                    TextField("https://example.com", text: $linkURLString)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                }
                Section("Organize") {
                    Picker("Folder", selection: Binding(
                        get: {
                            linkFolder?.id
                            ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
                        },
                        set: { id in
                            linkFolder = store.folders.first(where: { $0.id == id })
                        }
                    )) {
                        Text("None")
                            .tag(UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
                        ForEach(store.folders) { f in
                            Text("\(f.emoji) \(f.name)").tag(f.id)
                        }
                    }
                    TagEditor(tags: $linkTags)
                }
                if isFetchingLink {
                    ProgressView("Fetching preview…")
                }
            }
            .navigationTitle("Add Link")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { activeSheet = nil }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task { await saveLink() }
                    }
                    .bold()
                    .disabled(
                        linkURLString
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .isEmpty || isFetchingLink
                    )
                }
            }
        }
    }

    private func saveLink() async {
        let urlStr = linkURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: urlStr) else { return }
        isFetchingLink = true

        var title: String? = nil
        var thumbFile: String? = nil

        do {
            let provider = LPMetadataProvider()
            let meta = try await provider.startFetchingMetadata(for: url)
            title = meta.title ?? url.host

            if let ip = meta.imageProvider,
               let data = await loadImageData(from: ip),
               let ui = UIImage(data: data) {
                let name = "linkthumb-\(UUID().uuidString).jpg"
                if let jd = ui.jpegData(compressionQuality: 0.9) {
                    try? jd.write(to: store.urlForNewFile(named: name))
                    thumbFile = name
                }
            }
        } catch {
            title = title ?? url.host
        }

        let item = BoardItem(
            kind: .link,
            text: nil,
            style: nil,
            fileName: nil,
            urlString: urlStr,
            linkTitle: title,
            linkThumb: thumbFile,
            date: Date(),
            frameAsset: previewFrame(),
            folderID: linkFolder?.id,
            tags: linkTags
        )
        store.items.insert(item, at: 0)

        isFetchingLink = false
        linkURLString = ""
        linkTags = []
        linkFolder = nil
        activeSheet = nil
    }

    private func loadImageData(from provider: NSItemProvider) async -> Data? {
        await withCheckedContinuation { cont in
            provider.loadItem(
                forTypeIdentifier: UTType.image.identifier,
                options: nil
            ) { item, _ in
                if let url = item as? URL,
                   let data = try? Data(contentsOf: url) {
                    cont.resume(returning: data)
                } else if let data = item as? Data {
                    cont.resume(returning: data)
                } else {
                    cont.resume(returning: nil)
                }
            }
        }
    }
}

// MARK: - Media Helpers

extension TreysContentView {
    private func handleSelectedPhoto(
        _ item: PhotosPickerItem?,
        folder: MuseoFolder?,
        tags: [String]
    ) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self) {
            let name = "photo-\(UUID().uuidString).jpg"
            try? data.write(to: store.urlForNewFile(named: name))
            let boardItem = BoardItem(
                kind: .photo,
                text: nil,
                style: nil,
                fileName: name,
                urlString: nil,
                linkTitle: nil,
                linkThumb: nil,
                date: Date(),
                frameAsset: previewFrame(),
                folderID: folder?.id,
                tags: tags
            )
            store.items.insert(boardItem, at: 0)
        }
        photoItem = nil
    }

    private func handleSelectedVideo(
        _ item: PhotosPickerItem?,
        folder: MuseoFolder?,
        tags: [String]
    ) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self) {
            let name = "video-\(UUID().uuidString).mov"
            try? data.write(to: store.urlForNewFile(named: name))
            let boardItem = BoardItem(
                kind: .video,
                text: nil,
                style: nil,
                fileName: name,
                urlString: nil,
                linkTitle: nil,
                linkThumb: nil,
                date: Date(),
                frameAsset: previewFrame(),
                folderID: folder?.id,
                tags: tags
            )
            store.items.insert(boardItem, at: 0)
        }
        videoItem = nil
    }
}

// MARK: - Voice Memo

extension TreysContentView {
    private func handleVoiceMemo() async {
        if isRecording {
            stopRecording()
            return
        }

        if #available(iOS 17.0, *) {
            let granted = await AVAudioApplication.requestRecordPermission()
            guard granted else { return }
        } else {
            let session = AVAudioSession.sharedInstance()
            switch session.recordPermission {
            case .granted:
                break
            case .undetermined:
                session.requestRecordPermission { _ in }
                return
            case .denied:
                return
            @unknown default:
                return
            }
        }

        do {
            try startRecording()
        } catch {
            print("Recording error: \(error)")
        }
    }

    private func startRecording() throws {
        let name = "audio-\(UUID().uuidString).m4a"
        let url = store.urlForNewFile(named: name)

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 12_000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default)
        try session.setActive(true, options: [])

        recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder?.record()
        isRecording = true
        recordingStartedAt = Date()
        elapsed = 0

        // Hard cap at 60 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            if self.isRecording {
                self.stopRecording()
            }
        }
    }

    private func stopRecording() {
        guard let rec = recorder else { return }
        rec.stop()
        isRecording = false
        recordingStartedAt = nil
        elapsed = 0

        let fileName = rec.url.lastPathComponent
        let item = BoardItem(
            kind: .audio,
            text: nil,
            style: nil,
            fileName: fileName,
            urlString: nil,
            linkTitle: nil,
            linkThumb: nil,
            date: Date(),
            frameAsset: previewFrame(),
            folderID: audioFolder?.id,
            tags: audioTags
        )
        store.items.insert(item, at: 0)
        recorder = nil
    }
}

// MARK: - Shared Helpers

extension TreysContentView {
    private func previewFrame() -> String {
        ["frame-1", "frame-2", "frame-3", "frame-4"].randomElement() ?? "frame-1"
    }

    private func formatted(_ t: TimeInterval) -> String {
        let s = Int(t)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }
}

// MARK: - Item Detail View

struct ItemDetailView: View {
    let item: BoardItem
    @ObservedObject var store: AppStore

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(titleFor(item))
                    .font(.title2)
                    .bold()

                contentFor(item)

                if !subtitleFor(item).isEmpty {
                    Text(subtitleFor(item))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                if !item.tags.isEmpty {
                    Wrap(item.tags) { tag in
                        Text("#\(tag)")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
        }
        .navigationTitle("Item")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func contentFor(_ item: BoardItem) -> some View {
        switch item.kind {
        case .note:
            Text(item.text ?? "")
                .font(.system(size: item.style?.fontSize ?? 18))
                .multilineTextAlignment(item.style?.alignment ?? .center)
                .foregroundStyle(Color.mz_hex(item.style?.hexColor ?? "#111111"))
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

        case .photo:
            if let ui = store.image(for: item.fileName) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(12)
            }

        case .video:
            if let url = store.urlForNewFile(named: item.fileName ?? "") as URL? {
                VideoPlayerView(url: url)
                    .frame(height: 280)
                    .cornerRadius(12)
            }

        case .audio:
            if let file = item.fileName {
                let url = store.urlForNewFile(named: file)
                AudioPlayerBar(url: url)
            }

        case .link:
            if let u = item.urlString,
               let url = URL(string: u) {
                Link(destination: url) {
                    HStack {
                        Image(systemName: "link.circle.fill")
                        Text(item.linkTitle ?? url.host ?? u)
                            .lineLimit(2)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            if let ui = store.image(for: item.linkThumb) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(12)
            }
        }
    }

    private func titleFor(_ item: BoardItem) -> String {
        switch item.kind {
        case .note:  return "Note"
        case .photo: return "Photo"
        case .video: return "Video"
        case .audio: return "Voice Memo"
        case .link:  return item.linkTitle ?? "Link"
        }
    }

    private func subtitleFor(_ item: BoardItem) -> String {
        switch item.kind {
        case .note:
            return (item.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        case .photo:
            return "Captured image"
        case .video:
            return "Saved video"
        case .audio:
            return "Recorded audio"
        case .link:
            if let u = item.urlString,
               let host = URL(string: u)?.host {
                return host
            }
            return item.urlString ?? ""
        }
    }
}

// MARK: - Inline Players

struct VideoPlayerView: View {
    let url: URL
    var body: some View {
        VideoPlayer(player: AVPlayer(url: url))
    }
}

final class SimpleAudioPlayer: NSObject, ObservableObject {
    @Published var isPlaying = false
    private var player: AVAudioPlayer?

    func load(_ url: URL) {
        player = try? AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
        isPlaying = false
    }

    func toggle() {
        guard let p = player else { return }
        if p.isPlaying {
            p.pause()
            isPlaying = false
        } else {
            p.play()
            isPlaying = true
        }
    }
}

struct AudioPlayerBar: View {
    let url: URL
    @StateObject private var engine = SimpleAudioPlayer()

    var body: some View {
        HStack(spacing: 12) {
            Button(action: { engine.toggle() }) {
                Image(systemName: engine.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 28, weight: .semibold))
            }
            Text(url.lastPathComponent)
                .lineLimit(1)
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .onAppear { engine.load(url) }
    }
}

// MARK: - Preview

#Preview {
    TreysContentView()
}

