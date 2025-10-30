//
//  HUDManager.swift
//  branchr
//
//  Created by Joe Dormond on 10/21/25.
//

import Foundation
import SwiftUI

/// Central manager for Ride HUD state and gesture integration
/// Coordinates between gesture detection, audio mixing, and UI updates
@MainActor
class HUDManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isVisible = false
    @Published var currentMode: AudioMixerService.AudioMode = .both
    @Published var musicVolume: Float = 0.6
    @Published var voiceVolume: Float = 0.8
    @Published var peerCount: Int = 0
    @Published var connectionStatus: String = "Connected"
    @Published var lastAction: String = ""
    @Published var showToast = false
    
    // MARK: - Private Properties
    private var audioMixer: AudioMixerService?
    private var gestureService: GestureControlService?
    private var hapticsService = HapticsService.shared
    private var groupManager: GroupSessionManager?
    
    // Toast management
    private var toastTimer: Timer?
    private let toastDuration: TimeInterval = 2.0
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupNotificationObservers()
        print("Branchr HUDManager initialized")
    }
    
    // MARK: - Setup Methods
    
    private func setupNotificationObservers() {
        // Listen for gesture detection
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleGestureDetected(_:)),
            name: .rideGestureDetected,
            object: nil
        )
        
        print("Branchr: HUD notification observers setup complete")
    }
    
    // MARK: - Public Methods
    
    /// Set the audio mixer service for integration
    func setAudioMixer(_ mixer: AudioMixerService) {
        self.audioMixer = mixer
        
        // Subscribe to audio mixer changes
        // Note: In a real implementation, you'd use Combine publishers
        // For now, we'll update manually when needed
        updateFromAudioMixer()
        
        print("Branchr: Audio mixer connected to HUD")
    }
    
    /// Set the gesture control service for integration
    func setGestureService(_ service: GestureControlService) {
        self.gestureService = service
        print("Branchr: Gesture service connected to HUD")
    }
    
    /// Set the group session manager for peer count
    func setGroupManager(_ manager: GroupSessionManager) {
        self.groupManager = manager
        updatePeerCount()
        print("Branchr: Group manager connected to HUD")
    }
    
    /// Show the HUD overlay
    func showHUD() {
        isVisible = true
        updateFromAudioMixer()
        updatePeerCount()
        hapticsService.selection()
        print("Branchr: HUD shown")
    }
    
    /// Hide the HUD overlay
    func hideHUD() {
        isVisible = false
        hideToast()
        print("Branchr: HUD hidden")
    }
    
    /// Toggle HUD visibility
    func toggleHUD() {
        if isVisible {
            hideHUD()
        } else {
            showHUD()
        }
    }
    
    /// Flash a message in the HUD
    func flash(_ message: String) {
        lastAction = message
        showToast = true
        
        // Auto-hide toast after duration
        toastTimer?.invalidate()
        toastTimer = Timer.scheduledTimer(withTimeInterval: toastDuration, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.hideToast()
            }
        }
        
        print("Branchr: HUD flash message: \(message)")
    }
    
    /// Hide the toast message
    func hideToast() {
        showToast = false
        toastTimer?.invalidate()
        toastTimer = nil
    }
    
    // MARK: - Gesture Handling
    
    @objc private func handleGestureDetected(_ notification: Notification) {
        guard let gesture = notification.userInfo?["gesture"] as? GestureControlService.RideGesture else {
            return
        }
        
        handleGesture(gesture)
    }
    
    private func handleGesture(_ gesture: GestureControlService.RideGesture) {
        guard let audioMixer = audioMixer else { return }
        
        switch gesture {
        case .nodUp:
            // Increase music volume
            let newVolume = min(1.0, musicVolume + (gestureService?.volumeAdjustmentStep ?? 0.05))
            audioMixer.setMusicVolume(newVolume)
            musicVolume = newVolume
            flash("Music +5%")
            hapticsService.volumeChange()
            
        case .nodDown:
            // Decrease music volume
            let newVolume = max(0.0, musicVolume - (gestureService?.volumeAdjustmentStep ?? 0.05))
            audioMixer.setMusicVolume(newVolume)
            musicVolume = newVolume
            flash("Music -5%")
            hapticsService.volumeChange()
            
        case .tiltLeft:
            // Switch to voice only mode
            audioMixer.switchMode(.voiceOnly)
            currentMode = .voiceOnly
            flash("Voice Only")
            hapticsService.modeChange()
            
        case .tiltRight:
            // Switch to music only mode
            audioMixer.switchMode(.musicOnly)
            currentMode = .musicOnly
            flash("Music Only")
            hapticsService.modeChange()
            
        case .shake:
            // Switch to both mode
            audioMixer.switchMode(.both)
            currentMode = .both
            flash("Both Mode")
            hapticsService.gestureRecognized()
        }
        
        print("Branchr: Gesture handled - \(gesture.displayName)")
    }
    
    // MARK: - Update Methods
    
    private func updateFromAudioMixer() {
        guard let audioMixer = audioMixer else { return }
        
        musicVolume = audioMixer.musicVolume
        voiceVolume = audioMixer.voiceVolume
        currentMode = audioMixer.mode
    }
    
    private func updatePeerCount() {
        guard let groupManager = groupManager else { return }
        
        peerCount = groupManager.groupSize
        connectionStatus = groupManager.sessionActive ? "Connected" : "Disconnected"
    }
    
    /// Manual update from external sources
    func updateAudioState() {
        updateFromAudioMixer()
    }
    
    func updateGroupState() {
        updatePeerCount()
    }
    
    // MARK: - Volume Control Methods
    
    /// Adjust music volume with haptic feedback
    func adjustMusicVolume(_ delta: Float) {
        guard let audioMixer = audioMixer else { return }
        
        let newVolume = max(0.0, min(1.0, musicVolume + delta))
        audioMixer.setMusicVolume(newVolume)
        musicVolume = newVolume
        
        let percentage = Int(delta * 100)
        flash("Music \(percentage > 0 ? "+" : "")\(percentage)%")
        hapticsService.volumeChange()
    }
    
    /// Adjust voice volume with haptic feedback
    func adjustVoiceVolume(_ delta: Float) {
        guard let audioMixer = audioMixer else { return }
        
        let newVolume = max(0.0, min(1.0, voiceVolume + delta))
        audioMixer.setVoiceVolume(newVolume)
        voiceVolume = newVolume
        
        let percentage = Int(delta * 100)
        flash("Voice \(percentage > 0 ? "+" : "")\(percentage)%")
        hapticsService.volumeChange()
    }
    
    // MARK: - Mode Control Methods
    
    /// Switch to voice only mode
    func switchToVoiceOnly() {
        guard let audioMixer = audioMixer else { return }
        
        audioMixer.switchMode(.voiceOnly)
        currentMode = .voiceOnly
        flash("Voice Only")
        hapticsService.modeChange()
    }
    
    /// Switch to music only mode
    func switchToMusicOnly() {
        guard let audioMixer = audioMixer else { return }
        
        audioMixer.switchMode(.musicOnly)
        currentMode = .musicOnly
        flash("Music Only")
        hapticsService.modeChange()
    }
    
    /// Switch to both mode
    func switchToBoth() {
        guard let audioMixer = audioMixer else { return }
        
        audioMixer.switchMode(.both)
        currentMode = .both
        flash("Both Mode")
        hapticsService.modeChange()
    }
    
    // MARK: - Status Methods
    
    /// Get current HUD status
    func getHUDStatus() -> (isVisible: Bool, mode: AudioMixerService.AudioMode, musicVolume: Float, voiceVolume: Float, peerCount: Int) {
        return (isVisible, currentMode, musicVolume, voiceVolume, peerCount)
    }
    
    /// Get gesture statistics
    func getGestureStats() -> (totalGestures: Int, lastGesture: GestureControlService.RideGesture?, timeSinceLastGesture: TimeInterval) {
        return gestureService?.getGestureStats() ?? (0, nil, 0)
    }
    
    // MARK: - Cleanup
    deinit {
        NotificationCenter.default.removeObserver(self)
        toastTimer?.invalidate()
    }
}
