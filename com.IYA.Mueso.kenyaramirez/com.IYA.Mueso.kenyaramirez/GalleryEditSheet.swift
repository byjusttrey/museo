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
    @State private var selectedColor: Color = MuseoColors.background

    var body: some View {
        NavigationStack {
            ZStack {
                MuseoColors.background.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Gallery Wallpaper")
                        .font(MuseoFont.bodyTitle(18))
                        .foregroundColor(MuseoColors.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                ColorPicker("Background color", selection: $selectedColor)
                    .padding(.horizontal, 16)

                    Spacer()
                }
            }
            .navigationTitle("Gallery Appearance")
            .font(MuseoFont.header(20))
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
