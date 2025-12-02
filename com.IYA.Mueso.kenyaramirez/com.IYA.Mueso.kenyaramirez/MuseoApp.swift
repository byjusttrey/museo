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
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            if authManager.shouldShowOnboarding {
                OnboardingFlowView(authManager: authManager) { username in
                    // Onboarding completed - authManager state is already updated
                    // The view will automatically switch to ContentView
                }
            } else {
                ContentView()
                    .environmentObject(store)
            }
        }
    }
}
