//
//  MusicService.swift
//  branchr
//
//  Created by Joe Dormond on 10/26/25.
//  Phase 18.4D - Hybrid Apple Music (Catalog + Library Fallback)
//

import Foundation
// import MusicKit  // Temporarily disabled for clean build
import SwiftUI

@MainActor
final class MusicService: ObservableObject {
    static let shared = MusicService()
    
    @Published var isAuthorized: Bool = false
    @Published var currentSongTitle: String = "No song playing"
    @Published var currentArtist: String = ""
    @Published var artworkURL: URL? = nil
    @Published var isPlaying: Bool = false
    
    // Temporarily disabled for clean build
    // private var player = ApplicationMusicPlayer.shared
    
    private init() {
        print("🎵 MusicService: Initialized (MusicKit temporarily disabled for clean build)")
    }
    
    // Check current authorization status
    func checkAuthorizationStatus() {
        // Temporarily disabled
        isAuthorized = false
        print("🎵 MusicService: MusicKit temporarily disabled for clean build")
    }
    
    // 🔐 Request permission to use Apple Music
    func requestAuthorization() async {
        // Temporarily disabled
        isAuthorized = false
        print("🎵 MusicService: MusicKit temporarily disabled - authorization skipped")
    }
    
    // 🎧 Hybrid playback: Try catalog first, fall back to library
    func playMusic() async {
        // Temporarily disabled for clean build
        print("🎵 MusicService: MusicKit temporarily disabled - playback unavailable")
        isPlaying = false
        currentSongTitle = "MusicKit disabled for clean build"
        currentArtist = ""
    }
    
    // Pause playback
    func pause() {
        // Temporarily disabled
        isPlaying = false
        print("⏸ MusicService: MusicKit disabled - pause unavailable")
    }
    
    // Resume playback
    func resume() async {
        // Temporarily disabled
        isPlaying = false
        print("▶️ MusicService: MusicKit disabled - resume unavailable")
    }
    
    // 🛑 Stop playback
    func stop() {
        // Temporarily disabled
        isPlaying = false
        currentSongTitle = "No song playing"
        currentArtist = ""
        artworkURL = nil
        print("⏹ MusicService: MusicKit disabled - stop unavailable")
    }
    
    // Skip to next track
    func skipToNext() async {
        // Temporarily disabled
        print("⏭ MusicService: MusicKit disabled - skip unavailable")
    }
    
    // Skip to previous track
    func skipToPrevious() async {
        // Temporarily disabled
        print("⏮ MusicService: MusicKit disabled - previous unavailable")
    }
    
    // Update now playing information
    private func updateNowPlaying() {
        // Temporarily disabled
        currentSongTitle = "MusicKit disabled"
        currentArtist = ""
    }
}
