//
//  ContentView.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created by Trey Jennings on 12/1/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = MuseoStore()
    @StateObject private var authManager = AuthManager()
    
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("username") private var storedUsername: String = ""
    @AppStorage("museoTheme") private var museoTheme: String = MuseoTheme.light.rawValue
    
    private var currentTheme: MuseoTheme {
        MuseoTheme(rawValue: museoTheme) ?? .light
    }
    
    var body: some View {
        ZStack {
            MuseoColors.background.ignoresSafeArea()
            
            if isLoggedIn && hasCompletedOnboarding {
                MainMuseoShellView(
                    username: storedUsername,
                    onLogout: handleLogout
                )
                .environmentObject(store)
            } else {
                OnboardingFlowView(
                    authManager: authManager,
                    initialUsername: storedUsername,
                    onFinished: handleOnboardingFinished
                )
            }
        }
        .preferredColorScheme(currentTheme == .dark ? .dark : .light)
    }
    
    private func handleOnboardingFinished(username: String) {
        storedUsername = username
        hasCompletedOnboarding = true
        isLoggedIn = true
    }
    
    private func handleLogout() {
        isLoggedIn = false
        hasCompletedOnboarding = false
        storedUsername = ""
        authManager.signOut()
    }
}

#Preview {
    ContentView()
}
