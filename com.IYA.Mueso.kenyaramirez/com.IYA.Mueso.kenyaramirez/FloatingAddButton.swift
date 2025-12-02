//
//  FloatingAddButton.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created by Trey Jennings on 12/1/25.
//


// FloatingAddButton.swift

import SwiftUI

struct FloatingAddButton: View {
    @EnvironmentObject var store: MuseoStore

    var body: some View {
        Button {
            store.isShowingQuickCapture = true
        } label: {
            ZStack {
                Circle()
                    .fill(MuseoColors.accent)
                    .frame(width: 68, height: 68)
                    .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)

                Image(systemName: "plus")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}
