import SwiftUI
import PhotosUI
import AVFoundation
import AVFAudio          // iOS 17 AVAudioApplication
import LinkPresentation
import UniformTypeIdentifiers

// MARK: - Models

struct MuseoFolder: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var emoji: String
    init(id: UUID = UUID(), name: String, emoji: String) {
        self.id = id; self.name = name; self.emoji = emoji
    }
}

enum ItemKind: String, Codable { case note, photo, video, audio, link }

struct NoteStyle: Hashable, Codable {
    var fontSize: CGFloat = 18
    var alignment: TextAlignment = .center
    var hexColor: String = "#111111"

    private enum CodingKeys: String, CodingKey { case fontSize, alignment, hexColor }
    private enum AlignKey: String, Codable { case leading, center, trailing }

    init(fontSize: CGFloat = 18, alignment: TextAlignment = .center, hexColor: String = "#111111") {
        self.fontSize = fontSize; self.alignment = alignment; self.hexColor = hexColor
    }
    init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        fontSize = CGFloat(try c.decode(Double.self, forKey: .fontSize))
        switch try c.decode(AlignKey.self, forKey: .alignment) {
        case .leading: alignment = .leading
        case .center:  alignment = .center
        case .trailing:alignment = .trailing
        }
        hexColor = try c.decode(String.self, forKey: .hexColor)
    }
    func encode(to e: Encoder) throws {
        var c = e.container(keyedBy: CodingKeys.self)
        try c.encode(Double(fontSize), forKey: .fontSize)
        let a: AlignKey = (alignment == .leading ? .leading : (alignment == .trailing ? .trailing : .center))
        try c.encode(a, forKey: .alignment)
        try c.encode(hexColor, forKey: .hexColor)
    }
}

struct BoardItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var kind: ItemKind
    var text: String?               // note
    var style: NoteStyle?           // note
    var fileName: String?           // photo / video / audio
    var urlString: String?          // link
    var linkTitle: String?          // link
    var linkThumb: String?          // link (saved image filename)
    var date: Date = Date()
    var frameAsset: String          // "frame-1"... "frame-4"
    var folderID: UUID?             // project/folder
    var tags: [String] = []
}

// MARK: - Store

@MainActor
final class AppStore: ObservableObject {
    @Published var items: [BoardItem] = [] { didSet { save() } }
    @Published var folders: [MuseoFolder] = [] { didSet { save() } }
    @Published var selectedFolder: MuseoFolder? = nil { didSet { save() } }

    private let key = "museo.store.v2"

    private struct Snapshot: Codable {
        var items: [BoardItem]
        var folders: [MuseoFolder]
        var selectedFolder: MuseoFolder?
    }

    init() { load(); seedIfEmpty() }

    private func seedIfEmpty() {
        if folders.isEmpty {
            folders = [
                MuseoFolder(name: "Ideas", emoji: "💡"),
                MuseoFolder(name: "Photos", emoji: "📷"),
                MuseoFolder(name: "Audio", emoji: "🎙️")
            ]
        }
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        items = snap.items; folders = snap.folders; selectedFolder = snap.selectedFolder
    }

    func save() {
        let snap = Snapshot(items: items, folders: folders, selectedFolder: selectedFolder)
        if let data = try? JSONEncoder().encode(snap) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    // Files
    func urlForNewFile(named name: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent(name)
    }
    func image(for fileName: String?) -> UIImage? {
        guard let fileName else { return nil }
        let url = urlForNewFile(named: fileName)
        return UIImage(contentsOfFile: url.path)
    }

    // Filtered view
    var filteredItems: [BoardItem] {
        guard let f = selectedFolder else { return items }
        return items.filter { $0.folderID == f.id }
    }
}

// MARK: - Single-screen app

struct ContentView: View {
    @StateObject private var store = AppStore()

    @State private var showCapture = false
    @State private var showNoteEditor = false
    @State private var showLinkCapture = false
    @State private var showFoldersSheet = false

    @State private var newNote = ""
    @State private var noteStyle = NoteStyle()
    @State private var noteTags: [String] = []
    @State private var noteFolder: MuseoFolder? = nil

