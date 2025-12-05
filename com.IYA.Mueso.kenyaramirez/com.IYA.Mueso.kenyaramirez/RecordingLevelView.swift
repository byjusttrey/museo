//
//  RecordingLevelView.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created by Trey Jennings on 12/4/25.
//


//
//  RecordingLevelView.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created on 12/2/25.
//

import SwiftUI

struct RecordingLevelView: View {
    let level: Float // Average power in dB (typically -160 to 0)
    
    // Convert dB to normalized level (0.0 to 1.0)
    private var normalizedLevel: CGFloat {
        // Map from -160 dB (silence) to 0 dB (max) to 0.0 to 1.0
        let clamped = max(-160.0, min(0.0, level))
        return CGFloat((clamped + 160.0) / 160.0)
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<20, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor(for: index))
                    .frame(width: 3, height: barHeight(for: index))
            }
        }
        .frame(height: 40)
    }
    
    private func barHeight(for index: Int) -> CGFloat {
        // Each bar represents 5% of the level
        let barThreshold = CGFloat(index) / 20.0
        let minHeight: CGFloat = 4
        let maxHeight: CGFloat = 32
        
        if normalizedLevel >= barThreshold {
            // This bar should be active
            let barProgress = (normalizedLevel - barThreshold) * 20.0 // Scale to 0-1 for this bar
            return minHeight + (maxHeight - minHeight) * min(1.0, max(0.0, barProgress))
        } else {
            return minHeight
        }
    }
    
    private func barColor(for index: Int) -> Color {
        let barThreshold = CGFloat(index) / 20.0
        if normalizedLevel >= barThreshold {
            // Use accent color for active bars, with slight variation
            if normalizedLevel > 0.7 {
                return MuseoColors.accent
            } else {
                return MuseoColors.accent.opacity(0.7)
            }
        } else {
            return MuseoColors.borderMuted.opacity(0.3)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        RecordingLevelView(level: -160.0) // Silence
        RecordingLevelView(level: -60.0)  // Quiet
        RecordingLevelView(level: -30.0)  // Medium
        RecordingLevelView(level: -10.0)  // Loud
    }
    .padding()
    .background(MuseoColors.background)
}
