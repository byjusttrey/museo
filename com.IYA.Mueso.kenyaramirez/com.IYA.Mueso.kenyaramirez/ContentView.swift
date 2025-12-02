//
//  ContentView.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created by Trey Jennings on 12/1/25.
//


// ContentView.swift

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: MuseoStore

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                TopBarView()
                Divider().opacity(0.1)

                switch store.displayMode {
                case .gallery:
                    GalleryModeView()
                case .simple:
                    SimpleModeView()
                }
            }

            FloatingAddButton()
                .padding(.bottom, 24)
        }
        .sheet(isPresented: $store.isShowingQuickCapture) {
            QuickCaptureSheet()
        }
        .sheet(isPresented: $store.isShowingSettings) {
            SettingsSheet()
        }
        .sheet(isPresented: $store.isShowingGalleryEdit) {
            GalleryEditSheet()
        }
        // ContentView.swift (inside body where other .sheet modifiers are)
        .sheet(item: $store.activeFolderDetail) { folder in
            FolderDetailSheet(folder: folder)
        }
        .sheet(item: $store.editingArtifact) { artifact in
            ArtifactEditSheet(artifact: artifact)
        }
        .background(MuseoColors.background.ignoresSafeArea())
    }
}

#Preview {
    ContentView()
        .environmentObject(MuseoStore())
}
