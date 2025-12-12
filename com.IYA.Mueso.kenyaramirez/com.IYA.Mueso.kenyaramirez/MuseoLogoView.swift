//
//  MuseoLogoView.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created by Kenya Ramirez on 12/2/25.
//

import SwiftUI

struct MuseoLogoView: View {
    var body: some View {
        VStack(spacing: 12) {
            // Logo mark - starburst icon
            // TODO: Replace with actual logo asset name when available
            Image("museo-logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 125, height: 125)
        }
    }
}

#Preview {
    MuseoLogoView()
        .padding()
        .background(MuseoColors.background)
}

