//
//  DJControlsSheetView.swift
//  branchr
//
//  Created for Phase 55 - DJ Controls Sheet 1.0
//

import SwiftUI
import MediaPlayer

/**
 * 🎧 DJ Controls Sheet
 *
 * Real music control center for Apple Music / Other Music App
 * Shows current track, playback controls, and music source info
 */
struct DJControlsSheetView: View {
    @ObservedObject var musicService: MusicService
    @ObservedObject var musicSyncService: MusicSyncService
    @Binding var musicSourceMode: MusicSourceMode
    
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            header
            
            // Now Playing Card
            nowPlayingCard
            
            // Playback Controls
            playbackControls
            
            // Source Hint
            sourceHint
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 24)
        .background(Color.black.ignoresSafeArea())
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Text("DJ Controls")
                .font(.headline.bold())
                .foregroundColor(.white)
            
            Spacer()
            
            // Music source pill (Phase 58: with branded icon and non-truncated text)
            HStack(spacing: 8) {
                Image(musicSourceMode.assetName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                Text(musicSourceMode.shortTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .layoutPriority(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.yellow.opacity(0.15))
            .foregroundColor(.yellow)
            .clipShape(Capsule())
        }
    }
    
    // MARK: - Now Playing Card
    
    private var nowPlayingCard: some View {
        Group {
            if let track = currentTrack {
                HStack(spacing: 16) {
                    artworkView(for: track)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(track.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(track.artist)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                        
                        Text("Now playing")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                    
                    Spacer()
                }
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No music playing")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                        
                        Text(musicSourceMode == .appleMusicSynced
                             ? "Start a song in Apple Music or from the DJ Controls."
                             : "Start music in your favorite app. Branchr will mix with voice chat.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                }
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }
    
    // MARK: - Artwork View
    
    @ViewBuilder
    private func artworkView(for track: NowPlayingInfo) -> some View {
        // Try to get artwork from MPNowPlayingInfoCenter
        let nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
        if let artwork = nowPlayingInfo?[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork {
            if let image = artwork.image(at: CGSize(width: 56, height: 56)) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                placeholderArtwork
            }
        } else {
            placeholderArtwork
        }
    }
    
    private var placeholderArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.yellow.opacity(0.2))
            Image(systemName: "music.note")
                .foregroundColor(.yellow)
        }
        .frame(width: 56, height: 56)
    }
    
    // MARK: - Playback Controls
    
    private var playbackControls: some View {
        HStack(spacing: 32) {
            Button {
                handlePreviousTapped()
            } label: {
                Image(systemName: "backward.fill")
            }
            
            Button {
                handlePlayPauseTapped()
            } label: {
                Image(systemName: isCurrentlyPlaying ? "pause.fill" : "play.fill")
                    .font(.title2.weight(.bold))
            }
            
            Button {
                handleNextTapped()
            } label: {
                Image(systemName: "forward.fill")
            }
        }
        .font(.title3)
        .foregroundColor(.yellow)
    }
    
    // MARK: - Source Hint
    
    private var sourceHint: some View {
        Text(hintText)
            .font(.caption)
            .foregroundColor(.gray)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
    }
    
    private var hintText: String {
        switch musicSourceMode {
        case .appleMusicSynced:
            return "Your Apple Music stays in sync with your ride. Use DJ Controls to adjust playback while Branchr keeps voice chat clear."
        case .externalPlayer:
            return "Music is playing from another app. Branchr mixes your voice over the top, but playback controls may be limited."
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentTrack: NowPlayingInfo? {
        // Prefer MusicSyncService's currentTrack (from MPNowPlayingInfoCenter)
        // Fall back to MusicService if needed
        if let syncTrack = musicSyncService.currentTrack {
            return syncTrack
        } else if musicService.currentSongTitle != "No song playing" && 
                  musicService.currentSongTitle != "MusicKit disabled for clean build" &&
                  musicService.currentSongTitle != "MusicKit disabled" {
            // Create NowPlayingInfo from MusicService data
            return NowPlayingInfo(
                title: musicService.currentSongTitle,
                artist: musicService.currentArtist,
                album: nil,
                sourceApp: .appleMusic,
                playbackPosition: nil,
                isPlaying: musicService.isPlaying,
                trackDuration: nil
            )
        }
        return nil
    }
    
    private var isCurrentlyPlaying: Bool {
        if let track = currentTrack {
            return track.isPlaying
        }
        return musicService.isPlaying
    }
    
    // MARK: - Actions
    
    private func handlePreviousTapped() {
        HapticsService.shared.lightTap()
        Task {
            await musicService.skipToPrevious()
        }
    }
    
    private func handlePlayPauseTapped() {
        HapticsService.shared.mediumTap()
        if isCurrentlyPlaying {
            musicService.pause()
        } else {
            Task {
                await musicService.resume()
            }
        }
    }
    
    private func handleNextTapped() {
        HapticsService.shared.lightTap()
        Task {
            await musicService.skipToNext()
        }
    }
}

