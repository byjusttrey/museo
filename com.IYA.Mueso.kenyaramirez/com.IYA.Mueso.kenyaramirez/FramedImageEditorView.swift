//
//  FramedImageEditorView.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created by Trey Jennings on 12/4/25.
//


//
//  FramedImageEditorView.swift
//  com.IYA.Mueso.kenyaramirez
//
//  Created on 12/2/25.
//

import SwiftUI

struct FramedImageEditorView: View {
    let frameImageName: String
    let frameAspectRatio: CGFloat
    let backgroundColor: Color
    @Binding var uiImage: UIImage?
    @Binding var transform: ImageTransformState
    
    var body: some View {
        VStack(spacing: 12) {
            // Frame editor
            GeometryReader { geometry in
                let frameWidth = min(geometry.size.width, geometry.size.height * frameAspectRatio)
                let frameHeight = frameWidth / frameAspectRatio
                
                ZStack {
                    // Background
                    backgroundColor
                    
                    // Transformed image with gestures
                    if let uiImage = uiImage {
                        let totalScale = max(0.5, min(4.0, transform.scale * gestureScale))
                        let totalOffset = CGSize(
                            width: transform.offset.width + gestureOffset.width,
                            height: transform.offset.height + gestureOffset.height
                        )
                        let totalRotation = transform.rotation + gestureRotation
                        
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .scaleEffect(totalScale)
                            .rotationEffect(totalRotation)
                            .offset(totalOffset)
                            .frame(width: frameWidth, height: frameHeight)
                            .clipped()
                            .gesture(combinedGesture)
                    }
                    
                    // Frame overlay (always on top)
                    Image(frameImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: frameWidth, height: frameHeight)
                }
                .frame(width: frameWidth, height: frameHeight)
                .clipped() // Rectangular clip, NO rounded corners
            }
            .aspectRatio(frameAspectRatio, contentMode: .fit)
            
            // Control buttons
            HStack(spacing: 16) {
                // Reset button
                Button {
                    transform = ImageTransformState()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset")
                            .font(MuseoFont.bodyTitle(14))
                    }
                    .foregroundColor(MuseoColors.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(MuseoColors.borderMuted, lineWidth: 1)
                            )
                    )
                }
                
                // Rotate 90° button
                Button {
                    transform.rotation += .degrees(90)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "rotate.right")
                        Text("Rotate 90°")
                            .font(MuseoFont.bodyTitle(14))
                    }
                    .foregroundColor(MuseoColors.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(MuseoColors.borderMuted, lineWidth: 1)
                            )
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Gesture State
    
    @GestureState private var gestureScale: CGFloat = 1.0
    @GestureState private var gestureOffset: CGSize = .zero
    @GestureState private var gestureRotation: Angle = .zero
    
    // MARK: - Gestures
    
    private var magnification: some Gesture {
        MagnificationGesture()
            .updating($gestureScale) { value, state, _ in
                state = value
            }
            .onEnded { value in
                transform.scale = max(0.5, min(4.0, transform.scale * value))
            }
    }
    
    private var drag: some Gesture {
        DragGesture()
            .updating($gestureOffset) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                transform.offset.width += value.translation.width
                transform.offset.height += value.translation.height
            }
    }
    
    private var rotation: some Gesture {
        RotationGesture()
            .updating($gestureRotation) { value, state, _ in
                state = value
            }
            .onEnded { value in
                transform.rotation += value
            }
    }
    
    private var combinedGesture: some Gesture {
        magnification
            .simultaneously(with: drag)
            .simultaneously(with: rotation)
    }
}