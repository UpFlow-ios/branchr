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
        VStack(spacing: 16) {
            // Centered title + artist
            VStack(spacing: 4) {
                Text(title.isEmpty ? "No Song Playing" : title)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(artist.isEmpty ? "Play music to see controls" : artist)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(1)
            }
            
            // Centered playback controls
            HStack(spacing: 32) {
                Button(action: onBack) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                
                Button(action: onPlayPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 52, height: 52)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.35), lineWidth: 1)
                        )
                        .shadow(color: .white.opacity(0.2), radius: 8, x: 0, y: 0)
                        .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                
                Button(action: onForward) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .frame(height: 180) // Fixed height for stable layout
        .liquidGlass(cornerRadius: 28) // iOS 26 Interactive Liquid Glass
    }
}

