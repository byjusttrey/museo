//
//  SplashView.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created by Kenya Ramirez on 12/2/25.
//

import SwiftUI

struct SplashView: View {
    @State private var opacity: Double = 0
    
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            MuseoColors.background
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                Text("museo")
                    .font(MuseoFont.header(48))
                    .foregroundColor(MuseoColors.textPrimary)
                    .opacity(opacity)
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.8)) {
                opacity = 1
            }
            
            // Auto-proceed to sign in after 1.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onComplete()
            }
        }
    }
}

#Preview {
    SplashView {
        print("Splash complete")
    }
}

