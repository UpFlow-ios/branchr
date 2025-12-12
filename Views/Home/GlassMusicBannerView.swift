//
//  GlassMusicBannerView.swift
//  branchr
//
//  Created for Phase 76 - Option B1 Music Banner (No Artwork Inside)
//

import SwiftUI

/**
 * 🎵 Glass Music Banner View (Option B1)
 *
 * Wide glass banner with centered title, artist, and playback controls.
 * NO artwork inside the banner (artwork is blurred in background only).
 * Fixed height for stable layout.
 */
struct GlassMusicBannerView: View {
    let title: String
    let artist: String
    let isPlaying: Bool
    let onBack: () -> Void
    let onPlayPause: () -> Void
    let onForward: () -> Void
    
    var body: some View {
        // CENTERED MUSIC CONTROLS INSIDE ARTWORK - Floating white icons
        VStack {
            Spacer()
            HStack(spacing: 50) {
                Button(action: onBack) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
                        .contentShape(Rectangle())   // keeps tap area large
                        .frame(width: 70, height: 70) // invisible hit box
                }
                
                Button(action: onPlayPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 44, weight: .heavy))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.45), radius: 8, y: 4)
                        .contentShape(Rectangle())
                        .frame(width: 80, height: 80)
                }
                
                Button(action: onForward) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
                        .contentShape(Rectangle())
                        .frame(width: 70, height: 70)
                }
            }
            .padding(.bottom, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

