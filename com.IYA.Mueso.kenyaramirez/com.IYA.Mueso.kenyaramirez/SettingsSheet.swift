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
    @AppStorage("username") private var username: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                MuseoColors.background.ignoresSafeArea()
                
                Form {
                    Section("Profile") {
                        TextField("Username", text: $username)
                            .font(MuseoFont.paragraph(16))
                            .foregroundColor(MuseoColors.textPrimary)
                    }

                    Section("About") {
                        Text("Museo – personal mind museum prototype.")
                            .font(MuseoFont.paragraph(12))
                            .foregroundColor(MuseoColors.textSecondary)
                    }

                // MARK: - Gallery Settings
                Section("Gallery Settings") {
                    NavigationLink("Wallpaper") {
                        WallpaperSelectorView(
                            selected: Binding(
                                get: { store.galleryWallpaperName },
                                set: { store.setGalleryWallpaper(name: $0) }
                            )
                        )
                    }
                }
                }
            }
            .navigationTitle("Settings")
            .font(MuseoFont.header(20))
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
                                    .stroke(selected == wallpaper ? Color.blue : .clear,
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

