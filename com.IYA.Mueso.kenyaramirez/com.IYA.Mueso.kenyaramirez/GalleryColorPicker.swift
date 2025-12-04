//
//  GalleryColorPicker.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created by Kenya Ramirez on 12/2/25.
//

import SwiftUI

enum GalleryBackgroundColor: String, CaseIterable, Identifiable {
    case cream
    case white
    case black
    case brown
    case blue
    case terracotta
    case yellow
    case pink
    case purple
    case green
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .cream: "Cream"
        case .white: "White"
        case .black: "Black"
        case .brown: "Brown"
        case .blue: "Blue"
        case .terracotta: "Terracotta"
        case .yellow: "Yellow"
        case .pink: "Pink"
        case .purple: "Purple"
        case .green: "Green"
        }
    }
    
    var color: Color {
        switch self {
        case .cream:
            return Color(red: 253/255, green: 242/255, blue: 213/255) // #FDF2D5
        case .white:
            return Color(red: 255/255, green: 255/255, blue: 255/255) // #FFFFFF
        case .black:
            return Color(red: 0/255, green: 0/255, blue: 0/255) // #000000
        case .brown:
            return Color(red: 105/255, green: 68/255, blue: 50/255) // #694432
        case .blue:
            return Color(red: 119/255, green: 172/255, blue: 183/255) // #77ACB7
        case .terracotta:
            return Color(red: 206/255, green: 122/255, blue: 83/255) // #CE7A53
        case .yellow:
            return Color(red: 246/255, green: 208/255, blue: 96/255) // #F6D060
        case .pink:
            return Color(red: 204/255, green: 134/255, blue: 131/255) // #CC8683
        case .purple:
            return Color(red: 143/255, green: 134/255, blue: 177/255) // #8F86B1
        case .green:
            return Color(red: 170/255, green: 195/255, blue: 156/255) // #AAC39C
        }
    }
}

struct GalleryColorPicker: View {
    @Binding var selectedColorKey: String
    
    private var selectedColor: GalleryBackgroundColor {
        GalleryBackgroundColor(rawValue: selectedColorKey) ?? .cream
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(GalleryBackgroundColor.allCases) { colorOption in
                    Button {
                        selectedColorKey = colorOption.rawValue
                    } label: {
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(colorOption.color)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            selectedColor == colorOption ? MuseoColors.accent : Color.clear,
                                            lineWidth: 3
                                        )
                                )
                            
                            Text(colorOption.displayName)
                                .font(MuseoFont.paragraph(12))
                                .foregroundColor(MuseoColors.textPrimary)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    GalleryColorPicker(selectedColorKey: .constant("cream"))
        .padding()
        .background(MuseoColors.background)
}

