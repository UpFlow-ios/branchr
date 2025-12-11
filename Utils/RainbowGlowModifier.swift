//
//  RainbowGlowModifier.swift
//  branchr
//
//  Created by Joseph Dormond on 2025-11-05
//  Phase 33 - Rainbow Glow Animation Modifier
//  Phase 33B - Improved continuous rotating animation
//  Fix: Enhanced visible rainbow glow with haptic feedback
//

import SwiftUI

/**
 * 🌈 Rainbow Glow Modifier
 *
 * Adds an animated rainbow glow effect to views.
 * Used for the "Start Connection" button when connected.
 * Fix: Enhanced with more visible glow, shadow, and haptic feedback.
 */
struct RainbowGlowModifier: ViewModifier {
    @State private var rotation: Double = 0
    @State private var hasTriggeredHaptic = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                .red, .orange, .yellow, .green, .blue, .purple, .pink, .red
                            ]),
                            center: .center,
                            angle: .degrees(rotation)
                        ),
                        lineWidth: 4
                    )
                    .blur(radius: 3)
                    .opacity(0.95)
                    .shadow(color: .yellow.opacity(0.9), radius: 40, x: 0, y: 0)
                    .shadow(color: .purple.opacity(0.7), radius: 75, x: 0, y: 0)
                    .shadow(color: .blue.opacity(0.6), radius: 50, x: 0, y: 0)
            )
            .onAppear {
                // Trigger haptic on first appearance
                if !hasTriggeredHaptic {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    hasTriggeredHaptic = true
                }
                
                // Start continuous rotation animation
                withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

extension View {
    /// Apply rainbow glow effect when active
    @ViewBuilder
    func rainbowGlow(active: Bool) -> some View {
        if active {
            self.modifier(RainbowGlowModifier())
        } else {
            self
        }
    }
}

