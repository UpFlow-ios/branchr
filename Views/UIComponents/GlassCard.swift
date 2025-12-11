//
//  GlassCard.swift
//  branchr
//
//  Created for Phase 76 - Liquid Glass Component System
//

import SwiftUI

/**
 * 💎 Glass Card Component
 *
 * Shared container for frosted glass blocks throughout the app.
 * Uses native .ultraThinMaterial for future-proof Apple design compatibility.
 */
struct GlassCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.30), radius: 18, x: 0, y: 8)
    }
}

