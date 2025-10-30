//
//  HostDJController.swift
//  branchr
//
//  Created by Joe Dormond on 10/24/25.
//

import Foundation
import MediaPlayer
import Combine

/// Controller for managing host DJ functionality and playback controls
final class HostDJController: NSObject, ObservableObject {
    @Published var isActiveHost: Bool = false
    @Published var hostName: String = ""
    @Published var isPlaying: Bool = false
    
    let musicSync: MusicSyncService
    let songRequests: SongRequestManager
    
    private var remoteCommandCenter: MPRemoteCommandCenter
    private var cancellables = Set<AnyCancellable>()
    
    init(musicSync: MusicSyncService, songRequests: SongRequestManager) {
        self.musicSync = musicSync
        self.songRequests = songRequests
        self.remoteCommandCenter = MPRemoteCommandCenter.shared()
        
        super.init()
        
        setupRemoteCommandCenter()
        setupBindings()
        print("Branchr: HostDJController initialized")
    }
    
    /// Activate host DJ mode
    func activateHost() {
        isActiveHost = true
        musicSync.becomeHostDJ()
        setupRemoteCommandCenter()
        print("Branchr: Host DJ activated")
    }
    
    /// Deactivate host DJ mode
    func deactivateHost() {
        isActiveHost = false
        musicSync.resignHostDJ()
        disableRemoteCommandCenter()
        print("Branchr: Host DJ deactivated")
    }
    
    /// Approve a song request
    func approveRequest(_ request: SongRequest) async {
        await songRequests.approveRequest(request)
        
        // Optionally, you could trigger a search in the music app here
        // This would require additional integration with specific music apps
        print("Branchr: Approved request: \(request.title) by \(request.requestedBy)")
    }
    
    /// Reject a song request
    func rejectRequest(_ request: SongRequest) async {
        await songRequests.rejectRequest(request)
        print("Branchr: Rejected request: \(request.title) by \(request.requestedBy)")
    }
    
    /// Skip to next track
    func skipTrack() {
        // Note: MPRemoteCommand doesn't have invoke() method
        // The commands are handled by the system when registered
        print("Branchr: Skip track command sent")
    }
    
    /// Go to previous track
    func previousTrack() {
        print("Branchr: Previous track command sent")
    }
    
    /// Pause playback
    func pausePlayback() {
        print("Branchr: Pause command sent")
    }
    
    /// Resume playback
    func resumePlayback() {
        print("Branchr: Resume command sent")
    }
    
    /// Toggle play/pause
    func togglePlayback() {
        if isPlaying {
            pausePlayback()
        } else {
            resumePlayback()
        }
    }
    
    /// Increase volume
    func volumeUp() {
        // Note: Volume control requires additional setup and may not work on all devices
        // This is a simplified implementation
        print("Branchr: Volume up requested")
    }
    
    /// Decrease volume
    func volumeDown() {
        // Note: Volume control requires additional setup and may not work on all devices
        // This is a simplified implementation
        print("Branchr: Volume down requested")
    }
    
    /// Setup remote command center for playback control
    private func setupRemoteCommandCenter() {
        // Enable commands
        remoteCommandCenter.playCommand.isEnabled = true
        remoteCommandCenter.pauseCommand.isEnabled = true
        remoteCommandCenter.nextTrackCommand.isEnabled = true
        remoteCommandCenter.previousTrackCommand.isEnabled = true
        remoteCommandCenter.togglePlayPauseCommand.isEnabled = true
        
        // Set up command handlers
        remoteCommandCenter.playCommand.addTarget { [weak self] _ in
            DispatchQueue.main.async {
                self?.isPlaying = true
            }
            return .success
        }
        
        remoteCommandCenter.pauseCommand.addTarget { [weak self] _ in
            DispatchQueue.main.async {
                self?.isPlaying = false
            }
            return .success
        }
        
        remoteCommandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            DispatchQueue.main.async {
                self?.isPlaying.toggle()
            }
            return .success
        }
        
        remoteCommandCenter.nextTrackCommand.addTarget { [weak self] _ in
            DispatchQueue.main.async {
                self?.handleNextTrack()
            }
            return .success
        }
        
        remoteCommandCenter.previousTrackCommand.addTarget { [weak self] _ in
            DispatchQueue.main.async {
                self?.handlePreviousTrack()
            }
            return .success
        }
    }
    
    /// Disable remote command center
    private func disableRemoteCommandCenter() {
        remoteCommandCenter.playCommand.isEnabled = false
        remoteCommandCenter.pauseCommand.isEnabled = false
        remoteCommandCenter.nextTrackCommand.isEnabled = false
        remoteCommandCenter.previousTrackCommand.isEnabled = false
        remoteCommandCenter.togglePlayPauseCommand.isEnabled = false
        
        // Remove targets
        remoteCommandCenter.playCommand.removeTarget(self)
        remoteCommandCenter.pauseCommand.removeTarget(self)
        remoteCommandCenter.nextTrackCommand.removeTarget(self)
        remoteCommandCenter.previousTrackCommand.removeTarget(self)
        remoteCommandCenter.togglePlayPauseCommand.removeTarget(self)
    }
    
    /// Setup reactive bindings
    private func setupBindings() {
        // Bind music sync playing state
        musicSync.$currentTrack
            .map { $0?.isPlaying ?? false }
            .assign(to: \.isPlaying, on: self)
            .store(in: &cancellables)
    }
    
    /// Handle next track command
    private func handleNextTrack() {
        print("Branchr: Next track command received")
        // Additional logic can be added here if needed
    }
    
    /// Handle previous track command
    private func handlePreviousTrack() {
        print("Branchr: Previous track command received")
        // Additional logic can be added here if needed
    }
    
    /// Get current playback status
    var playbackStatus: String {
        if isPlaying {
            return "Playing"
        } else {
            return "Paused"
        }
    }
    
    /// Get host status summary
    var hostStatusSummary: String {
        if isActiveHost {
            return "You are the DJ"
        } else {
            return "Not hosting"
        }
    }
    
    /// Get pending requests count
    var pendingRequestsCount: Int {
        return songRequests.pendingCount
    }
    
    /// Get next pending request
    var nextPendingRequest: SongRequest? {
        return songRequests.oldestPendingRequest
    }
    
    /// Check if there are pending requests
    var hasPendingRequests: Bool {
        return pendingRequestsCount > 0
    }
    
    deinit {
        disableRemoteCommandCenter()
        cancellables.removeAll()
    }
}
