//
//  AmbientBackground.swift
//  branchr
//
//  Created for Phase 76 - Ambient Artwork Background
//

import SwiftUI

/**
 * 🎨 Ambient Background
 *
 * Uses live Apple Music artwork and blurs it into a premium ambient backdrop.
 * Falls back to subtle gradient when no artwork is available.
 */
struct AmbientBackground: View {
    let artwork: UIImage?
    
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

