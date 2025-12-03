//
//  MuseoTheme.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created by Kenya Ramirez on 12/2/25.
//

import SwiftUI

enum MuseoTheme: String, CaseIterable, Identifiable {
    case light
    case dark
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .light: "Light"
        case .dark: "Dark"
        }
    }
}

