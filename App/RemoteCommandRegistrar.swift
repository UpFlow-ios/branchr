//
//  RemoteCommandRegistrar.swift
//  branchr
//
//  Created by Joe Dormond on 10/21/25.
//

import Foundation
import MediaPlayer
import AVFoundation
import SwiftUI

/// Service for registering and handling remote commands from earbuds and car controls
/// Maps standard media controls to Branchr audio functions
@MainActor
class RemoteCommandRegistrar: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isRegistered = false
    @Published var lastCommand: RemoteCommand?
    
    // MARK: - Remote Command Enum
    enum RemoteCommand: String, CaseIterable {
        case playPause = "play_pause"
        case nextTrack = "next_track"
        case previousTrack = "previous_track"
        case stop = "stop"
        case seekForward = "seek_forward"
        case seekBackward = "seek_backward"
        
        var displayName: String {
            switch self {
            case .playPause: return "Play/Pause"
            case .nextTrack: return "Next Track"
            case .previousTrack: return "Previous Track"
            case .stop: return "Stop"
            case .seekForward: return "Seek Forward"
            case .seekBackward: return "Seek Backward"
            }
        }
        
        var description: String {
            switch self {
            case .playPause: return "Toggle Both ↔ Voice Only"
            case .nextTrack: return "Music Only Mode"
            case .previousTrack: return "Both Mode"
            case .stop: return "Voice Only Mode"
            case .seekForward: return "Music Volume +"
            case .seekBackward: return "Music Volume -"
            }
        }
    }
    
    // MARK: - Private Properties
    private var hudManager: HUDManager?
    private var audioMixer: AudioMixerService?
    private let hapticsService = HapticsService.shared
    
    // MARK: - Initialization
    override init() {
        super.init()
        print("Branchr RemoteCommandRegistrar initialized")
    }
    
    // MARK: - Public Methods
    
    /// Register remote commands with MPRemoteCommandCenter
    func registerCommands() {
        guard !isRegistered else { return }
        
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Play/Pause Command
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.handlePlayPauseCommand()
            return .success
        }
        commandCenter.togglePlayPauseCommand.isEnabled = true
        
        // Next Track Command
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.handleNextTrackCommand()
            return .success
        }
        commandCenter.nextTrackCommand.isEnabled = true
        
        // Previous Track Command
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.handlePreviousTrackCommand()
            return .success
        }
        commandCenter.previousTrackCommand.isEnabled = true
        
        // Stop Command
        commandCenter.stopCommand.addTarget { [weak self] _ in
            self?.handleStopCommand()
            return .success
        }
        commandCenter.stopCommand.isEnabled = true
        
        // Seek Forward Command
        commandCenter.seekForwardCommand.addTarget { [weak self] _ in
            self?.handleSeekForwardCommand()
            return .success
        }
        commandCenter.seekForwardCommand.isEnabled = true
        
        // Seek Backward Command
        commandCenter.seekBackwardCommand.addTarget { [weak self] _ in
            self?.handleSeekBackwardCommand()
            return .success
        }
        commandCenter.seekBackwardCommand.isEnabled = true
        
        isRegistered = true
        print("Branchr: Remote commands registered")
    }
    
    /// Unregister remote commands
    func unregisterCommands() {
        guard isRegistered else { return }
        
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.togglePlayPauseCommand.removeTarget(self)
        commandCenter.nextTrackCommand.removeTarget(self)
        commandCenter.previousTrackCommand.removeTarget(self)
        commandCenter.stopCommand.removeTarget(self)
        commandCenter.seekForwardCommand.removeTarget(self)
        commandCenter.seekBackwardCommand.removeTarget(self)
        
        // Disable commands
        commandCenter.togglePlayPauseCommand.isEnabled = false
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.stopCommand.isEnabled = false
        commandCenter.seekForwardCommand.isEnabled = false
        commandCenter.seekBackwardCommand.isEnabled = false
        
        isRegistered = false
        print("Branchr: Remote commands unregistered")
    }
    
    /// Set the HUD manager for integration
    func setHUDManager(_ manager: HUDManager) {
        self.hudManager = manager
        print("Branchr: HUD manager connected to remote commands")
    }
    
    /// Set the audio mixer for integration
    func setAudioMixer(_ mixer: AudioMixerService) {
        self.audioMixer = mixer
        print("Branchr: Audio mixer connected to remote commands")
    }
    
    // MARK: - Command Handlers
    
    private func handlePlayPauseCommand() {
        lastCommand = .playPause
        
        guard let hudManager = hudManager else { return }
        
        // Toggle between Both and Voice Only modes
        if hudManager.currentMode == .both {
            hudManager.switchToVoiceOnly()
        } else {
            hudManager.switchToBoth()
        }
        
        hapticsService.modeChange()
        print("Branchr: Play/Pause command handled")
    }
    
    private func handleNextTrackCommand() {
        lastCommand = .nextTrack
        
        guard let hudManager = hudManager else { return }
        
        // Switch to Music Only mode
        hudManager.switchToMusicOnly()
        
        hapticsService.modeChange()
        print("Branchr: Next Track command handled")
    }
    
    private func handlePreviousTrackCommand() {
        lastCommand = .previousTrack
        
        guard let hudManager = hudManager else { return }
        
        // Switch to Both mode
        hudManager.switchToBoth()
        
        hapticsService.modeChange()
        print("Branchr: Previous Track command handled")
    }
    
    private func handleStopCommand() {
        lastCommand = .stop
        
        guard let hudManager = hudManager else { return }
        
        // Switch to Voice Only mode
        hudManager.switchToVoiceOnly()
        
        hapticsService.modeChange()
        print("Branchr: Stop command handled")
    }
    
    private func handleSeekForwardCommand() {
        lastCommand = .seekForward
        
        guard let hudManager = hudManager else { return }
        
        // Increase music volume
        hudManager.adjustMusicVolume(0.05)
        
        hapticsService.volumeChange()
        print("Branchr: Seek Forward command handled")
    }
    
    private func handleSeekBackwardCommand() {
        lastCommand = .seekBackward
        
        guard let hudManager = hudManager else { return }
        
        // Decrease music volume
        hudManager.adjustMusicVolume(-0.05)
        
        hapticsService.volumeChange()
        print("Branchr: Seek Backward command handled")
    }
    
    // MARK: - Audio Session Setup
    
    /// Setup audio session for remote commands
    func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker]
            )
            try audioSession.setActive(true)
            print("Branchr: Audio session configured for remote commands")
        } catch {
            print("Branchr: Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Command Status Methods
    
    /// Get command mapping information
    func getCommandMapping() -> [RemoteCommand: String] {
        return [
            .playPause: "Toggle Both ↔ Voice Only",
            .nextTrack: "Music Only Mode",
            .previousTrack: "Both Mode",
            .stop: "Voice Only Mode",
            .seekForward: "Music Volume +",
            .seekBackward: "Music Volume -"
        ]
    }
    
    /// Get last command information
    func getLastCommandInfo() -> (command: RemoteCommand?, time: Date?) {
        return (lastCommand, Date())
    }
    
    /// Check if specific command is enabled
    func isCommandEnabled(_ command: RemoteCommand) -> Bool {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        switch command {
        case .playPause:
            return commandCenter.togglePlayPauseCommand.isEnabled
        case .nextTrack:
            return commandCenter.nextTrackCommand.isEnabled
        case .previousTrack:
            return commandCenter.previousTrackCommand.isEnabled
        case .stop:
            return commandCenter.stopCommand.isEnabled
        case .seekForward:
            return commandCenter.seekForwardCommand.isEnabled
        case .seekBackward:
            return commandCenter.seekBackwardCommand.isEnabled
        }
    }
    
    // MARK: - Cleanup
    deinit {
        // Note: deinit cannot be @MainActor, so we handle cleanup differently
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.togglePlayPauseCommand.removeTarget(nil)
        commandCenter.nextTrackCommand.removeTarget(nil)
        commandCenter.previousTrackCommand.removeTarget(nil)
        commandCenter.stopCommand.removeTarget(nil)
        commandCenter.seekForwardCommand.removeTarget(nil)
        commandCenter.seekBackwardCommand.removeTarget(nil)
        
        // Disable commands
        commandCenter.togglePlayPauseCommand.isEnabled = false
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.stopCommand.isEnabled = false
        commandCenter.seekForwardCommand.isEnabled = false
        commandCenter.seekBackwardCommand.isEnabled = false
    }
}
