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
    @AppStorage("galleryBackgroundColorKey") private var galleryBackgroundColorKey: String = GalleryBackgroundColor.cream.rawValue
    @AppStorage("quickCaptureButtonColorKey") private var quickCaptureButtonColorKey: String = "terracotta"
    @AppStorage("galleryBackgroundMode") private var galleryBackgroundModeRawValue: String = GalleryBackgroundMode.color.rawValue
    
    private var galleryBackgroundMode: GalleryBackgroundMode {
        get { GalleryBackgroundMode(rawValue: galleryBackgroundModeRawValue) ?? .color }
        set { galleryBackgroundModeRawValue = newValue.rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MuseoColors.background.ignoresSafeArea()
                
                Form {
                    // MARK: - Gallery Appearance
                    Section {
                        // Wallpaper selector
                        NavigationLink {
                            WallpaperSelectorView(
                                selected: Binding(
                                    get: { store.galleryWallpaperName },
                                    set: { store.setGalleryWallpaper(name: $0) }
                                ),
                                backgroundModeRawValue: $galleryBackgroundModeRawValue
                            )
                        } label: {
                            Text("Wallpaper")
                                .font(MuseoFont.bodyTitle(14))
                                .foregroundColor(MuseoColors.textPrimary)
                        }
                        
                        // Background color picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Background Color")
                                .font(MuseoFont.paragraph(14))
                                .foregroundColor(MuseoColors.textSecondary)
                            
                            GalleryColorPicker(
                                selectedColorKey: $galleryBackgroundColorKey,
                                backgroundModeRawValue: $galleryBackgroundModeRawValue
                            )
                        }
                        .padding(.vertical, 8)
                        
                        // Quick Capture Button Color picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Capture Button Color")
                                .font(MuseoFont.paragraph(14))
                                .foregroundColor(MuseoColors.textSecondary)
                            
                            QuickCaptureButtonColorPicker(selectedColorKey: $quickCaptureButtonColorKey)
                        }
                        .padding(.vertical, 8)
                    } header: {
                        Text("Gallery Appearance")
                            .font(MuseoFont.bodyTitle(16))
                            .foregroundColor(MuseoColors.textSecondary)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(MuseoColors.background)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(MuseoFont.header(32))
                        .foregroundColor(MuseoColors.textPrimary)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        store.isShowingSettings = false
                    }
                    .font(MuseoFont.bodyTitle(16))
                }
            }
        }
    }
}

struct WallpaperSelectorView: View {
    @Binding var selected: String?
    @Binding var backgroundModeRawValue: String
    let wallpapers = ["wallpaper-1", "wallpaper-2", "wallpaper-3", "wallpaper-4", "wallpaper-5", "wallpaper-6", "wallpaper-7"]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 16) {
                // “Default color” option
                Button {
                    selected = nil
                    backgroundModeRawValue = GalleryBackgroundMode.color.rawValue
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
                        backgroundModeRawValue = GalleryBackgroundMode.wallpaper.rawValue
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

// MARK: - Quick Capture Button Color Picker

struct QuickCaptureButtonColorPicker: View {
    @Binding var selectedColorKey: String
    
    private var selectedColor: GalleryBackgroundColor? {
        GalleryBackgroundColor(rawValue: selectedColorKey)
    }
    
    private var colorOptions: [GalleryBackgroundColor] {
        // Include all brand colors, prioritizing terracotta as default
        [.terracotta, .blue, .pink, .purple, .green, .brown, .yellow, .cream, .black, .white]
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(colorOptions) { colorOption in
                    Button {
                        selectedColorKey = colorOption.rawValue
                    } label: {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(colorOption.color)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            selectedColor == colorOption ? MuseoColors.accent : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                            
                            Text(colorOption.displayName)
                                .font(MuseoFont.paragraph(11))
                                .foregroundColor(MuseoColors.textSecondary)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
