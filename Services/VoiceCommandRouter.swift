//
//  VoiceCommandRouter.swift
//  branchr
//
//  Created for Phase 34H - Voice Command Router
//

import Foundation
import UIKit

/**
 * 🎤 Voice Command Router
 *
 * Simple router that listens for transcribed phrases and dispatches actions.
 * Handles wake words ("hey Branchr") and music/ride commands.
 */
final class VoiceCommandRouter {
    
    static let shared = VoiceCommandRouter()
    
    private init() {
        print("🎤 VoiceCommandRouter initialized")
    }
    
    /// Handle a recognized voice command transcript
    func handleCommand(_ transcript: String) {
        let lower = transcript.lowercased()
        
        // Check for wake word
        guard lower.contains("hey branchr") ||
              lower.contains("hey bracher") ||
              lower.contains("hey stryvr") ||
              lower.contains("hey branch") else {
            // No wake word, but still check for direct commands (for ride tracking)
            handleDirectCommand(lower)
            return
        }
        
        // Wake word detected - play confirmation sound
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        Task { @MainActor in
            await VoiceFeedbackService.shared.speak("Yes?")
        }
        
        // Music playback commands
        if lower.contains("play") {
            if let artist = extractArtistName(from: lower) {
                MusicSyncService.shared.playArtist(artist)
            } else {
                MusicSyncService.shared.resumeCurrentTrack()
            }
        }
        
        // Pause / stop commands
        else if lower.contains("pause") || lower.contains("stop") {
            if lower.contains("music") || lower.contains("song") {
                MusicSyncService.shared.pausePlayback()
            } else {
                // Default to music pause if context unclear
                MusicSyncService.shared.pausePlayback()
            }
        }
        
        // Skip / next track
        else if lower.contains("next") || lower.contains("skip") {
            MusicSyncService.shared.nextTrack()
        }
        
        // Status update
        else if lower.contains("status") {
            Task { @MainActor in
                await VoiceFeedbackService.shared.speak("Ride tracking active and music playing")
            }
        }
        
        // Phase 34I: Ride tracking control via RideSessionManager
        else if lower.contains("start ride") || lower.contains("start ride tracking") {
            Task { @MainActor in
                RideSessionManager.shared.startSoloRide()
                await VoiceFeedbackService.shared.speak("Ride started")
            }
        }
        else if lower.contains("pause ride") || lower.contains("pause ride tracking") {
            Task { @MainActor in
                RideSessionManager.shared.pauseRide()
                await VoiceFeedbackService.shared.speak("Ride paused")
            }
        }
        else if lower.contains("resume ride") || lower.contains("resume ride tracking") {
            Task { @MainActor in
                RideSessionManager.shared.resumeRide()
                await VoiceFeedbackService.shared.speak("Ride resumed")
            }
        }
        else if lower.contains("stop ride") || lower.contains("stop ride tracking") || lower.contains("end ride") {
            Task { @MainActor in
                // Phase 35.3: Instant stop
                RideSessionManager.shared.endRide()
                await VoiceFeedbackService.shared.speak("Ride stopped, saved to calendar")
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
    
    /// Handle direct commands without wake word (for ride tracking)
    private func handleDirectCommand(_ text: String) {
        // Phase 34I: Direct ride commands work without wake word
        if text.contains("start ride") || text.contains("start ride tracking") {
            Task { @MainActor in
                RideSessionManager.shared.startSoloRide()
                await VoiceFeedbackService.shared.speak("Ride started")
            }
        } else if text.contains("pause tracking") || text.contains("pause ride") {
            Task { @MainActor in
                RideSessionManager.shared.pauseRide()
                await VoiceFeedbackService.shared.speak("Ride paused")
            }
        } else if text.contains("resume ride") || text.contains("resume tracking") {
            Task { @MainActor in
                RideSessionManager.shared.resumeRide()
                await VoiceFeedbackService.shared.speak("Ride resumed")
            }
        } else if text.contains("stop ride") || text.contains("end ride") || text.contains("stop tracking") {
            Task { @MainActor in
                // Phase 35.3: Instant stop
                RideSessionManager.shared.endRide()
                await VoiceFeedbackService.shared.speak("Ride stopped, saved to calendar")
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
    
    /// Extract artist name from "play [artist]" command
    private func extractArtistName(from text: String) -> String? {
        let tokens = text.components(separatedBy: " ")
        guard let playIndex = tokens.firstIndex(of: "play"), playIndex < tokens.count - 1 else { return nil }
        
        // Extract everything after "play" until end or next command word
        let commandWords = ["pause", "stop", "next", "skip", "status"]
        var artistTokens: [String] = []
        
        for i in (playIndex + 1)..<tokens.count {
            let token = tokens[i]
            if commandWords.contains(token) {
                break
            }
            artistTokens.append(token)
        }
        
        let artist = artistTokens.joined(separator: " ").trimmingCharacters(in: .whitespaces)
        return artist.isEmpty ? nil : artist
    }
}

// MARK: - Phase 35B: Notification Names


