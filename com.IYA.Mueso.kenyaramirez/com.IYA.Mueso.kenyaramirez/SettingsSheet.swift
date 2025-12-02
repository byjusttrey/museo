//
//  SettingsSheet.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created by Trey Jennings on 12/1/25.
//


// SettingsSheet.swift

import SwiftUI

struct SettingsSheet: View {
    @EnvironmentObject var store: MuseoStore
    @AppStorage("museoTheme") private var museoTheme: String = MuseoTheme.light.rawValue
    @AppStorage("galleryBackgroundColorKey") private var galleryBackgroundColorKey: String = GalleryBackgroundColor.cream.rawValue

    var body: some View {
        NavigationStack {
            ZStack {
                MuseoColors.background.ignoresSafeArea()
                
                Form {
                    // MARK: - Gallery Appearance
                    Section("Gallery Appearance") {
                        // Theme picker
                        Picker("Theme", selection: $museoTheme) {
                            ForEach(MuseoTheme.allCases) { theme in
                                Text(theme.displayName)
                                    .font(MuseoFont.paragraph(14))
                                    .tag(theme.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        // Wallpaper selector
                        NavigationLink("Wallpaper") {
                            WallpaperSelectorView(
                                selected: Binding(
                                    get: { store.galleryWallpaperName },
                                    set: { store.setGalleryWallpaper(name: $0) }
                                )
                            )
                        }
                        
                        // Background color picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Background Color")
                                .font(MuseoFont.paragraph(14))
                                .foregroundColor(MuseoColors.textSecondary)
                            
                            GalleryColorPicker(selectedColorKey: $galleryBackgroundColorKey)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        store.isShowingSettings = false
                    }
                }
            }
        }
    }
}

struct WallpaperSelectorView: View {
    @Binding var selected: String?
    let wallpapers = ["wallpaper-1", "wallpaper-2", "wallpaper-3", "wallpaper-4"]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 16) {
                // “Default color” option
                Button {
                    selected = nil
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(MuseoColors.background)
                            .frame(height: 120)

                        Text("Default color")
                            .font(MuseoFont.paragraph(14))
                            .foregroundColor(MuseoColors.textPrimary)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(selected == nil ? MuseoColors.accent : .clear, lineWidth: 3)
                    )
                }

                ForEach(wallpapers, id: \.self) { wallpaper in
                    Button {
                        selected = wallpaper
                    } label: {
                        Image(wallpaper)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipped()
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selected == wallpaper ? MuseoColors.accent : .clear,
                                            lineWidth: 3)
                            )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Choose Wallpaper")
    }
}

