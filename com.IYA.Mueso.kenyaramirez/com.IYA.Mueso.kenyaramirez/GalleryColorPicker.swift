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
    case beige
    case warmGray
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .cream: "Cream"
        case .white: "White"
        case .beige: "Beige"
        case .warmGray: "Warm Gray"
        }
    }
    
    var color: Color {
        switch self {
        case .cream:
            return MuseoColors.background // #FDF2D5
        case .white:
            return Color.white
        case .beige:
            return Color(red: 0.96, green: 0.93, blue: 0.88)
        case .warmGray:
            return Color(red: 0.93, green: 0.90, blue: 0.84)
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