    @State private var linkURLString: String = ""
    @State private var linkTags: [String] = []
    @State private var linkFolder: MuseoFolder? = nil
    @State private var isFetchingLink = false

    @State private var photoItem: PhotosPickerItem?
    @State private var videoItem: PhotosPickerItem?

    // Audio
    @State private var recorder: AVAudioRecorder?
    @State private var isRecording = false
    @State private var audioTags: [String] = []
    @State private var audioFolder: MuseoFolder? = nil

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
                            }
                        }
                        .padding(.top, 6)
                        .padding(.bottom, 100)
                    }
                }
                .padding(.top, 12)
            }

            Button { showCapture = true } label: {
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
        }
        .sheet(isPresented: $showCapture) { captureSheet }
        .sheet(isPresented: $showNoteEditor) { noteEditor }
        .sheet(isPresented: $showLinkCapture) { linkCapture }
        .sheet(isPresented: $showFoldersSheet) { foldersManager }
    }

    // MARK: Header / Folders

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("museo").font(.system(size: 28, weight: .semibold))
                Text("Your creative space").font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Button { showFoldersSheet = true } label: {
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
                        showNoteEditor = true
                    } label: { captureRow(icon: "note.text", title: "Note") }

                    PhotosPicker(selection: $photoItem, matching: .images) {
                        captureRow(icon: "photo", title: "Photo")
                    }
                    .onChange(of: photoItem) { _, new in
                        Task { await handleSelectedPhoto(new, folder: store.selectedFolder, tags: []) }
                        showCapture = false
                    }

                    PhotosPicker(selection: $videoItem, matching: .videos) {
                        captureRow(icon: "video", title: "Video")
                    }
                    .onChange(of: videoItem) { _, new in
                        Task { await handleSelectedVideo(new, folder: store.selectedFolder, tags: []) }
                        showCapture = false
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
                        showLinkCapture = true
                    } label: { captureRow(icon: "link", title: "Link") }
                }
            }
            .navigationTitle("Quick Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Close") { showCapture = false } } }
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
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { showNoteEditor = false } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let text = newNote.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !text.isEmpty else { showNoteEditor = false; return }
                        let item = BoardItem(
                            kind: .note, text: text, style: noteStyle,
                            fileName: nil, urlString: nil, linkTitle: nil, linkThumb: nil,
                            date: Date(), frameAsset: previewFrame(),
                            folderID: noteFolder?.id, tags: noteTags
                        )
                        store.items.insert(item, at: 0)
                        newNote = ""; noteTags = []; noteFolder = nil
                        showNoteEditor = false; showCapture = false
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
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { showLinkCapture = false } }
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
            title = meta.title

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
            // ignore; saving without preview is fine
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
        showLinkCapture = false; showCapture = false
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

    // MARK: Voice memo (iOS 17+ safe)

    private func handleVoiceMemo() async {
        if isRecording {
            stopRecording()
            showCapture = false
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            if self.isRecording { self.stopRecording() }
        }
    }

    private func stopRecording() {
        guard let rec = recorder else { return }
        rec.stop()
        isRecording = false
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

    // MARK: Folder manager

    private var foldersManager: some View {
        NavigationStack {
            List {
                Section("Folders") {
                    ForEach(store.folders) { f in
                        HStack {
                            Text(f.emoji); Text(f.name); Spacer()
                            if store.selectedFolder?.id == f.id {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { store.selectedFolder = f }
                        .contextMenu {
                            Button("Set as Filter") { store.selectedFolder = f }
                            Button("Rename") { renameFolder(f) }
                            Button("Delete", role: .destructive) { deleteFolder(f) }
                        }
                    }
                    Button { addFolder() } label: { Label("New Folder", systemImage: "folder.badge.plus") }
                }
                Section { Button("Show All Items") { store.selectedFolder = nil } }
            }
            .navigationTitle("Projects & Folders")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showFoldersSheet = false } } }
        }
    }

    private func addFolder() {
        var base = "Folder"; var idx = 1
        while store.folders.contains(where: { $0.name == base }) { idx += 1; base = "Folder \(idx)" }
        store.folders.append(MuseoFolder(name: base, emoji: "📁"))
    }
    private func deleteFolder(_ f: MuseoFolder) {
        store.items = store.items.map { var m = $0; if m.folderID == f.id { m.folderID = nil }; return m }
        store.folders.removeAll { $0.id == f.id }
        if store.selectedFolder?.id == f.id { store.selectedFolder = nil }
    }
    private func renameFolder(_ f: MuseoFolder) {
        var tf: UITextField?
        let alert = UIAlertController(title: "Rename Folder", message: nil, preferredStyle: .alert)
        alert.addTextField { t in t.text = f.name; tf = t }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
            let new = tf?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !new.isEmpty, let idx = store.folders.firstIndex(where: { $0.id == f.id }) else { return }
            store.folders[idx].name = new
        }))
        UIApplication.shared.topMostController()?.present(alert, animated: true)
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
            Image(systemName: "play.rectangle.fill").resizable().scaledToFit().padding(18)
        case .audio:
            Image(systemName: "waveform").resizable().scaledToFit().padding(18)
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
}

