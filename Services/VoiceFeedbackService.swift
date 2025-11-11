//
//  VoiceFeedbackService.swift
//  branchr
//
//  Created by Joseph Dormond on 2025-11-04
//  Phase 31 - Unified Voice Feedback Service
//

import Foundation
import AVFoundation

/**
 * 🗣️ Voice Feedback Service
 *
 * Provides simple text-to-speech functionality for ride tracking announcements.
 * Wraps AVSpeechSynthesizer for easy use throughout the app.
 * Phase 34E: Ensures audio session is properly configured for playback.
 * Phase 35.3: @MainActor for concurrency safety.
 */
@MainActor
final class VoiceFeedbackService {
    static let shared = VoiceFeedbackService()
    
    private let synthesizer = AVSpeechSynthesizer()
    
    private init() {
        print("🗣️ VoiceFeedbackService initialized")
    }
    
    /// Speak a text message
    func speak(_ text: String) {
        // Phase 34F: Activate playback audio session before speaking
        activatePlaybackSessionIfNeeded()
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.48
        utterance.volume = 0.8
        
        synthesizer.speak(utterance)
        print("🗣️ Speaking: \(text)")
        
        // Phase 34F: Restore main audio session after speech completes
        // Estimate duration: ~150 words per minute at rate 0.48 = ~2.5 words per second
        let wordCount = text.split(separator: " ").count
        let estimatedDuration = Double(wordCount) / 2.5 + 0.5 // Add buffer
        DispatchQueue.main.asyncAfter(deadline: .now() + estimatedDuration) {
            self.restoreMainAudioSession()
        }
    }
    
    /// Stop current speech
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        restoreMainAudioSession()
    }
    
    // MARK: - Phase 34F: Audio Session Management
    
    /// Activate playback audio session to ensure voice announcements are heard
    private func activatePlaybackSessionIfNeeded() {
        let session = AVAudioSession.sharedInstance()
        do {
            // Phase 34F: Temporarily deactivate current session if needed
            try session.setActive(false, options: .notifyOthersOnDeactivation)
            
            // Use .playback category with .spokenAudio mode for clear speech
            // .duckOthers allows voice to play even if other audio is active
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            
            // Activate this session exclusively for speaking
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            
            print("🔊 VoiceFeedbackService: Playback session active")
        } catch {
            print("⚠️ VoiceFeedbackService: Failed to activate playback session: \(error.localizedDescription)")
        }
    }
    
    /// Restore main audio session (for voice chat) after speech completes
    private func restoreMainAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            // Restore to playAndRecord for voice chat functionality
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .defaultToSpeaker])
            try session.setActive(true)
            print("🎧 VoiceFeedbackService: Restored main audio session")
        } catch {
            print("⚠️ VoiceFeedbackService: Failed to restore main session: \(error.localizedDescription)")
        }
    }
}

