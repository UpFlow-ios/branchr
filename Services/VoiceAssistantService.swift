//
//  VoiceAssistantService.swift
//  branchr
//
//  Created by Joe Dormond on 10/23/25.
//

import Foundation
import AVFoundation
import SwiftUI

/// Service for providing voice announcements during rides
/// Uses AVSpeechSynthesizer to give real-time feedback and updates
@MainActor
class VoiceAssistantService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isEnabled = false
    @Published var isSpeaking = false
    
    // MARK: - Private Properties
    private let speechSynthesizer = AVSpeechSynthesizer()
    private let voice = AVSpeechSynthesisVoice(language: "en-US")
    private var lastAnnouncedDistance: Double = 0.0
    private let announcementInterval: Double = 0.5 // Announce every 0.5 miles
    
    // MARK: - Initialization
    override init() {
        super.init()
        speechSynthesizer.delegate = self
        print("Branchr VoiceAssistantService initialized")
    }
    
    // MARK: - Public Methods
    
    /// Enable or disable the voice assistant
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        print("Branchr: Voice assistant \(enabled ? "enabled" : "disabled")")
    }
    
    /// Speak a custom message
    func speak(_ message: String) {
        guard isEnabled else { return }
        
        let utterance = AVSpeechUtterance(string: message)
        utterance.voice = voice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9 // Slightly slower for clarity
        utterance.volume = 0.8
        
        speechSynthesizer.speak(utterance)
        print("Branchr: Speaking - \(message)")
    }
    
    /// Announce ride progress at milestones
    func announceProgress(distance: Double, speed: Double, duration: TimeInterval) {
        guard isEnabled else { return }
        
        // Check if we should announce based on distance milestone
        let distanceInMiles = distance / 1609.34 // Convert meters to miles
        let shouldAnnounce = distanceInMiles - lastAnnouncedDistance >= announcementInterval
        
        if shouldAnnounce {
            lastAnnouncedDistance = distanceInMiles
            
            let speedInMph = speed * 2.237 // Convert m/s to mph
            let durationInMinutes = duration / 60
            
            let message = createProgressMessage(
                distance: distanceInMiles,
                speed: speedInMph,
                duration: durationInMinutes
            )
            
            speak(message)
        }
    }
    
    /// Announce ride start
    func announceRideStart() {
        speak("Ride tracking started. Voice assistant is active.")
    }
    
    /// Announce ride pause
    func announceRidePaused() {
        speak("Ride paused.")
    }
    
    /// Announce ride resume
    func announceRideResumed() {
        speak("Resuming ride.")
    }
    
    /// Announce ride end with summary
    func announceRideEnd(distance: Double, duration: TimeInterval, averageSpeed: Double) {
        let distanceInMiles = distance / 1609.34
        let durationInMinutes = duration / 60
        let speedInMph = averageSpeed * 2.237
        
        let message = String(format: "Ride finished. Total distance: %.1f miles in %.0f minutes. Average speed: %.1f miles per hour.",
                            distanceInMiles, durationInMinutes, speedInMph)
        
        speak(message)
    }
    
    /// Announce current status
    func announceStatus(distance: Double, speed: Double, duration: TimeInterval) {
        let distanceInMiles = distance / 1609.34
        let speedInMph = speed * 2.237
        let durationInMinutes = duration / 60
        
        let message = String(format: "Current status: %.1f miles, %.1f miles per hour, %.0f minutes elapsed.",
                            distanceInMiles, speedInMph, durationInMinutes)
        
        speak(message)
    }
    
    /// Stop any current speech
    func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
    
    // MARK: - Private Methods
    
    private func createProgressMessage(distance: Double, speed: Double, duration: Double) -> String {
        let roundedDistance = round(distance * 10) / 10 // Round to 1 decimal place
        let roundedSpeed = round(speed * 10) / 10
        let roundedDuration = round(duration)
        
        if roundedDistance.truncatingRemainder(dividingBy: 1.0) == 0 {
            // Whole mile milestone
            return String(format: "You've completed %.0f miles in %.0f minutes — keep it up! Current speed: %.1f miles per hour.",
                        roundedDistance, roundedDuration, roundedSpeed)
        } else {
            // Half mile milestone
            return String(format: "You've reached %.1f miles. Current speed: %.1f miles per hour.",
                        roundedDistance, roundedSpeed)
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension VoiceAssistantService: @preconcurrency AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = true
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = false
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = false
        }
    }
}
