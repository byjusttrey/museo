//
//  FoldersManagerView.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created by Trey Jennings on 11/12/25.
//


import SwiftUI
import UIKit

struct FoldersManagerView: View {
    @ObservedObject var store: AppStore
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            List {
                Section("Folders") {
                    ForEach(store.folders) { f in
                        HStack {
                            Text(f.emoji)
                            Text(f.name)
                            Spacer()
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
                    Button { addFolder() } label: {
                        Label("New Folder", systemImage: "folder.badge.plus")
                    }
                }
                Section { Button("Show All Items") { store.selectedFolder = nil } }
            }
            .navigationTitle("Projects & Folders")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { isPresented = false }
                }
            }
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
}
