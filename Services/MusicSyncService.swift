//
//  MusicSyncService.swift
//  branchr
//
//  Created by Joe Dormond on 10/24/25.
//

import Foundation
import MediaPlayer
import Combine
import MultipeerConnectivity

/// Data model for current playing track information
struct NowPlayingInfo: Codable {
    var title: String
    var artist: String
    var album: String?
    var sourceApp: MusicSource
    var playbackPosition: TimeInterval?
    var isPlaying: Bool
    var trackDuration: TimeInterval?
    
    init(title: String, artist: String, album: String? = nil, sourceApp: MusicSource, playbackPosition: TimeInterval? = nil, isPlaying: Bool, trackDuration: TimeInterval? = nil) {
        self.title = title
        self.artist = artist
        self.album = album
        self.sourceApp = sourceApp
        self.playbackPosition = playbackPosition
        self.isPlaying = isPlaying
        self.trackDuration = trackDuration
    }
}

/// Music source apps that Branchr can detect and integrate with
enum MusicSource: String, Codable, CaseIterable {
    case appleMusic = "apple_music"
    case pandora = "pandora"
    case youtubeMusic = "youtube_music"
    case spotify = "spotify"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .appleMusic: return "Apple Music"
        case .pandora: return "Pandora"
        case .youtubeMusic: return "YouTube Music"
        case .spotify: return "Spotify"
        case .unknown: return "Unknown"
        }
    }
    
    var icon: String {
        switch self {
        case .appleMusic: return "music.note"
        case .pandora: return "p.circle.fill"
        case .youtubeMusic: return "play.rectangle.fill"
        case .spotify: return "s.circle.fill"
        case .unknown: return "questionmark.circle"
        }
    }
}

/// Service for syncing music playback information across connected riders
/// Uses MPNowPlayingInfoCenter to read host's current track and broadcasts via MultipeerConnectivity
final class MusicSyncService: NSObject, ObservableObject {
    @Published var currentTrack: NowPlayingInfo?
    @Published var isHostDJ: Bool = false
    @Published var isPolling: Bool = false
    @Published var isMusicMuted: Bool = false // Phase 20: Per-user music mute
    
    private var pollingTimer: Timer?
    private var groupSessionManager: GroupSessionManager?
    private let pollingInterval: TimeInterval = 1.0
    
    override init() {
        super.init()
        print("Branchr: MusicSyncService initialized")
    }
    
    /// Set the group session manager for broadcasting
    func setGroupSessionManager(_ manager: GroupSessionManager) {
        self.groupSessionManager = manager
    }
    
    /// Become the host DJ
    func becomeHostDJ() {
        isHostDJ = true
        startPolling()
        print("Branchr: User became Host DJ")
    }
    
    /// Resign as host DJ
    func resignHostDJ() {
        isHostDJ = false
        stopPolling()
        currentTrack = nil
        print("Branchr: User resigned as Host DJ")
    }
    
    // MARK: - Phase 20: Music Mute Controls
    
    /// Toggle music mute state
    func toggleMusicMute() {
        isMusicMuted.toggle()
        // TODO: Adjust local playback volume when muted
        // When muted, playback continues silently (maintaining sync timestamps)
        print("Branchr: Music \(isMusicMuted ? "muted" : "unmuted")")
    }
    
    /// Mute all music (host control)
    @MainActor
    func muteAllMusic() {
        isMusicMuted = true
        // Broadcast mute all command to group
        Task { @MainActor in
            groupSessionManager?.broadcastMusicMuteAll()
        }
        print("Branchr: Host muted all music")
    }
    
