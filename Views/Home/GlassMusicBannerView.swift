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
        VStack(spacing: 10) {
            // Centered title + artist
            VStack(spacing: 3) {
                Text(title.isEmpty ? "No Song Playing" : title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(artist.isEmpty ? "Play music to see controls" : artist)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(1)
            }
            
            // Centered playback controls
            HStack(spacing: 24) {
                Button(action: onBack) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                
                Button(action: onPlayPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 42, height: 42)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.35), lineWidth: 1)
                        )
                        .shadow(color: .white.opacity(0.25), radius: 8, x: 0, y: 0)
                        .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                
                Button(action: onForward) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .frame(height: 126) // Reduced by 30% for compact layout
        .liquidGlass(cornerRadius: 24) // Premium Interactive Liquid Glass
    }
}

