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
 * Phase 39: Added queue/debounce to prevent overlapping speech and track speech state.
 */
@MainActor
final class VoiceFeedbackService: NSObject {
    static let shared = VoiceFeedbackService()
    
    private let synthesizer = AVSpeechSynthesizer()
    
    // Phase 39: Speech state tracking and queue
    private var isSpeaking = false
    private var speechQueue: [String] = []
    private var lastSpeechTime: Date?
    private let minimumSpeechInterval: TimeInterval = 0.5 // Prevent rapid-fire speech
    
    private override init() {
        super.init()
        synthesizer.delegate = self
        print("🗣️ VoiceFeedbackService initialized")
    }
    
    /// Speak a text message (with queue/debounce)
    func speak(_ text: String) {
        // Phase 39: Validate text is not empty to avoid AVAudioBuffer warnings
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("⚠️ VoiceFeedbackService: Attempted to speak empty text, ignoring")
            return
        }
        
        // Phase 39: Debounce - prevent rapid-fire speech
        if let lastTime = lastSpeechTime {
            let timeSinceLastSpeech = Date().timeIntervalSince(lastTime)
            if timeSinceLastSpeech < minimumSpeechInterval {
                print("🗣️ VoiceFeedbackService: Debouncing speech (too soon after last)")
                return
            }
        }
        
        // Phase 39: If already speaking, queue the message
        if isSpeaking {
            speechQueue.append(text)
            print("🗣️ VoiceFeedbackService: Queued speech: \(text)")
            return
        }
        
        // Phase 39: Start speaking immediately
        startSpeaking(text)
    }
    
    /// Start speaking a message (internal)
    private func startSpeaking(_ text: String) {
        // Phase 34F: Activate playback audio session before speaking
        activatePlaybackSessionIfNeeded()
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.48
        utterance.volume = 0.8
        
        // Phase 39: Ensure utterance has valid text to avoid AVAudioBuffer warnings
        guard !utterance.speechString.isEmpty else {
            print("⚠️ VoiceFeedbackService: Utterance has empty speech string, skipping")
            processNextInQueue()
            return
        }
        
        isSpeaking = true
        lastSpeechTime = Date()
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
    
    /// Process next item in queue
    private func processNextInQueue() {
        guard !speechQueue.isEmpty else {
            isSpeaking = false
            return
        }
        
        let nextText = speechQueue.removeFirst()
        // Small delay to ensure previous speech has fully stopped
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.startSpeaking(nextText)
        }
    }
    
    /// Stop current speech and clear queue
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        speechQueue.removeAll()
        isSpeaking = false
        restoreMainAudioSession()
        print("🗣️ VoiceFeedbackService: Stopped speech and cleared queue")
    }
    
    /// Check if currently speaking
    var currentlySpeaking: Bool {
        return isSpeaking
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

// MARK: - Phase 39: AVSpeechSynthesizerDelegate

extension VoiceFeedbackService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("🗣️ VoiceFeedbackService: Finished speaking")
        isSpeaking = false
        processNextInQueue()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        print("🗣️ VoiceFeedbackService: Speech cancelled")
        isSpeaking = false
        processNextInQueue()
    }
}