// MARK: - Frame Card

struct FrameCard<Center: View>: View {
    let frameAsset: String
    @ViewBuilder var center: () -> Center
    var title: () -> String
    var subtitle: () -> String

    var body: some View {
        ZStack {
            Image(frameAsset).resizable().scaledToFit()
            VStack(spacing: 10) {
                Text(title()).font(.headline)
                let sub = subtitle()
                if !sub.isEmpty {
                    Text(sub).font(.subheadline).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center).lineLimit(4).minimumScaleFactor(0.85)
                        .padding(.horizontal, 16)
                }
                center().frame(maxWidth: 160, maxHeight: 120).clipped().cornerRadius(10)
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: 340)
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
}

// MARK: - Tag Editor & helpers

struct TagEditor: View {
    @Binding var tags: [String]
    @State private var newTag = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Add a tag", text: $newTag, onCommit: addTag)
                Button("Add", action: addTag)
            }
            Wrap(tags, spacing: 6) { tag in
                HStack(spacing: 6) {
                    Text(tag)
                    Image(systemName: "xmark.circle.fill")
                        .onTapGesture { tags.removeAll { $0 == tag } }
                }
                .font(.caption)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
            }
        }
    }
    private func addTag() {
        let t = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, !tags.contains(t) else { return }
        tags.append(t); newTag = ""
    }
}

struct Wrap<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let data: Data; let spacing: CGFloat; let content: (Data.Element) -> Content
    init(_ data: Data, spacing: CGFloat = 8, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data; self.spacing = spacing; self.content = content
    }
    var body: some View {
        var width: CGFloat = 0; var height: CGFloat = 0
        return GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ForEach(Array(data), id: \.self) { item in
                    content(item)
                        .padding(4)
                        .alignmentGuide(.leading) { d in
                            if (abs(width - d.width) > geo.size.width) { width = 0; height -= d.height + spacing }
                            let result = width
                            if item == data.last { width = 0 } else { width -= d.width + spacing }
                            return result
                        }
                        .alignmentGuide(.top) { _ in
                            let result = height
                            if item == data.last { height = 0 }
                            return result
                        }
                }
            }
        }
        .frame(height: max(32, CGFloat((Array(data).count / 4) + 1) * 32))
    }
}

extension Color {
    /// HEX helper with a unique name to avoid collisions.
    static func mz_hex(_ hex: String) -> Color {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        var v: UInt64 = 0; Scanner(string: s).scanHexInt64(&v)
        return Color(
            red: Double((v >> 16) & 0xFF) / 255.0,
            green: Double((v >> 8) & 0xFF) / 255.0,
            blue: Double(v & 0xFF) / 255.0
        )
    }
}

extension UIApplication {
    func topMostController(base: UIViewController? = nil) -> UIViewController? {
        let base = base ?? connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first?.rootViewController
        if let nav = base as? UINavigationController { return topMostController(base: nav.visibleViewController) }
        if let tab = base as? UITabBarController { return topMostController(base: tab.selectedViewController) }
        if let presented = base?.presentedViewController { return topMostController(base: presented) }
        return base
    }
}

#Preview { ContentView() }
