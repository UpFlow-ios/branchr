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
    
    // Phase 62: Observe MusicKit authorization status
    @ObservedObject private var musicKitService = MusicKitService.shared
    
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            header
            
            // Phase 63: Improved Now Playing Card (only for Apple Music mode)
            if musicSourceMode == .appleMusicSynced {
                appleMusicNowPlayingCard
            } else {
                // External Player mode: Show helper message
                externalPlayerHelperMessage
            }
            
            // Playback Controls
            playbackControls
            
            // Source Hint
            sourceHint
            
            // Phase 62: Apple Music authorization status (only when Apple Music is selected)
            if musicSourceMode == .appleMusicSynced {
                appleMusicStatusView
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 24)
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            // Phase 62: Refresh authorization status when sheet appears
            Task {
                await musicKitService.refreshAuthorizationStatus(requestIfNeeded: false)
            }
            
            // Phase 63: Refresh now playing when sheet appears (only for Apple Music mode)
            if musicSourceMode == .appleMusicSynced {
                musicService.refreshNowPlayingFromNowPlayingInfoCenter()
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Text("DJ Controls")
                .font(.headline.bold())
                .foregroundColor(.white)
            
            Spacer()
            
            // Phase 60.3: Image-only full-size music badge pill (no text)
            Button {
                // Toggle between music source modes
                musicSourceMode = musicSourceMode == .appleMusicSynced ? .externalPlayer : .appleMusicSynced
                HapticsService.shared.lightTap()
                print("Branchr: DJ Controls music source changed to \(musicSourceMode.title)")
            } label: {
                brandedLogo(for: musicSourceMode)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .frame(minWidth: 96, minHeight: 32, maxHeight: 32)
                    .frame(maxWidth: .infinity)
                    .background(theme.brandYellow) // keep current yellow pill color
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Phase 60: Safe Branded Logo Helper (Full-Color Assets)
    
    /// Returns branded logo image if available, falls back to SF Symbol
    private func brandedLogo(for mode: MusicSourceMode) -> Image {
        if UIImage(named: mode.assetName) != nil {
            // Use original rendering for full-color badge assets
            return Image(mode.assetName)
                .renderingMode(.original)
        } else {
            // Failsafe – fall back to SF Symbol in template mode so it tints correctly
            return Image(systemName: mode.systemIconName)
                .renderingMode(.template)
        }
    }
    
    // MARK: - Phase 63: Apple Music Now Playing Card
    
    @ViewBuilder
    private var appleMusicNowPlayingCard: some View {
        if let nowPlaying = musicService.nowPlaying {
            HStack(spacing: 12) {
                // Artwork
                Group {
                    if let artwork = nowPlaying.artwork {
                        Image(uiImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Image(systemName: "music.note")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(width: 56, height: 56)
                .background(Color.black.opacity(0.45))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(nowPlaying.title)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundColor(.white)
                    
                    Text(nowPlaying.artist)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.black.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        } else {
            // No music playing state
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("No music playing")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                    
                    Text("Start a song in Apple Music or from the DJ Controls.")
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
    
    // MARK: - Phase 63: External Player Helper Message
    
    private var externalPlayerHelperMessage: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("No music playing")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                
                Text("Start music in your favorite app. Branchr will mix with voice chat.")
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
    
    // MARK: - Phase 63: Removed old artworkView and placeholderArtwork
    // Now using musicService.nowPlaying directly in appleMusicNowPlayingCard
    
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
    
    // MARK: - Phase 62: Apple Music Authorization Status
    
    @ViewBuilder
    private var appleMusicStatusView: some View {
        switch musicKitService.authorizationStatus {
        case .notDetermined:
            HStack(spacing: 12) {
                Text("Apple Music not set up yet")
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.7))
                
                Spacer()
                
                Button {
                    HapticsService.shared.lightTap()
                    Task {
                        await musicKitService.refreshAuthorizationStatus(requestIfNeeded: true)
                    }
                } label: {
                    Text("Enable")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(theme.brandYellow)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
        case .denied, .restricted:
            HStack {
                Text("Apple Music access is off. Enable in Settings > Music > Branchr.")
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.7))
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
        case .authorized:
            // Show nothing or a very subtle indicator
            EmptyView()
            
        @unknown default:
            EmptyView()
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentTrack: NowPlayingInfo? {
        // Prefer MusicSyncService's currentTrack (from MPNowPlayingInfoCenter)
        // Fall back to MusicService if needed
        if let syncTrack = musicSyncService.currentTrack {
            return syncTrack
        } else if musicService.currentSongTitle != "No song playing" {
            // Phase 61: Create NowPlayingInfo from MusicService data (MusicKit re-enabled)
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
    
    // MARK: - Actions (Phase 61: Respect musicSourceMode)
    
    private func handlePreviousTapped() {
        HapticsService.shared.lightTap()
        
        // Phase 61: Only control MusicKit when in Apple Music mode
        guard musicSourceMode == .appleMusicSynced else {
            print("Branchr MusicService: Ignoring transport controls (ExternalPlayer mode)")
            return
        }
        
        Task {
            await musicService.skipToPrevious()
        }
    }
    
    private func handlePlayPauseTapped() {
        HapticsService.shared.mediumTap()
        
        // Phase 61: Only control MusicKit when in Apple Music mode
        guard musicSourceMode == .appleMusicSynced else {
            print("Branchr MusicService: Ignoring transport controls (ExternalPlayer mode)")
            return
        }
        
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
        
        // Phase 61: Only control MusicKit when in Apple Music mode
        guard musicSourceMode == .appleMusicSynced else {
            print("Branchr MusicService: Ignoring transport controls (ExternalPlayer mode)")
            return
        }
        
        Task {
            await musicService.skipToNext()
        }
    }
}

