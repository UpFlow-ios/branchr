//
//  MusicService.swift
//  branchr
//
//  Created by Joe Dormond on 10/26/25.
//  Phase 18.4D - Hybrid Apple Music (Catalog + Library Fallback)
//  Phase 61 - MusicKit Re-enabled with musicSourceMode support
//

import Foundation
import MusicKit  // Phase 61: Re-enabled
import MediaPlayer  // Phase 61: For MPNowPlayingInfoCenter
import SwiftUI

// Phase 63: Lightweight Now Playing metadata for UI
struct MusicServiceNowPlaying: Equatable {
    let title: String
    let artist: String
    let artwork: UIImage?
    
    static func == (lhs: MusicServiceNowPlaying, rhs: MusicServiceNowPlaying) -> Bool {
        lhs.title == rhs.title && lhs.artist == rhs.artist
    }
}

@MainActor
final class MusicService: ObservableObject {
    static let shared = MusicService()
    
    @Published var isAuthorized: Bool = false
    @Published var currentSongTitle: String = "No song playing"
    @Published var currentArtist: String = ""
    @Published var artworkURL: URL? = nil
    @Published var isPlaying: Bool = false
    
    // Phase 63: Published Now Playing info with artwork
    @Published private(set) var nowPlaying: MusicServiceNowPlaying?
    
    // Phase 76: Cached artwork that persists between track changes
    @Published private(set) var lastArtworkImage: UIImage?
    
    // Phase 61: Re-enabled MusicKit player (kept for future in-app playback)
    private var player = ApplicationMusicPlayer.shared
    
    // Phase 65: System music player for transport controls
    private let systemPlayer = MPMusicPlayerController.systemMusicPlayer
    
