//
//  NeonHaloModifier.swift
//  branchr
//
//  Vivid neon rainbow halo for premium buttons (like the mockup)
//

import SwiftUI

struct NeonHaloModifier: ViewModifier {
    let isEnabled: Bool
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if isEnabled {
                        // Vivid rainbow border like the mockup
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                AngularGradient(
                                    gradient: Gradient(colors: [
                                        .green, .cyan, .blue, .purple, .pink, .red, .orange, .yellow, .green
                                    ]),
                                    center: .center,
                                    startAngle: .degrees(0),
                                    endAngle: .degrees(360)
                                ),
                                lineWidth: 3.0
                            )
                            .blur(radius: 2)
                            .brightness(0.2)
                            // Multiple shadow layers for intense glow
                            .shadow(color: .green.opacity(0.6), radius: 12, x: 0, y: 0)
                            .shadow(color: .cyan.opacity(0.6), radius: 12, x: 0, y: 0)
                            .shadow(color: .orange.opacity(0.6), radius: 12, x: 0, y: 0)
                            .shadow(color: .pink.opacity(0.6), radius: 12, x: 0, y: 0)
                            .allowsHitTesting(false)
                    }
                }
            )
    }
}

extension View {
    func neonHalo(enabled: Bool, cornerRadius: CGFloat = 18) -> some View {
        self.modifier(NeonHaloModifier(isEnabled: enabled, cornerRadius: cornerRadius))
    }
}

