//
//  AuthFooterText.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created by Kenya Ramirez on 12/2/25.
//

import SwiftUI

struct AuthFooterText: View {
    let prompt: String
    let actionText: String
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(prompt)
                .font(MuseoFont.paragraph(14))
                .foregroundColor(MuseoColors.textPrimary)
            
            Button(action: action) {
                Text(actionText)
                    .font(MuseoFont.paragraph(14))
                    .foregroundColor(MuseoColors.accent)
            }
        }
    }
}

#Preview {
    AuthFooterText(
        prompt: "Don't have an Account ?",
        actionText: "Sign up"
    ) {
        print("Sign up tapped")
    }
    .padding()
    .background(MuseoColors.background)
}

