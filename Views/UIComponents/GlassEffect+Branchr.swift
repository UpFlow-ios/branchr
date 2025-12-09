//
//  GlassEffect+Branchr.swift
//  branchr
//
//  Created for Liquid Glass redesign - provides version-aware glass effects
//

import SwiftUI

extension View {
    /// Branchr wrapper for Apple's Liquid Glass effect with graceful fallback.
    @ViewBuilder
    func branchrGlass(
        in shape: some Shape,
        interactive: Bool = false
    ) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: shape)
                .interactive(interactive)
        } else {
            // Fallback: ultraThin blur + soft gradient + subtle stroke
            self.background {
                shape
                    .fill(.ultraThinMaterial)
                    .overlay(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.20),
                                .white.opacity(0.08),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        shape
                            .stroke(Color.white.opacity(0.22), lineWidth: 0.8)
                    )
                    .shadow(
                        color: Color.black.opacity(0.35),
                        radius: 18,
                        x: 0,
                        y: 12
                    )
            }
        }
    }

    /// Convenience for large rounded glass cards.
    @ViewBuilder
    func branchrGlassCard(cornerRadius: CGFloat = 24) -> some View {
        branchrGlass(in: RoundedRectangle(cornerRadius: cornerRadius,
                                          style: .continuous),
                     interactive: false)
    }

    /// Convenience for large pill-style glass buttons.
    @ViewBuilder
    func branchrGlassButton(cornerRadius: CGFloat = 24) -> some View {
        branchrGlass(in: RoundedRectangle(cornerRadius: cornerRadius,
                                          style: .continuous),
                     interactive: true)
    }

    /// Convenience for small capsule/pill badges (e.g. connection status).
    @ViewBuilder
    func branchrGlassPill() -> some View {
        branchrGlass(in: Capsule(), interactive: false)
    }
}
