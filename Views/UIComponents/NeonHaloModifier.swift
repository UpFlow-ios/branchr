//
//  NeonHaloModifier.swift
//  branchr
//
//  Sharp, crisp rainbow halo with traveling light sweep - appears on press only
//

import SwiftUI

struct NeonHaloModifier: ViewModifier {
    @State private var isGlowing = false
    @State private var sweepProgress: CGFloat = 0.0
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if isGlowing {
                        ZStack {
                            // Base sharp rainbow border (high saturation, vivid colors)
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .strokeBorder(
                                    AngularGradient(
                                        gradient: Gradient(colors: [
                                            .red, .purple, .blue, .cyan, .green, .yellow, .orange, .red
                                        ]),
                                        center: .center
                                    ),
                                    lineWidth: 2.5
                                )
                                .blur(radius: 0.5) // Minimal blur for crispness
                            
                            // Traveling light sweep animation
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .trim(from: 0, to: 0.3)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            .white.opacity(0.9),
                                            .white.opacity(0.0)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    style: StrokeStyle(lineWidth: 3.0, lineCap: .round)
                                )
                                .rotationEffect(.degrees(Double(sweepProgress * 360)))
                                .blur(radius: 1)
                        }
                        .allowsHitTesting(false)
                    }
                }
            )
            .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
                if pressing {
                    // Start glow and animation
                    isGlowing = true
                    withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                        sweepProgress = 1.0
                    }
                } else {
                    // Stop immediately
                    withAnimation(.easeOut(duration: 0.1)) {
                        isGlowing = false
                        sweepProgress = 0.0
                    }
                }
            }) {}
    }
}

extension View {
    func neonHalo(cornerRadius: CGFloat = 20) -> some View {
        self.modifier(NeonHaloModifier(cornerRadius: cornerRadius))
    }
}

