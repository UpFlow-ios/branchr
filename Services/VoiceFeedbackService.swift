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
 */
final class VoiceFeedbackService {
    static let shared = VoiceFeedbackService()
    
    private let synthesizer = AVSpeechSynthesizer()
    
    private init() {
        print("🗣️ VoiceFeedbackService initialized")
    }
    
    /// Speak a text message
    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.volume = 0.8
        
        synthesizer.speak(utterance)
        print("🗣️ Speaking: \(text)")
    }
    
    /// Stop current speech
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

