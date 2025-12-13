//
//  NeonHaloModifier.swift
//  branchr
//
//  Continuous traveling rainbow halo with vivid colors (like the image)
//

import SwiftUI

struct NeonHaloModifier: ViewModifier {
    @State private var sweepProgress: CGFloat = 0.0
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .overlay(
                // Continuous rainbow border with traveling light
                ZStack {
                    // Base vivid rainbow border (matches image: blue→purple→magenta→red→orange→yellow→green→blue)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    .blue, .purple, Color(red: 1.0, green: 0.0, blue: 1.0), // magenta
                                    .red, .orange, .yellow, .green, .blue
                                ]),
                                center: .center
                            ),
                            lineWidth: 2.0
                        )
                        .opacity(0.85) // Less glow, more subtle
                    
                    // Traveling light sweep (continuous animation)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .trim(from: 0, to: 0.25)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.6),
                                    .white.opacity(0.0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(Double(sweepProgress * 360)))
                        .opacity(0.7) // Less intense glow
                }
                .allowsHitTesting(false)
            )
            .onAppear {
                // Start continuous animation immediately
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    sweepProgress = 1.0
                }
            }
    }
}

extension View {
    func neonHalo(cornerRadius: CGFloat = 20) -> some View {
        self.modifier(NeonHaloModifier(cornerRadius: cornerRadius))
    }
}