    private init() {
        print("🎵 Branchr MusicService: Initialized")
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    // MARK: - Phase 61: Music Source Mode Check
    
    /// Check if MusicKit should be used based on current music source mode
    private var shouldUseMusicKit: Bool {
        MusicSyncService.shared.musicSourceMode == .appleMusicSynced
    }
    
    // MARK: - Authorization
    
    // Check current authorization status
    func checkAuthorizationStatus() async {
        guard shouldUseMusicKit else {
            isAuthorized = false
            return
        }
        
        let status = MusicAuthorization.currentStatus
        isAuthorized = (status == .authorized)
        
        if isAuthorized {
            print("✅ Branchr MusicService: Apple Music access authorized")
        } else {
            print("⚠️ Branchr MusicService: Apple Music access status: \(status)")
        }
    }
    
    // 🔐 Request permission to use Apple Music
    func requestAuthorization() async {
        guard shouldUseMusicKit else {
            print("Branchr MusicService: Skipping authorization (ExternalPlayer mode)")
            isAuthorized = false
            return
        }
        
        do {
            let status = await MusicAuthorization.request()
            isAuthorized = (status == .authorized)
            
            if isAuthorized {
                print("✅ Branchr MusicService: Apple Music access granted")
                print("✅ Branchr MusicService: MusicKit entitlements verified and active.")
            } else {
                print("⚠️ Branchr MusicService: Apple Music access denied or restricted")
            }
        } catch {
            print("❌ Branchr MusicService: Authorization request failed: \(error.localizedDescription)")
            isAuthorized = false
        }
    }
    
    // MARK: - Playback Controls (Phase 61: Respect musicSourceMode)
    
    // 🎧 Hybrid playback: Try catalog first, fall back to library
    func playMusic() async {
        guard shouldUseMusicKit else {
            print("Branchr MusicService: Ignoring playMusic (ExternalPlayer mode)")
            return
        }
        
        if !isAuthorized {
            let status = MusicKitService.shared.authorizationStatus
            print("⚠️ Branchr MusicService: Cannot play - MusicKit not authorized (status: \(status)). Requesting authorization...")
            await requestAuthorization()
            guard isAuthorized else {
                let finalStatus = MusicKitService.shared.authorizationStatus
                print("❌ Branchr MusicService: Authorization denied, cannot play music (status: \(finalStatus))")
                return
            }
        }
        
        do {
            try await player.play()
            isPlaying = true
            await updateNowPlaying()
            print("▶️ Branchr MusicService: Playback started")
        } catch {
            print("❌ Branchr MusicService: Failed to start playback: \(error.localizedDescription)")
            isPlaying = false
        }
    }
    
    // Phase 65: Pause playback using system player
    func pause() {
        guard MusicSyncService.shared.musicSourceMode == .appleMusicSynced else {
            print("Branchr MusicService: Ignoring pause (ExternalPlayer mode)")
            return
        }
        
        systemPlayer.pause()
        isPlaying = false
        print("⏸ Branchr MusicService: Paused system Apple Music playback")
        refreshNowPlayingFromNowPlayingInfoCenter()
    }
    
    // Phase 65: Resume playback using system player
    func resume() async {
        guard MusicSyncService.shared.musicSourceMode == .appleMusicSynced else {
            print("Branchr MusicService: Ignoring resume (ExternalPlayer mode)")
            return
        }
        
        systemPlayer.play()
        isPlaying = true
        print("▶️ Branchr MusicService: Resumed system Apple Music playback")
        refreshNowPlayingFromNowPlayingInfoCenter()
    }
    
    // Phase 65: Toggle play/pause using system player
    func togglePlayPause() {
        guard MusicSyncService.shared.musicSourceMode == .appleMusicSynced else {
            print("Branchr MusicService: Ignoring togglePlayPause (ExternalPlayer mode)")
            return
        }
        
        switch systemPlayer.playbackState {
        case .playing:
            systemPlayer.pause()
            isPlaying = false
            print("Branchr MusicService: Paused system Apple Music playback")
        case .paused, .stopped, .interrupted:
            systemPlayer.play()
            isPlaying = true
            print("Branchr MusicService: Resumed system Apple Music playback")
        @unknown default:
            systemPlayer.play()
            isPlaying = true
            print("Branchr MusicService: Attempted to play system Apple Music from non-standard state: \(systemPlayer.playbackState.rawValue)")
        }
        
        // Refresh now playing after state change
        refreshNowPlayingFromNowPlayingInfoCenter()
    }
    
    // 🛑 Stop playback
    func stop() {
        guard shouldUseMusicKit else {
            print("Branchr MusicService: Ignoring stop (ExternalPlayer mode)")
            return
        }
        
        Task {
            await player.stop()
            isPlaying = false
            currentSongTitle = "No song playing"
            currentArtist = ""
            artworkURL = nil
            print("⏹ Branchr MusicService: Playback stopped")
        }
    }
    
    // Phase 65: Skip to next track using system player
    func skipToNext() async {
        guard MusicSyncService.shared.musicSourceMode == .appleMusicSynced else {
            print("Branchr MusicService: Ignoring skip next (ExternalPlayer mode)")
            return
        }
        
        systemPlayer.skipToNextItem()
        print("⏭ Branchr MusicService: Skipped to next track on system Apple Music")
        refreshNowPlayingFromNowPlayingInfoCenter()
    }
    
    // Phase 65: Skip to previous track using system player
    func skipToPrevious() async {
        guard MusicSyncService.shared.musicSourceMode == .appleMusicSynced else {
            print("Branchr MusicService: Ignoring skip previous (ExternalPlayer mode)")
            return
        }
        
        systemPlayer.skipToPreviousItem()
        print("⏮ Branchr MusicService: Skipped to previous track on system Apple Music")
        refreshNowPlayingFromNowPlayingInfoCenter()
    }
    
    // Phase 65: Alias methods for consistency (used by DJ Controls)
    func skipToNextTrack() {
        Task {
            await skipToNext()
        }
    }
    
    func skipToPreviousTrack() {
        Task {
            await skipToPrevious()
        }
    }
    
    // MARK: - Now Playing Info
    
    // Phase 65: Public method to refresh now playing from MPNowPlayingInfoCenter with systemPlayer fallback
    func refreshNowPlayingFromNowPlayingInfoCenter() {
        guard MusicSyncService.shared.musicSourceMode == .appleMusicSynced else {
            nowPlaying = nil
            return
        }
        
        // Phase 65: First try MPNowPlayingInfoCenter (existing code)
        let center = MPNowPlayingInfoCenter.default()
        if let info = center.nowPlayingInfo,
           let title = info[MPMediaItemPropertyTitle] as? String,
           let artist = info[MPMediaItemPropertyArtist] as? String {
            
            var artworkImage: UIImage? = nil
            if let artwork = info[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork {
                artworkImage = artwork.image(at: CGSize(width: 80, height: 80))
            }
            
            nowPlaying = MusicServiceNowPlaying(title: title, artist: artist, artwork: artworkImage)
            // Phase 76: Cache artwork so it persists between track changes
            if let artworkImage = artworkImage {
                lastArtworkImage = artworkImage
            }
            // Phase 66: Update isPlaying state when refreshing now playing
            isPlaying = (systemPlayer.playbackState == .playing)
            print("Branchr MusicService: NowPlaying updated from MPNowPlayingInfoCenter: \(title) – \(artist)")
            return
        }
        
        // Phase 65: Fallback to systemPlayer.nowPlayingItem if center is nil
        if let item = systemPlayer.nowPlayingItem {
            let title = item.title ?? "Unknown Title"
            let artist = item.artist ?? "Unknown Artist"
            
            var artworkImage: UIImage? = nil
            if let artwork = item.artwork {
                artworkImage = artwork.image(at: CGSize(width: 80, height: 80))
            }
            
            nowPlaying = MusicServiceNowPlaying(title: title, artist: artist, artwork: artworkImage)
            // Phase 76: Cache artwork so it persists between track changes
            if let artworkImage = artworkImage {
                lastArtworkImage = artworkImage
            }
            // Phase 66: Update isPlaying state when refreshing now playing
            isPlaying = (systemPlayer.playbackState == .playing)
            print("Branchr MusicService: NowPlaying updated from systemPlayer: \(title) – \(artist)")
            return
        }
        
        // Phase 65: Both center and systemPlayer give no data
        nowPlaying = nil
        // Phase 66: Update isPlaying state when no track
        isPlaying = false
        print("Branchr MusicService: NowPlaying: no active Apple Music track (center + systemPlayer both nil)")
    }
    
    // Update now playing information (internal, called by playback methods)
    private func updateNowPlaying() async {
        guard shouldUseMusicKit else {
            nowPlaying = nil
            return
        }
        
        // Phase 61: Use MPNowPlayingInfoCenter for reliable track info
        // This works with both MusicKit and other music apps
        let nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
        
        guard let info = nowPlayingInfo,
              let title = info[MPMediaItemPropertyTitle] as? String,
              let artist = info[MPMediaItemPropertyArtist] as? String else {
            currentSongTitle = "No song playing"
            currentArtist = ""
            artworkURL = nil
            isPlaying = false
            nowPlaying = nil
            return
        }
        
        currentSongTitle = title
        currentArtist = artist
        
        // Try to get artwork from now playing info
        var artworkImage: UIImage? = nil
        if let artwork = info[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork {
            artworkImage = artwork.image(at: CGSize(width: 80, height: 80))
            if artworkImage != nil {
                artworkURL = nil // MPNowPlayingInfoCenter doesn't provide URLs, just images
            } else {
                artworkURL = nil
            }
        } else {
            artworkURL = nil
        }
        
        // Phase 63: Update published nowPlaying property
        nowPlaying = MusicServiceNowPlaying(title: title, artist: artist, artwork: artworkImage)
        // Phase 76: Cache artwork so it persists between track changes
        if let artworkImage = artworkImage {
            lastArtworkImage = artworkImage
        }
        
        // Phase 65: Update playing state from system player
        isPlaying = (systemPlayer.playbackState == .playing)
    }
}
