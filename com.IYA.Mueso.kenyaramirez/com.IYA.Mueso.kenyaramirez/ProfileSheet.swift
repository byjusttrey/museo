//
//  ProfileSheet.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created by Kenya Ramirez on 12/2/25.
//

import SwiftUI

struct ProfileSheet: View {
    @EnvironmentObject var store: MuseoStore
    @AppStorage("username") private var username: String = ""
    let onLogout: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                MuseoColors.background.ignoresSafeArea()
                
                Form {
                    Section("Profile") {
                        HStack {
                            Text("Username")
                                .font(MuseoFont.paragraph(14))
                                .foregroundColor(MuseoColors.textSecondary)
                            Spacer()
                            Text(username.isEmpty ? "Not set" : username)
                                .font(MuseoFont.bodyTitle(16))
                                .foregroundColor(MuseoColors.textPrimary)
                        }
                    }
                    
                    Section {
                        Button(role: .destructive) {
                            onLogout()
                            store.isShowingProfile = false
                        } label: {
                            HStack {
                                Spacer()
                                Text("Log out")
                                    .font(MuseoFont.bodyTitle(16))
                                    .foregroundColor(MuseoColors.accent)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        store.isShowingProfile = false
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileSheet(onLogout: {})
        .environmentObject(MuseoStore())
}

