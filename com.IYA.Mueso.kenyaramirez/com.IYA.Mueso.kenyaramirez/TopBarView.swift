//
//  TopBarView.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created by Trey Jennings on 12/1/25.
//


// TopBarView.swift

import SwiftUI

struct TopBarView: View {
    @EnvironmentObject var store: MuseoStore

    var body: some View {
        HStack {
            // Logo placeholder
            Text("museo")
                .font(MuseoFont.header(24))
                .foregroundColor(MuseoColors.textPrimary)
                .kerning(1)
                .padding(.leading, 16)

            Spacer()

            // Gallery toggle
            Button {
                store.displayMode = .gallery
            } label: {
                Image(systemName: "square.grid.2x2")
                    .font(MuseoFont.bodyTitle(18))
                    .foregroundColor(store.displayMode == .gallery ? MuseoColors.textPrimary : MuseoColors.textSecondary)
                    .padding(8)
            }

            // Simple toggle
            Button {
                store.displayMode = .simple
            } label: {
                Image(systemName: "list.bullet")
                    .font(MuseoFont.bodyTitle(18))
                    .foregroundColor(store.displayMode == .simple ? MuseoColors.textPrimary : MuseoColors.textSecondary)
                    .padding(8)
            }

            // Profile icon
            Button {
                store.isShowingProfile = true
            } label: {
                Image(systemName: "person.crop.circle")
                    .font(MuseoFont.bodyTitle(20))
                    .foregroundColor(MuseoColors.textPrimary)
                    .padding(.trailing, 12)
            }

            // Settings cog
            Button {
                store.isShowingSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(MuseoFont.bodyTitle(18))
                    .foregroundColor(MuseoColors.textPrimary)
                    .padding(.trailing, 16)
            }
        }
        .padding(.vertical, 8)
        .background(MuseoColors.background)
    }
}
