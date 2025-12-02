//
//  GalleryEditSheet.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created by Trey Jennings on 12/1/25.
//


// GalleryEditSheet.swift

import SwiftUI

struct GalleryEditSheet: View {
    @EnvironmentObject var store: MuseoStore

    // For now just a simple color picker as wallpaper stand-in
    @State private var selectedColor: Color = Color(red: 0.99, green: 0.96, blue: 0.89)

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Gallery Wallpaper")
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                ColorPicker("Background color", selection: $selectedColor)
                    .padding(.horizontal, 16)

                Spacer()
            }
            .navigationTitle("Gallery Appearance")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        store.isShowingGalleryEdit = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // For now this doesn't persist; you can wire it into Folder.wallpaperID later.
                        store.isShowingGalleryEdit = false
                    }
                }
            }
        }
    }
}