    /// Start polling MPNowPlayingInfoCenter for updates
    private func startPolling() {
        guard isHostDJ else { return }
        
        stopPolling() // Stop any existing timer
        
        isPolling = true
        pollingTimer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.updateNowPlayingFromSystem()
            }
        }
        
        // Initial update
        Task {
            await updateNowPlayingFromSystem()
        }
    }
    
    /// Stop polling for updates
    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        isPolling = false
    }
    
    /// Update current track from system's now playing info
    func updateNowPlayingFromSystem() async {
        guard isHostDJ else { return }
        
        let nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
        
        print("Branchr: MPNowPlayingInfoCenter info: \(nowPlayingInfo ?? [:])")
        
        guard let info = nowPlayingInfo,
              let title = info[MPMediaItemPropertyTitle] as? String,
              let artist = info[MPMediaItemPropertyArtist] as? String else {
            // No music playing or insufficient info
            print("Branchr: No music detected or insufficient info")
            if currentTrack != nil {
                currentTrack = nil
                await broadcastNowPlaying()
            }
            return
        }
        
        print("Branchr: Detected music - Title: \(title), Artist: \(artist)")
        
        let album = info[MPMediaItemPropertyAlbumTitle] as? String
        let playbackPosition = info[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? TimeInterval
        let trackDuration = info[MPMediaItemPropertyPlaybackDuration] as? TimeInterval
        let playbackRate = info[MPNowPlayingInfoPropertyPlaybackRate] as? Double ?? 0.0
        let isPlaying = playbackRate > 0
        
        // Detect source app
        let sourceApp = detectSourceApp()
        
        let newTrack = NowPlayingInfo(
            title: title,
            artist: artist,
            album: album,
            sourceApp: sourceApp,
            playbackPosition: playbackPosition,
            isPlaying: isPlaying,
            trackDuration: trackDuration
        )
        
        // Only broadcast if track info has changed
        if currentTrack?.title != newTrack.title || 
           currentTrack?.artist != newTrack.artist ||
           currentTrack?.isPlaying != newTrack.isPlaying {
            
            currentTrack = newTrack
            print("Branchr: Broadcasting new track: \(newTrack.title) by \(newTrack.artist)")
            await broadcastNowPlaying()
        }
    }
    
    /// Detect which music app is currently playing
    private func detectSourceApp() -> MusicSource {
        // Try to detect the source app using various methods
        
        // Method 1: Check if we can detect from the now playing info
        let nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
        
        // Method 2: Check running applications (if possible)
        // Note: This is limited on iOS, but we can try to infer from the app state
        
        // Method 3: Use heuristics based on the track information
        if let info = nowPlayingInfo {
            // Check if there are any specific identifiers
            if let _ = info["MPNowPlayingInfoPropertyExternalContentIdentifier"] {
                // This might indicate Apple Music or other integrated apps
                return .appleMusic
            }
            
            // Check for Pandora-specific properties (if any)
            if let _ = info["MPNowPlayingInfoPropertyExternalUserProfileIdentifier"] {
                return .pandora
            }
        }
        
        // Method 4: Check if specific apps are running (limited on iOS)
        // We can't directly check running apps, but we can make educated guesses
        
        // Default to unknown for now - in a real implementation you might:
        // 1. Use private APIs (not recommended for App Store)
        // 2. Use URL schemes to check if apps are installed
        // 3. Use heuristics based on track metadata
        
        print("Branchr: Could not determine music source, defaulting to unknown")
        return .unknown
    }
    
    /// Broadcast current track to all connected peers
    func broadcastNowPlaying() async {
        guard isHostDJ, let track = currentTrack else { return }
        
        do {
            let data = try JSONEncoder().encode(track)
            let command = MusicCommand.nowPlaying(data)
            await groupSessionManager?.broadcastToPeers(command.data)
            print("Branchr: Broadcasted now playing: \(track.title) - \(track.artist)")
        } catch {
            print("Branchr: Failed to encode now playing info: \(error)")
        }
    }
    
    /// Handle incoming now playing info from host
    func handleIncomingNowPlaying(_ info: NowPlayingInfo) {
        guard !isHostDJ else { return } // Only riders receive this
        
        currentTrack = info
        print("Branchr: Received now playing: \(info.title) - \(info.artist)")
    }
    
    /// Send playback control command to host
    func sendPlaybackCommand(_ command: PlaybackCommand) async {
        guard !isHostDJ else { return } // Only riders send commands
        
        do {
            let data = try JSONEncoder().encode(command)
            let musicCommand = MusicCommand.playbackControl(data)
            await groupSessionManager?.broadcastToPeers(musicCommand.data)
            print("Branchr: Sent playback command: \(command)")
        } catch {
            print("Branchr: Failed to encode playback command: \(error)")
        }
    }
    
    deinit {
        stopPolling()
    }
}

/// Playback control commands that riders can send to host
struct PlaybackCommand: Codable {
    let action: PlaybackAction
    let timestamp: Date
    
    init(action: PlaybackAction) {
        self.action = action
        self.timestamp = Date()
    }
}

enum PlaybackAction: String, Codable {
    case play = "play"
    case pause = "pause"
    case next = "next"
    case previous = "previous"
    case volumeUp = "volume_up"
    case volumeDown = "volume_down"
}

/// Music commands for MultipeerConnectivity communication
enum MusicCommand: Codable {
    case nowPlaying(Data)
    case playbackControl(Data)
    case songRequest(Data)
    case djStatus(Data)
    
    var data: Data {
        switch self {
        case .nowPlaying(let data), .playbackControl(let data), .songRequest(let data), .djStatus(let data):
            return data
        }
    }
    
    var commandType: String {
        switch self {
        case .nowPlaying:
            return "now_playing"
        case .playbackControl:
            return "playback_control"
        case .songRequest:
            return "song_request"
        case .djStatus:
            return "dj_status"
        }
    }
}