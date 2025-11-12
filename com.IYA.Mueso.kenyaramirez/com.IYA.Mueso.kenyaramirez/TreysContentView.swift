//
//  TreyContentView.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created by Trey Jennings on 11/12/25.
//

import SwiftUI
import PhotosUI
import UIKit
import AVKit
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
}

// MARK: - ContentView

struct TreysContentView: View {
    @StateObject private var store = AppStore()

    // Single-sheet state
    @State private var activeSheet: ActiveSheet? = nil

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
        ZStack {
            Image("wallpaper-1").resizable().scaledToFill().ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    headerBar
                    foldersRow

                    if store.filteredItems.isEmpty {
                        emptyHint
                    } else {
                        VStack(spacing: 28) {
                            ForEach(store.filteredItems) { item in
                                FrameCard(frameAsset: item.frameAsset) {
                                    centerFor(item)
                                } title: {
                                    titleFor(item)
                                } subtitle: {
                                    subtitleFor(item)
                                }
                                .padding(.horizontal, 20)
                                .onTapGesture { activeSheet = .detail(item) }
                            }
                        }
                        .padding(.top, 6)
                        .padding(.bottom, 100)
                    }
                }
                .padding(.top, 12)
            }

            // Floating Quick Capture
            Button { activeSheet = .capture } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(.black.opacity(0.9))
                    .clipShape(Circle())
                    .shadow(radius: 8, y: 3)
            }
            .accessibilityLabel("Quick Capture")
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 22)

            // Recording banner
            if isRecording {
                HStack(spacing: 10) {
                    Circle().fill(Color.red).frame(width: 10, height: 10)
                        .overlay(Circle().stroke(.white, lineWidth: 1))
                    Text("Recording \(formatted(elapsed))")
                        .monospacedDigit().bold()
                    Spacer()
                    Button(role: .destructive) { stopRecording() } label: {
                        Text("Stop")
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Color.red.opacity(0.9), in: Capsule())
                            .foregroundStyle(.white)
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.bottom, 100)
                .onReceive(ticker) { _ in
                    if let start = recordingStartedAt { elapsed = Date().timeIntervalSince(start) }
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .capture: captureSheet
            case .note:    noteEditor
            case .link:    linkCapture
            case .folders:     FoldersManagerView(
                store: store,
                isPresented: Binding(
                    get: { activeSheet == .folders },
                    set: { if !$0 { activeSheet = nil } }
                ))
            case .detail(let item): DetailView(item: item, store: store)
            }
        }
    }


    // MARK: Header / Folders

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("museo").font(.system(size: 28, weight: .semibold))
                Text("Your creative space").font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Button { activeSheet = .folders } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 20, weight: .semibold))
                    .padding(10)
                    .background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 12))
            }
            .accessibilityLabel("Folder & Project Organizer")
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.35), lineWidth: 0.5))
    }

    private var foldersRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Button { store.selectedFolder = nil } label: {
                    HStack { Image(systemName: "square.grid.2x2"); Text("All") }
                        .font(.subheadline)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background((store.selectedFolder == nil ? Color.white.opacity(0.9) : Color.white.opacity(0.55)), in: Capsule())
                }
                ForEach(store.folders) { f in
                    Button { store.selectedFolder = f } label: {
                        HStack { Text(f.emoji); Text(f.name) }
                            .font(.subheadline)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background((store.selectedFolder?.id == f.id ? Color.white.opacity(0.9) : Color.white.opacity(0.55)), in: Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    

    // MARK: Capture Sheet

    private var captureSheet: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        noteFolder = store.selectedFolder
                        noteTags = []; newNote = ""; noteStyle = NoteStyle()
                        activeSheet = .note
                    } label: { captureRow(icon: "note.text", title: "Note") }

                    PhotosPicker(selection: $photoItem, matching: .images) {
                        captureRow(icon: "photo", title: "Photo")
                    }
                    .onChange(of: photoItem) { _, new in
                        Task { await handleSelectedPhoto(new, folder: store.selectedFolder, tags: []) }
                        activeSheet = nil
                    }

                    PhotosPicker(selection: $videoItem, matching: .videos) {
                        captureRow(icon: "video", title: "Video")
                    }
                    .onChange(of: videoItem) { _, new in
                        Task { await handleSelectedVideo(new, folder: store.selectedFolder, tags: []) }
                        activeSheet = nil
                    }

                    Button {
                        audioFolder = store.selectedFolder
                        audioTags = []
                        Task { await handleVoiceMemo() }
                    } label: {
                        captureRow(icon: isRecording ? "stop.circle.fill" : "waveform",
                                   title: isRecording ? "Stop Recording" : "Voice Memo")
                    }

                    Button {
                        linkURLString = ""; linkTags = []; linkFolder = store.selectedFolder
                        activeSheet = .link
                    } label: { captureRow(icon: "link", title: "Link") }
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
            Image(systemName: icon).frame(width: 24)
            Text(title)
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Color(.tertiaryLabel))
        }
        .contentShape(Rectangle())
    }

    // MARK: Note Editor

    private var noteEditor: some View {
        NavigationStack {
            VStack(spacing: 12) {
                GroupBox("Style") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Font").frame(width: 60, alignment: .leading)
                            Slider(value: Binding(get: {
                                Double(noteStyle.fontSize)
                            }, set: { noteStyle.fontSize = CGFloat($0) }), in: 12...36, step: 1)
                            Text("\(Int(noteStyle.fontSize))")
                        }
                        HStack {
                            Text("Align").frame(width: 60, alignment: .leading)
                            Picker("", selection: $noteStyle.alignment) {
                                Text("Left").tag(TextAlignment.leading)
                                Text("Center").tag(TextAlignment.center)
                                Text("Right").tag(TextAlignment.trailing)
                            }.pickerStyle(.segmented)
                        }
                        HStack {
                            Text("Color").frame(width: 60, alignment: .leading)
                            TextField("#111111", text: $noteStyle.hexColor)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.asciiCapable)
                            Circle().fill(Color.mz_hex(noteStyle.hexColor))
                                .frame(width: 20, height: 20)
                                .overlay(Circle().stroke(.black.opacity(0.1)))
                        }
                    }
                }

                GroupBox("Organize") {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Folder", selection: Binding(
                            get: { noteFolder?.id ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000") ?? UUID() },
                            set: { id in noteFolder = store.folders.first(where: { $0.id == id }) }
                        )) {
                            Text("None").tag(UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
                            ForEach(store.folders) { f in Text("\(f.emoji) \(f.name)").tag(f.id) }
                        }
                        TagEditor(tags: $noteTags)
                    }
                }

                TextEditor(text: $newNote)
                    .padding()
                    .frame(maxHeight: .infinity)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(.black.opacity(0.05)))
                    .padding(.top, 4)

                FrameCard(frameAsset: previewFrame()) {
                    Text(newNote.isEmpty ? "Start typing…" : newNote)
                        .font(.system(size: noteStyle.fontSize))
                        .multilineTextAlignment(noteStyle.alignment)
                        .foregroundStyle(Color.mz_hex(noteStyle.hexColor))
                        .padding(8)
                } title: { "Note" } subtitle: { newNote.isEmpty ? "" : "Preview" }
                .padding(.top, 4)
            }
            .padding()
            .navigationTitle("New Note")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { activeSheet = nil } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let text = newNote.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !text.isEmpty else { activeSheet = nil; return }
                        let item = BoardItem(
                            kind: .note, text: text, style: noteStyle,
                            fileName: nil, urlString: nil, linkTitle: nil, linkThumb: nil,
                            date: Date(), frameAsset: previewFrame(),
                            folderID: noteFolder?.id, tags: noteTags
                        )
                        store.items.insert(item, at: 0)
                        newNote = ""; noteTags = []; noteFolder = nil
                        activeSheet = nil
                    }.bold()
                }
            }
        }
    }

    // MARK: Link Capture

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
                        get: { linkFolder?.id ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000") ?? UUID() },
                        set: { id in linkFolder = store.folders.first(where: { $0.id == id }) }
                    )) {
                        Text("None").tag(UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
                        ForEach(store.folders) { f in Text("\(f.emoji) \(f.name)").tag(f.id) }
                    }
                    TagEditor(tags: $linkTags)
                }
                if isFetchingLink { ProgressView("Fetching preview…") }
            }
            .navigationTitle("Add Link")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { activeSheet = nil } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { Task { await saveLink() } }
                        .bold()
                        .disabled(linkURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isFetchingLink)
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
            kind: .link, text: nil, style: nil, fileName: nil,
            urlString: urlStr, linkTitle: title, linkThumb: thumbFile,
            date: Date(), frameAsset: previewFrame(),
            folderID: linkFolder?.id, tags: linkTags
        )
        store.items.insert(item, at: 0)

        isFetchingLink = false
        linkURLString = ""; linkTags = []; linkFolder = nil
        activeSheet = nil
    }

    private func loadImageData(from provider: NSItemProvider) async -> Data? {
        await withCheckedContinuation { cont in
            provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, _ in
                if let url = item as? URL, let data = try? Data(contentsOf: url) {
                    cont.resume(returning: data)
                } else if let data = item as? Data {
                    cont.resume(returning: data)
                } else {
                    cont.resume(returning: nil)
                }
            }
        }
    }

    // MARK: Photos / Videos

    private func handleSelectedPhoto(_ item: PhotosPickerItem?, folder: MuseoFolder?, tags: [String]) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self) {
            let name = "photo-\(UUID().uuidString).jpg"
            try? data.write(to: store.urlForNewFile(named: name))
            store.items.insert(BoardItem(kind: .photo, text: nil, style: nil, fileName: name, urlString: nil, linkTitle: nil, linkThumb: nil, date: Date(), frameAsset: previewFrame(), folderID: folder?.id, tags: tags), at: 0)
        }
        photoItem = nil
    }

    private func handleSelectedVideo(_ item: PhotosPickerItem?, folder: MuseoFolder?, tags: [String]) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self) {
            let name = "video-\(UUID().uuidString).mov"
            try? data.write(to: store.urlForNewFile(named: name))
            store.items.insert(BoardItem(kind: .video, text: nil, style: nil, fileName: name, urlString: nil, linkTitle: nil, linkThumb: nil, date: Date(), frameAsset: previewFrame(), folderID: folder?.id, tags: tags), at: 0)
        }
        videoItem = nil
    }

    // MARK: Voice memo

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
            case .granted: break
            case .undetermined:
                session.requestRecordPermission { _ in }
                return
            case .denied: return
            @unknown default: return
            }
        }

        do { try startRecording() } catch { print("Recording error: \(error)") }
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            if self.isRecording { self.stopRecording() }
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
            kind: .audio, text: nil, style: nil, fileName: fileName,
            urlString: nil, linkTitle: nil, linkThumb: nil,
            date: Date(), frameAsset: previewFrame(),
            folderID: audioFolder?.id, tags: audioTags
        )
        store.items.insert(item, at: 0)
        recorder = nil
    }

    // MARK: Helpers

    private func previewFrame() -> String { ["frame-1","frame-2","frame-3","frame-4"].randomElement() ?? "frame-1" }

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
            if let ui = store.image(for: item.fileName) { Image(uiImage: ui).resizable().scaledToFill() }
            else { Color.clear }

        case .video:
            if let url = storeURL(fileName: item.fileName) {
                VideoPlayerView(url: url).frame(maxWidth: 200, maxHeight: 140).cornerRadius(10)
            } else {
                Image(systemName: "play.rectangle.fill").resizable().scaledToFit().padding(18)
            }

        case .audio:
            if let url = storeURL(fileName: item.fileName) {
                AudioPlayerBar(url: url)
                    .frame(maxWidth: 220)
            } else {
                Image(systemName: "waveform").resizable().scaledToFit().padding(18)
            }

        case .link:
            if let ui = store.image(for: item.linkThumb) { Image(uiImage: ui).resizable().scaledToFill() }
            else { Image(systemName: "link").resizable().scaledToFit().padding(18) }
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
        case .note:  return (item.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        case .photo: return "Captured image"
        case .video: return "Saved video"
        case .audio: return "Recorded audio"
        case .link:
            if let u = item.urlString, let host = URL(string: u)?.host { return host }
            return item.urlString ?? ""
        }
    }

    private var emptyHint: some View {
        VStack(spacing: 14) {
            Text("Your board is empty").font(.headline)
            Text("Tap the + to quickly capture a note, photo, video, voice memo, or link. Organize with folders and tags.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, minHeight: 240)
    }

    private func storeURL(fileName: String?) -> URL? {
        guard let fileName else { return nil }
        return store.urlForNewFile(named: fileName)
    }

    private func formatted(_ t: TimeInterval) -> String {
        let s = Int(t)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }
}


// MARK: - Detail View

struct DetailView: View {
    let item: BoardItem
    @ObservedObject var store: AppStore

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(titleFor(item)).font(.title2).bold()
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
                            .padding(.horizontal, 10).padding(.vertical, 6)
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
                Image(uiImage: ui).resizable().scaledToFit().cornerRadius(12)
            }

        case .video:
            if let url = store.urlForNewFile(named: item.fileName ?? "") as URL? {
                VideoPlayerView(url: url).frame(height: 280).cornerRadius(12)
            }

        case .audio:
            if let file = item.fileName {
                let url = store.urlForNewFile(named: file)
                AudioPlayerBar(url: url)
            }

        case .link:
            if let u = item.urlString, let url = URL(string: u) {
                Link(destination: url) {
                    HStack {
                        Image(systemName: "link.circle.fill")
                        Text(item.linkTitle ?? url.host ?? u).lineLimit(2)
                        Spacer(); Image(systemName: "arrow.up.right.square")
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            if let ui = store.image(for: item.linkThumb) {
                Image(uiImage: ui).resizable().scaledToFit().cornerRadius(12)
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
        case .note:  return (item.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        case .photo: return "Captured image"
        case .video: return "Saved video"
        case .audio: return "Recorded audio"
        case .link:
            if let u = item.urlString, let host = URL(string: u)?.host { return host }
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
        if p.isPlaying { p.pause(); isPlaying = false } else { p.play(); isPlaying = true }
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
            Text(url.lastPathComponent).lineLimit(1)
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .onAppear { engine.load(url) }
    }
}


// MARK: - Preview

#Preview { ContentView() }
