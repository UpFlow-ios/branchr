//
//  VoiceFeedbackService.swift
//  branchr
//
//  Created by Joseph Dormond on 2025-11-04
//  Phase 31 - Unified Voice Feedback Service
//  Phase 53 - Hardened with debounce + safe concurrency
//

import Foundation
import AVFoundation

/**
 * 🗣️ Voice Feedback Service
 *
 * Provides simple text-to-speech functionality for ride tracking announcements.
 * Wraps AVSpeechSynthesizer for easy use throughout the app.
 * Phase 34E: Ensures audio session is properly configured for playback.
 * Phase 39: Added queue/debounce to prevent overlapping speech and track speech state.
 * Phase 53: Hardened with serial queue, improved debounce (8s), and safe concurrency.
 */
final class VoiceFeedbackService: NSObject, ObservableObject {
    static let shared = VoiceFeedbackService()
    
    private let synthesizer = AVSpeechSynthesizer()
    private let session = AVAudioSession.sharedInstance()
    private let speechQueue = DispatchQueue(label: "com.branchr.voiceFeedback")
    
    // Phase 53: Speech state tracking with improved debounce
    private var isSpeaking = false
    private var lastSpokenAt: Date?
    private let debounceInterval: TimeInterval = 8.0 // Phase 53: 8 second debounce
    
    private override init() {
        super.init()
        synthesizer.delegate = self
        print("Branchr VoiceFeedbackService: Initialized")
    }
    
    /// Speak a text message (with debounce and safe concurrency)
    /// - Parameters:
    ///   - text: Text to speak
    ///   - force: Force speech even if debounced
    ///   - isSafetyAlert: If true, checks voiceSafetyAlerts setting before speaking
    func speak(_ text: String, force: Bool = false, isSafetyAlert: Bool = false) {
        speechQueue.async { [weak self] in
            guard let self else { return }
            
            // Check if safety alerts are disabled
            if isSafetyAlert && !UserDefaults.standard.bool(forKey: "voiceSafetyAlerts") {
                print("Branchr VoiceFeedbackService: Safety alerts disabled, skipping: \(text)")
                return
            }
            
            // Phase 53: Validate text is not empty
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                print("Branchr VoiceFeedbackService: Attempted to speak empty text, ignoring")
                return
            }
            
            // Phase 53: Debounce - prevent rapid-fire speech (8 second interval)
            let now = Date()
            if !force, let last = self.lastSpokenAt, now.timeIntervalSince(last) < self.debounceInterval {
                print("Branchr VoiceFeedbackService: Debounced phrase: \(text)")
                return
            }
            self.lastSpokenAt = now
            
            // Phase 53: Stop any current speech before starting new
            if self.isSpeaking {
                self.synthesizer.stopSpeaking(at: .immediate)
                self.isSpeaking = false
            }
            
            // Phase 53: Configure audio session safely
            do {
                try self.session.setCategory(
                    .playback,
                    mode: .voicePrompt,
                    options: [.mixWithOthers]
                )
                try self.session.setActive(true)
                self.logSessionState(context: "speak-start")
            } catch {
                print("Branchr VoiceFeedbackService: Failed to activate session: \(error)")
                self.logSessionState(context: "error-activate")
                return
            }
            
            // Phase 53: Create and speak utterance
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
            utterance.volume = 0.8
            
            guard !utterance.speechString.isEmpty else {
                print("Branchr VoiceFeedbackService: Utterance has empty speech string, skipping")
                return
            }
            
            self.isSpeaking = true
            self.synthesizer.speak(utterance)
            print("Branchr VoiceFeedbackService: Speaking: \(text)")
        }
    }
    
    /// Stop current speech
    func stop() {
        speechQueue.async { [weak self] in
            guard let self else { return }
            self.synthesizer.stopSpeaking(at: .immediate)
            self.isSpeaking = false
            
            do {
                try self.session.setActive(false, options: [.notifyOthersOnDeactivation])
                self.logSessionState(context: "stop")
            } catch {
                print("Branchr VoiceFeedbackService: Failed to deactivate session: \(error)")
                self.logSessionState(context: "error-deactivate")
            }
        }
    }
    
    /// Check if currently speaking
    var currentlySpeaking: Bool {
        return isSpeaking
    }
    
    // MARK: - Phase 53: Audio Session Debug Logging
    
    /// Log current audio session state for debugging
    private func logSessionState(context: String) {
        let category = session.category.rawValue
        let mode = session.mode.rawValue
        let route = session.currentRoute.outputs.map { $0.portType.rawValue }.joined(separator: ",")
        let otherAudio = session.secondaryAudioShouldBeSilencedHint
        
        print("Branchr VoiceFeedbackService [\(context)] – category=\(category), mode=\(mode), route=\(route), otherAudioShouldBeSilenced=\(otherAudio)")
    }
}

// MARK: - Phase 53: AVSpeechSynthesizerDelegate (Safe Concurrency)

extension VoiceFeedbackService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        speechQueue.async { [weak self] in
            guard let self else { return }
            self.isSpeaking = false
            
            do {
                try self.session.setActive(false, options: [.notifyOthersOnDeactivation])
                self.logSessionState(context: "speak-finished")
            } catch {
                print("Branchr VoiceFeedbackService: Failed to deactivate session: \(error)")
                self.logSessionState(context: "error-deactivate")
            }
        }
    }
    
    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        speechQueue.async { [weak self] in
            guard let self else { return }
            self.isSpeaking = false
            
            do {
                try self.session.setActive(false, options: [.notifyOthersOnDeactivation])
                self.logSessionState(context: "speak-cancelled")
            } catch {
                print("Branchr VoiceFeedbackService: Failed to deactivate session after cancel: \(error)")
                self.logSessionState(context: "error-deactivate-cancel")
            }
        }
    }
}

