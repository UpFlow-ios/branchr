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
                RoundedRectangle(cornerRadius: 24, style: .continuous)  // Phase 34D: Match button corner radius
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                .red, .orange, .yellow, .green, .blue, .purple, .pink, .red
                            ]),
                            center: .center,
                            angle: .degrees(rotation)
                        ),
                        lineWidth: 5
                    )
                    .blur(radius: 2)
                    .opacity(0.9)
                    .shadow(color: .yellow.opacity(0.9), radius: 35, x: 0, y: 0)  // Phase 35.7: Enhanced glow
                    .shadow(color: .purple.opacity(0.6), radius: 70, x: 0, y: 0)
            )
            .onAppear {
                // Trigger haptic on first appearance
                if !hasTriggeredHaptic {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    hasTriggeredHaptic = true
                }
                
                // Start continuous rotation animation
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
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

