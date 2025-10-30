//
//  MusicService.swift
//  branchr
//
//  Created by Joe Dormond on 10/26/25.
//  Phase 18.4D - Hybrid Apple Music (Catalog + Library Fallback)
//

import Foundation
import MusicKit
import SwiftUI

@MainActor
final class MusicService: ObservableObject {
    static let shared = MusicService()
    
    @Published var isAuthorized: Bool = false
    @Published var currentSongTitle: String = "No song playing"
    @Published var currentArtist: String = ""
    @Published var artworkURL: URL? = nil
    @Published var isPlaying: Bool = false
    
    private var player = ApplicationMusicPlayer.shared
    
    private init() {
        print("🎵 MusicService: Initialized (Hybrid Mode)")
    }
    
    // Check current authorization status
    func checkAuthorizationStatus() {
        let status = MusicAuthorization.currentStatus
        isAuthorized = (status == .authorized)
        print("🎵 MusicService: Current authorization status: \(status)")
    }
    
    // 🔐 Request permission to use Apple Music
    func requestAuthorization() async {
        let status = await MusicAuthorization.request()
        isAuthorized = (status == .authorized)
        print("🎵 Apple Music status: \(status)")
        if isAuthorized {
            print("✅ MusicService: Apple Music access granted")
            print("✅ MusicKit entitlements verified and active.")
        } else {
            print("❌ Apple Music access denied")
        }
    }
    
    // 🎧 Hybrid playback: Try catalog first, fall back to library
    func playMusic() async {
        guard isAuthorized else {
            print("⚠️ Not authorized. Please connect Apple Music first.")
            return
        }
        
        // STEP 1: Try catalog search (requires MusicKit registration)
        do {
            print("🔍 Step 1: Attempting catalog search for Calvin Harris...")
            var request = MusicCatalogSearchRequest(term: "Calvin Harris", types: [Song.self])
            request.limit = 5
            let response = try await request.response()
            
            if let song = response.songs.first {
                print("✅ Found in catalog: \(song.title) by \(song.artistName)")
                
                player.queue = ApplicationMusicPlayer.Queue(for: [song])
                try await player.play()
                
                isPlaying = true
                currentSongTitle = song.title
                currentArtist = song.artistName
                artworkURL = song.artwork?.url(width: 300, height: 300)
                
                print("🎶 Now playing from CATALOG: \(song.title)")
                return // Success! Exit early
            }
        } catch {
            print("⚠️ Catalog search failed: \(error.localizedDescription)")
            if error.localizedDescription.contains("developer token") {
                print("💡 TIP: Register MusicKit identifier at developer.apple.com")
                print("📚 See: APPLE_MUSIC_DEVELOPER_TOKEN_SETUP.md for instructions")
            }
            print("🔄 Falling back to library playback...")
        }
        
        // STEP 2: Fallback to user's library (works without MusicKit registration)
        do {
            print("📚 Step 2: Loading songs from your Apple Music library...")
            let request = MusicLibraryRequest<Song>()
            let response = try await request.response()
            
            if let song = response.items.first {
                print("✅ Found in library: \(song.title) by \(song.artistName)")
                
                player.queue = ApplicationMusicPlayer.Queue(for: [song])
                try await player.play()
                
                isPlaying = true
                currentSongTitle = song.title
                currentArtist = song.artistName
                artworkURL = song.artwork?.url(width: 300, height: 300)
                
                print("🎶 Now playing from LIBRARY: \(song.title)")
            } else {
                print("❌ No songs in library")
                print("💡 TIP: Open Apple Music app and add some songs to your library")
            }
        } catch {
            print("❌ Library playback failed: \(error.localizedDescription)")
            print("💡 Make sure you're signed in to Apple Music")
        }
    }
    
    // Pause playback
    func pause() {
        player.pause()
        isPlaying = false
        print("⏸ MusicService: Playback paused")
    }
    
    // Resume playback
    func resume() async {
        do {
            try await player.play()
            isPlaying = true
            print("▶️ MusicService: Playback resumed")
        } catch {
            print("❌ MusicService: Resume failed: \(error.localizedDescription)")
        }
    }
    
    // 🛑 Stop playback
    func stop() {
        player.stop()
        isPlaying = false
        currentSongTitle = "No song playing"
        currentArtist = ""
        artworkURL = nil
        print("⏹ MusicService: Playback stopped")
    }
    
    // Skip to next track
    func skipToNext() async {
        do {
            try await player.skipToNextEntry()
            updateNowPlaying()
            print("⏭ MusicService: Skipped to next track")
        } catch {
            print("❌ MusicService: Skip failed: \(error.localizedDescription)")
        }
    }
    
    // Skip to previous track
    func skipToPrevious() async {
        do {
            try await player.skipToPreviousEntry()
            updateNowPlaying()
            print("⏮ MusicService: Skipped to previous track")
        } catch {
            print("❌ MusicService: Previous track failed: \(error.localizedDescription)")
        }
    }
    
    // Update now playing information
    private func updateNowPlaying() {
        Task {
            if let nowPlaying = player.queue.currentEntry {
                switch nowPlaying.item {
                case .song(let song):
                    currentSongTitle = song.title
                    currentArtist = song.artistName
                    artworkURL = song.artwork?.url(width: 300, height: 300)
                    print("🎵 Now Playing: \(currentSongTitle) by \(currentArtist)")
                default:
                    currentSongTitle = "Unknown Track"
                    currentArtist = "Unknown Artist"
                }
            }
        }
    }
}
