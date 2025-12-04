//
//  Folder.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created by Trey Jennings on 12/1/25.
//


// Folder.swift

import Foundation
import SwiftUI

enum FolderPriority: String, Codable, CaseIterable, Identifiable {
    case low = "!"
    case medium = "!!"
    case high = "!!!"
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .low: return "Low !"
        case .medium: return "Medium !!"
        case .high: return "High !!!"
        }
    }
    
    var displayName: String {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        }
    }
    
    var sortIndex: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        }
    }
}

struct Folder: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var color: ColorData
    var wallpaperID: String?   // identifier for wallpaper choice
    var priority: FolderPriority?

    init(id: UUID = UUID(),
         name: String,
         color: Color = .orange,
         wallpaperID: String? = nil,
         priority: FolderPriority? = nil) {
        self.id = id
        self.name = name
        self.color = ColorData(color: color)
        self.wallpaperID = wallpaperID
        self.priority = priority
    }
}

/// Codable-friendly representation of SwiftUI.Color
struct ColorData: Codable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double

    init(red: Double, green: Double, blue: Double, opacity: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }

    init(color: Color) {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.opacity = Double(a)
    }

    var swiftUIColor: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }
}
