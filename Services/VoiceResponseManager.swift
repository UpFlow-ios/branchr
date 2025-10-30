//
//  VoiceResponseManager.swift
//  branchr
//
//  Created by Joe Dormond on 2025-10-26.
//

import Foundation
import AVFoundation

/// Manages text-to-speech for voice assistant responses
final class VoiceResponseManager: ObservableObject {
    
    static let shared = VoiceResponseManager()
    
    // MARK: - Private Properties
    private let synthesizer = AVSpeechSynthesizer()
    private var isEnabled = true
    
    // MARK: - Initialization
    private init() {
        print("Branchr: VoiceResponseManager initialized")
    }
    
    /// Enable or disable voice responses
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
    
    /// Speak a response
    func say(_ text: String) {
        guard isEnabled else { return }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 0.8
        
        synthesizer.speak(utterance)
        
        print("Branchr: Speaking: \(text)")
    }
    
    /// Speak wake word activation confirmation
    func sayWakeWordActivated() {
        say("Hey Branchr activated. What can I help you with?")
    }
    
    /// Speak song request confirmation
    func saySongRequestAdded(_ songName: String) {
        say("Adding \(songName) to the queue")
    }
    
    /// Speak ride status
    func sayRideStatus(distance: Double, duration: TimeInterval, speed: Double) {
        let miles = String(format: "%.1f", distance)
        let durationStr = formatDuration(duration)
        let speedStr = String(format: "%.1f", speed)
        
        say("You've ridden \(miles) miles in \(durationStr) at \(speedStr) miles per hour")
    }
}

// MARK: - Helper Methods
extension VoiceResponseManager {
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        
        if hours > 0 {
            return "\(hours) hours and \(minutes) minutes"
        } else {
            return "\(minutes) minutes"
        }
    }
}

