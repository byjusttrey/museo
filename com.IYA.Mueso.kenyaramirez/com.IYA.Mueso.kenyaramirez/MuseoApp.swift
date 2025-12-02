//
//  MuseoApp.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created by Trey Jennings on 12/1/25.
//


// MuseoApp.swift

import SwiftUI

@main
struct MuseoApp: App {
    @StateObject private var store = MuseoStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
