//
//  GlassMusicBannerView.swift
//  branchr
//
//  Apple Music-style floating controls with perfect artwork masking
//

import SwiftUI

struct GlassMusicBannerView: View {
    let title: String
    let artist: String
    let isPlaying: Bool
    let onBack: () -> Void
    let onPlayPause: () -> Void
    let onForward: () -> Void
    
    var body: some View {
        // Centered floating music controls - Apple Music style
        HStack(spacing: 40) {
            Button(action: onBack) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 70, height: 70)
                    .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
            }
            
            Spacer()
            
            Button(action: onPlayPause) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 80, height: 80)
                    .shadow(color: .black.opacity(0.45), radius: 8, y: 4)
            }
            
            Spacer()
            
            Button(action: onForward) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 70, height: 70)
                    .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
            }
        }
        .padding(.horizontal, 40)
    }
}
