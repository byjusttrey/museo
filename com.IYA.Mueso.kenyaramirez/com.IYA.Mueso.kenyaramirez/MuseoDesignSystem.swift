//
//  MuseoDesignSystem.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created by Kenya Ramirez on 12/2/25.
//

import SwiftUI
import UIKit

enum MuseoColors {
    static let background = Color("Background")
    static let textPrimary = Color("TextPrimary")
    static let accent = Color("Accent")
    static let accentSoft = Color("AccentSoft")
    static let borderMuted = Color("BorderMuted")
    static let textSecondary = Color("TextSecondary")
}

enum MuseoFont {
    static func header(_ size: CGFloat = 32) -> Font {
        .custom("Italiana-Regular", size: size)
    }

    static func bodyTitle(_ size: CGFloat = 18) -> Font {
        .custom("Roboto-Regular", size: size)
    }

    static func paragraph(_ size: CGFloat = 14) -> Font {
        .custom("Roboto-Light", size: size)
    }
}

// MARK: - Shared Color Palette

struct MuseoPalette {
    /// Solid colors available for folders and wallpaper backgrounds
    /// Uses the same colors as GalleryBackgroundColor for consistency
    static let folderColors: [Color] = [
        GalleryBackgroundColor.cream.color,
        GalleryBackgroundColor.blue.color,
        GalleryBackgroundColor.pink.color,
        GalleryBackgroundColor.purple.color,
        GalleryBackgroundColor.green.color,
        GalleryBackgroundColor.terracotta.color,
        GalleryBackgroundColor.yellow.color,
        GalleryBackgroundColor.brown.color,
        GalleryBackgroundColor.white.color,
        GalleryBackgroundColor.black.color
    ]
    
    /// Helper to get color name/key from a Color value
    static func colorKey(for color: Color) -> String? {
        for bgColor in GalleryBackgroundColor.allCases {
            if areColorsEqual(color, bgColor.color) {
                return bgColor.rawValue
            }
        }
        return nil
    }
    
    /// Helper to get Color from a color key/name
    static func color(for key: String) -> Color? {
        guard let bgColor = GalleryBackgroundColor(rawValue: key) else { return nil }
        return bgColor.color
    }
    
    /// Compare two colors for equality (with tolerance for floating point)
    static func areColorsEqual(_ color1: Color, _ color2: Color) -> Bool {
        let uiColor1 = UIColor(color1)
        let uiColor2 = UIColor(color2)
        
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        uiColor1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        uiColor2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        let tolerance: CGFloat = 0.01
        return abs(r1 - r2) < tolerance &&
               abs(g1 - g2) < tolerance &&
               abs(b1 - b2) < tolerance &&
               abs(a1 - a2) < tolerance
    }
}
