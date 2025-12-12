//
//  LayersModalView.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created by Trey Jennings on 12/11/25.
//

import SwiftUI

struct LayersModalView: View {
    @Binding var isPresented: Bool
    let onEdit: () -> Void
    let onBringToFront: () -> Void
    let onSendToBack: () -> Void
    
    var body: some View {
        ZStack {
            // Tap outside to dismiss
            Color.clear
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    isPresented = false
                }
            
            VStack {
                Spacer()
                
                VStack(spacing: 0) {
                    // Title
                    Text("Layers")
                        .font(MuseoFont.bodyTitle(24))
                        .foregroundColor(MuseoColors.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    
                    Rectangle()
                        .fill(MuseoColors.accent.opacity(0.3))
                        .frame(height: 1)
                    
                    // Edit
                    Button {
                        onEdit()
                        isPresented = false
                    } label: {
                        Text("Edit")
                            .font(MuseoFont.paragraph(16))
                            .foregroundColor(MuseoColors.accent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(LayersActionButtonStyle())
                    
                    Rectangle()
                        .fill(MuseoColors.accent.opacity(0.3))
                        .frame(height: 1)
                    
                    // Bring to front
                    Button {
                        onBringToFront()
                        isPresented = false
                    } label: {
                        Text("Bring to front")
                            .font(MuseoFont.paragraph(16))
                            .foregroundColor(MuseoColors.accent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(LayersActionButtonStyle())
                    
                    Rectangle()
                        .fill(MuseoColors.accent.opacity(0.3))
                        .frame(height: 1)
                    
                    // Send to back
                    Button {
                        onSendToBack()
                        isPresented = false
                    } label: {
                        Text("Send to back")
                            .font(MuseoFont.paragraph(16))
                            .foregroundColor(MuseoColors.accent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(LayersActionButtonStyle())
                }
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.3), radius: 24, y: -8)
                )
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isPresented)
        .zIndex(99_999)
    }
}

struct LayersActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed
                ? MuseoColors.accent.opacity(0.1)
                : Color.clear
            )
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        
        LayersModalView(
            isPresented: .constant(true),
            onEdit: { print("Edit") },
            onBringToFront: { print("Bring to front") },
            onSendToBack: { print("Send to back") }
        )
    }
}

