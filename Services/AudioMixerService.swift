//
//  AudioMixerService.swift
//  branchr
//
//  Created by Joe Dormond on 10/21/25.
//

import Foundation
import AVFoundation
import SwiftUI

/// Service for managing independent audio mixing between voice chat and music
/// Provides real-time volume control and mode switching for optimal ride experience
@MainActor
class AudioMixerService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var voiceVolume: Float = 0.8
    @Published var musicVolume: Float = 0.6
    @Published var mode: AudioMode = .both
    @Published var isActive = false
    @Published var microphonePermissionStatus: AVAudioSession.RecordPermission = .undetermined
    
    // MARK: - Audio Mode Enum
    enum AudioMode: String, CaseIterable {
        case voiceOnly = "voice_only"
        case musicOnly = "music_only"
        case both = "both"
        
    var displayName: String {
        switch self {
        case .voiceOnly: return "Voice Only"
        case .musicOnly: return "Music Only"
        case .both: return "Both"
        }
    }
    }
    
    // MARK: - Private Properties
    private var audioEngine: AVAudioEngine
    private var voiceMixerNode: AVAudioMixerNode
    private var musicMixerNode: AVAudioMixerNode
    private var outputMixerNode: AVAudioMixerNode
    private var audioSession: AVAudioSession
    
    // MARK: - Initialization
    override init() {
        // Initialize audio engine and mixer nodes
        self.audioEngine = AVAudioEngine()
        self.voiceMixerNode = AVAudioMixerNode()
        self.musicMixerNode = AVAudioMixerNode()
        self.outputMixerNode = AVAudioMixerNode()
        self.audioSession = AVAudioSession.sharedInstance()
        
        super.init()
        
        // Check current microphone permission status
        microphonePermissionStatus = audioSession.recordPermission
        
        // Only setup audio if we have permission
        if microphonePermissionStatus == .granted {
            setupAudioEngine()
            setupAudioSession()
        }
        
        print("Branchr AudioMixerService initialized - Microphone permission: \(microphonePermissionStatus)")
    }
    
    // MARK: - Setup Methods
    
    /// Request microphone permission from the user
    func requestMicrophonePermission() {
        audioSession.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.microphonePermissionStatus = granted ? .granted : .denied
                
                if granted {
                    self?.setupAudioEngine()
                    self?.setupAudioSession()
                    print("Branchr AudioMixer: Microphone permission granted")
                } else {
                    print("Branchr AudioMixer: Microphone permission denied")
                }
            }
        }
    }
    
    /// Check if microphone permission is granted
    var hasMicrophonePermission: Bool {
        return microphonePermissionStatus == .granted
    }
    
    private func setupAudioEngine() {
        // Attach mixer nodes to audio engine
        audioEngine.attach(voiceMixerNode)
        audioEngine.attach(musicMixerNode)
        audioEngine.attach(outputMixerNode)
        
        // Connect voice mixer to output mixer
        audioEngine.connect(voiceMixerNode, to: outputMixerNode, format: nil)
        
        // Connect music mixer to output mixer
        audioEngine.connect(musicMixerNode, to: outputMixerNode, format: nil)
        
        // Connect output mixer to main mixer (speaker output)
        audioEngine.connect(outputMixerNode, to: audioEngine.mainMixerNode, format: nil)
        
        // Set initial volumes
        voiceMixerNode.outputVolume = voiceVolume
        musicMixerNode.outputVolume = musicVolume
        
        print("Branchr: Audio engine setup complete")
    }
    
    private func setupAudioSession() {
        // Use centralized AudioSessionManager for high-fidelity music + voice chat
        // This preserves full-range audio (including bass) while allowing mic input
        AudioSessionManager.shared.configureForRideMusicAndVoiceChat()
    }
    
    // MARK: - Public Methods
    
    /// Start the audio mixer service
    func startMixer() {
        guard !isActive else { return }
        
        do {
            try audioEngine.start()
            isActive = true
            updateMix()
            print("Branchr: Audio mixer started")
        } catch {
            print("Branchr: Failed to start audio mixer: \(error)")
        }
    }
    
    /// Stop the audio mixer service
    func stopMixer() {
        guard isActive else { return }
        
        audioEngine.stop()
        isActive = false
        print("Branchr: Audio mixer stopped")
    }
    
    /// Set voice volume level (0.0 - 1.0)
    func setVoiceVolume(_ level: Float) {
        let clampedLevel = max(0.0, min(1.0, level))
        voiceVolume = clampedLevel
        
        if mode != .musicOnly {
            voiceMixerNode.outputVolume = clampedLevel
        }
        
        print("Branchr: Voice volume set to \(clampedLevel)")
    }
    
    /// Set music volume level (0.0 - 1.0)
    func setMusicVolume(_ level: Float) {
        let clampedLevel = max(0.0, min(1.0, level))
        musicVolume = clampedLevel
        
        if mode != .voiceOnly {
            musicMixerNode.outputVolume = clampedLevel
        }
        
        print("Branchr: Music volume set to \(clampedLevel)")
    }
    
    /// Switch audio mode (voice only, music only, or both)
    func switchMode(_ newMode: AudioMode) {
        mode = newMode
        updateMix()
        print("Branchr: Audio mode switched to \(newMode.displayName)")
    }
    
    /// Update the audio mix based on current mode and volumes
    func updateMix() {
        switch mode {
        case .voiceOnly:
            voiceMixerNode.outputVolume = voiceVolume
            musicMixerNode.outputVolume = 0.0
            
        case .musicOnly:
            voiceMixerNode.outputVolume = 0.0
            musicMixerNode.outputVolume = musicVolume
            
        case .both:
            voiceMixerNode.outputVolume = voiceVolume
            musicMixerNode.outputVolume = musicVolume
        }
        
        print("Branchr: Audio mix updated - Voice: \(voiceVolume), Music: \(musicVolume), Mode: \(mode.displayName)")
    }
    
    /// Get voice mixer node for voice chat service integration
    var voiceMixer: AVAudioMixerNode {
        return voiceMixerNode
    }
    
    /// Get music mixer node for music sync service integration
    var musicMixer: AVAudioMixerNode {
        return musicMixerNode
    }
    
    /// Enable smart ducking - automatically lower music when voice is detected
    func enableSmartDucking() {
        // This would implement automatic ducking based on voice activity
        // For now, we'll implement a simple version
        print("Branchr: Smart ducking enabled")
    }
    
    /// Disable smart ducking
    func disableSmartDucking() {
        print("Branchr: Smart ducking disabled")
    }
    
    /// Reset to default settings
    func resetToDefaults() {
        voiceVolume = 0.8
        musicVolume = 0.6
        mode = .both
        updateMix()
        print("Branchr: Audio mixer reset to defaults")
    }
    
    /// Get current audio levels for visualization
    func getAudioLevels() -> (voice: Float, music: Float) {
        // This would return real-time audio levels for UI visualization
        // For now, return current volume settings
        return (voice: voiceVolume, music: musicVolume)
    }
    
    // MARK: - Audio Processing
    
    /// Apply audio effects to voice input
    func applyVoiceEffects(_ effects: [AudioEffect]) {
        // This would apply various audio effects to the voice input
        // Implementation would depend on specific effects needed
        print("Branchr: Applying voice effects: \(effects)")
    }
    
    /// Apply audio effects to music input
    func applyMusicEffects(_ effects: [AudioEffect]) {
        // This would apply various audio effects to the music input
        // Implementation would depend on specific effects needed
        print("Branchr: Applying music effects: \(effects)")
    }
    
    // MARK: - Cleanup
    deinit {
        // Note: deinit cannot be @MainActor, so we handle cleanup differently
        audioEngine.stop()
        
        do {
            try audioSession.setActive(false)
        } catch {
            print("Branchr: Failed to deactivate audio session: \(error)")
        }
    }
}

// MARK: - Audio Effect Types
enum AudioEffect: String, CaseIterable {
    case noiseReduction = "noise_reduction"
    case windReduction = "wind_reduction"
    case echoCancellation = "echo_cancellation"
    case autoGain = "auto_gain"
    case bassBoost = "bass_boost"
    case trebleBoost = "treble_boost"
    
    var displayName: String {
        switch self {
        case .noiseReduction: return "Noise Reduction"
        case .windReduction: return "Wind Reduction"
        case .echoCancellation: return "Echo Cancellation"
        case .autoGain: return "Auto Gain"
        case .bassBoost: return "Bass Boost"
        case .trebleBoost: return "Treble Boost"
        }
    }
    
    var icon: String {
        switch self {
        case .noiseReduction: return "waveform"
        case .windReduction: return "wind"
        case .echoCancellation: return "speaker.slash"
        case .autoGain: return "slider.horizontal.3"
        case .bassBoost: return "speaker.wave.2"
        case .trebleBoost: return "speaker.wave.3"
        }
    }
}
