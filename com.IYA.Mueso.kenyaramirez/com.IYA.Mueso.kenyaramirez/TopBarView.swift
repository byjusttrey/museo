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
                .font(.title2.weight(.semibold))
                .kerning(1)
                .padding(.leading, 16)

            Spacer()

            // Gallery toggle
            Button {
                store.displayMode = .gallery
            } label: {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(store.displayMode == .gallery ? Color.primary : .secondary)
                    .padding(8)
            }

            // Simple toggle
            Button {
                store.displayMode = .simple
            } label: {
                Image(systemName: "list.bullet")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(store.displayMode == .simple ? Color.primary : .secondary)
                    .padding(8)
            }

            // Profile / settings
            Button {
                store.isShowingSettings = true
            } label: {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 20))
                    .padding(.trailing, 12)
            }

            // Gallery edit cog (only meaningful in gallery mode)
            Button {
                if store.displayMode == .gallery {
                    store.isShowingGalleryEdit = true
                }
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18))
                    .foregroundStyle(store.displayMode == .gallery ? .primary : .secondary)
                    .padding(.trailing, 16)
            }
        }
        .padding(.vertical, 8)
        .background(Color(red: 0.99, green: 0.96, blue: 0.89))
    }
}
