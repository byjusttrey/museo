//
//  FloatingAddButton.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created by Trey Jennings on 12/1/25.
//

import SwiftUI

struct FloatingAddButton: View {
    @EnvironmentObject var store: MuseoStore
    
    @AppStorage("quickCaptureButtonColorKey") private var quickCaptureButtonColorKey: String = "terracotta"
    
    @State private var isQuickCaptureExpanded = false
    @State private var activeCaptureType: ArtifactType?
    
    private var quickCaptureButtonColor: Color {
        // Map the key to Color using GalleryBackgroundColor enum
        if let colorOption = GalleryBackgroundColor(rawValue: quickCaptureButtonColorKey) {
            return colorOption.color
        }
        // Default to terracotta if key doesn't match
        return Color(red: 206/255, green: 122/255, blue: 83/255) // #CE7A53
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if isQuickCaptureExpanded {
                HStack(spacing: 16) {
                    // IMAGE (green #AAC39C)
                    QuickCaptureOptionButton(
                        type: .image,
                        icon: "photo.on.rectangle",
                        color: Color(red: 170/255, green: 195/255, blue: 156/255), // #AAC39C
                        offset: .zero
                    ) {
                        quickCaptureOptionTapped(.image)
                    }
                    
                    // NOTE (purple #8F86B1)
                    QuickCaptureOptionButton(
                        type: .note,
                        icon: "pencil",
                        color: Color(red: 143/255, green: 134/255, blue: 177/255), // #8F86B1
                        offset: .zero
                    ) {
                        quickCaptureOptionTapped(.note)
                    }
                    
                    // AUDIO (pink #CC8683)
                    QuickCaptureOptionButton(
                        type: .audio,
                        icon: "mic",
                        color: Color(red: 204/255, green: 134/255, blue: 131/255), // #CC8683
                        offset: .zero
                    ) {
                        quickCaptureOptionTapped(.audio)
                    }
                    
                    // VIDEO (blue #77ACB7)
                    QuickCaptureOptionButton(
                        type: .video,
                        icon: "video",
                        color: Color(red: 119/255, green: 172/255, blue: 183/255), // #77ACB7
                        offset: .zero
                    ) {
                        quickCaptureOptionTapped(.video)
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            // Main + button (uses selected color from settings)
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    isQuickCaptureExpanded.toggle()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(quickCaptureButtonColor)
                        .frame(width: 68, height: 68)
                        .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)
                    
                    Image(systemName: isQuickCaptureExpanded ? "xmark" : "plus")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .sheet(item: $activeCaptureType) { type in
            QuickCaptureSheet(initialType: type)
                .interactiveDismissDisabled(true)
        }
    }
    
    private func quickCaptureOptionTapped(_ type: ArtifactType) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isQuickCaptureExpanded = false
        }
        
        // Small delay to allow collapse animation before showing sheet
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            activeCaptureType = type
        }
    }
}

// MARK: - Quick Capture Option Button

struct QuickCaptureOptionButton: View {
    let type: ArtifactType
    let icon: String
    let color: Color
    let offset: CGSize
    let action: () -> Void
    
    @State private var isVisible = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 56, height: 56)
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        .offset(offset)
        .scaleEffect(isVisible ? 1.0 : 0.6)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
        .transition(.scale.combined(with: .opacity))
    }
}
