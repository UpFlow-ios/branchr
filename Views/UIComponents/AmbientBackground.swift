//
//  AmbientBackground.swift
//  branchr
//
//  Created for Phase 76 - Ambient Artwork Background
//

import SwiftUI

/**
 * 🎨 Ambient Background (with Dynamic Tint)
 *
 * Uses live Apple Music artwork and blurs it into a premium ambient backdrop.
 * Includes dynamic color tint that adapts to the artwork's dominant color.
 * Falls back to subtle gradient when no artwork is available.
 */
struct AmbientBackground: View {
    let artwork: UIImage?
    
    @ObservedObject private var artworkTint = ArtworkTint.shared
    
    var body: some View {
        Group {
            if let image = artwork {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 35)
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.4),
                                Color.black.opacity(0.75)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        artworkTint.dominantColor
                            .blur(radius: 80)
                    )
            } else {
                // Fallback gradient when no artwork
                LinearGradient(
                    colors: [
                        Color.black,
                        Color.black.opacity(0.85),
                        Color.black.opacity(0.9)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .ignoresSafeArea()
    }
}

