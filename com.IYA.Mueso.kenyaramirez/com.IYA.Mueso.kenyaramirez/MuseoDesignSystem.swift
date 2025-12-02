//
//  MuseoDesignSystem.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created by Kenya Ramirez on 12/2/25.
//

import SwiftUI

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
