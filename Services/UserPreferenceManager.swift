//
//  UserPreferenceManager.swift
//  branchr
//
//  Created by Joe Dormond on 10/23/25.
//

import Foundation
import SwiftUI

/// Singleton service for managing user preferences and settings
/// Persists settings using UserDefaults and provides reactive updates
@MainActor
class UserPreferenceManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = UserPreferenceManager()
    
    // MARK: - Published Properties
    @Published var voiceAssistantEnabled: Bool {
        didSet {
            UserDefaults.standard.set(voiceAssistantEnabled, forKey: "voiceAssistantEnabled")
            print("Branchr: Voice assistant preference updated: \(voiceAssistantEnabled)")
        }
    }
    
    @Published var voiceCommandsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(voiceCommandsEnabled, forKey: "voiceCommandsEnabled")
            print("Branchr: Voice commands preference updated: \(voiceCommandsEnabled)")
        }
    }
    
    @Published var audioAnnouncementsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(audioAnnouncementsEnabled, forKey: "audioAnnouncementsEnabled")
            print("Branchr: Audio announcements preference updated: \(audioAnnouncementsEnabled)")
        }
    }
    
    @Published var musicSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(musicSyncEnabled, forKey: "musicSyncEnabled")
            print("Branchr: Music sync preference updated: \(musicSyncEnabled)")
        }
    }
    
    @Published var hapticFeedbackEnabled: Bool {
        didSet {
            UserDefaults.standard.set(hapticFeedbackEnabled, forKey: "hapticFeedbackEnabled")
            print("Branchr: Haptic feedback preference updated: \(hapticFeedbackEnabled)")
        }
    }
    
    // Phase 34: Voice announcement settings
    @Published var distanceUpdatesEnabled: Bool {
        didSet {
            UserDefaults.standard.set(distanceUpdatesEnabled, forKey: "distanceUpdatesEnabled")
            print("Branchr: Distance updates preference updated: \(distanceUpdatesEnabled)")
        }
    }
    
    @Published var paceOrSpeedUpdatesEnabled: Bool {
        didSet {
            UserDefaults.standard.set(paceOrSpeedUpdatesEnabled, forKey: "paceOrSpeedUpdatesEnabled")
            print("Branchr: Pace/speed updates preference updated: \(paceOrSpeedUpdatesEnabled)")
        }
    }
    
    @Published var completionSummaryEnabled: Bool {
        didSet {
            UserDefaults.standard.set(completionSummaryEnabled, forKey: "completionSummaryEnabled")
            print("Branchr: Completion summary preference updated: \(completionSummaryEnabled)")
        }
    }
    
    @Published var darkModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(darkModeEnabled, forKey: "darkModeEnabled")
            print("Branchr: Dark mode preference updated: \(darkModeEnabled)")
        }
    }
    
    // Phase 39: Voice Coach ride updates
    @Published var voiceCoachEnabled: Bool {
        didSet {
            UserDefaults.standard.set(voiceCoachEnabled, forKey: "voiceCoachEnabled")
            print("Branchr: Voice Coach preference updated: \(voiceCoachEnabled)")
        }
    }
    
    // Phase 40: Preferred calendar for ride events
    @Published var preferredCalendarIdentifier: String? {
        didSet {
            UserDefaults.standard.set(preferredCalendarIdentifier, forKey: "preferredCalendarIdentifier")
            print("Branchr: Preferred calendar identifier updated: \(preferredCalendarIdentifier ?? "nil")")
        }
    }
    
    // Phase 41: Weekly distance goal in miles
    @Published var weeklyDistanceGoalMiles: Double {
        didSet {
            UserDefaults.standard.set(weeklyDistanceGoalMiles, forKey: "weeklyDistanceGoalMiles")
            print("Branchr: Weekly distance goal updated: \(String(format: "%.1f", weeklyDistanceGoalMiles)) mi")
        }
    }
    
    // Phase 51: Preferred music source mode
    @Published var preferredMusicSource: MusicSourceMode {
        didSet {
            UserDefaults.standard.set(preferredMusicSource.rawValue, forKey: "preferredMusicSource")
            print("Branchr UserPreferenceManager: preferredMusicSource set to \(preferredMusicSource.title)")
        }
    }
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Initialization
    private init() {
        // Load preferences from UserDefaults with default values
        self.voiceAssistantEnabled = userDefaults.object(forKey: "voiceAssistantEnabled") as? Bool ?? true
        self.voiceCommandsEnabled = userDefaults.object(forKey: "voiceCommandsEnabled") as? Bool ?? true
        self.audioAnnouncementsEnabled = userDefaults.object(forKey: "audioAnnouncementsEnabled") as? Bool ?? true
        self.musicSyncEnabled = userDefaults.object(forKey: "musicSyncEnabled") as? Bool ?? true
        self.hapticFeedbackEnabled = userDefaults.object(forKey: "hapticFeedbackEnabled") as? Bool ?? true
        self.darkModeEnabled = userDefaults.object(forKey: "darkModeEnabled") as? Bool ?? false
        // Phase 34: Voice announcement settings (default ON)
        self.distanceUpdatesEnabled = userDefaults.object(forKey: "distanceUpdatesEnabled") as? Bool ?? true
        self.paceOrSpeedUpdatesEnabled = userDefaults.object(forKey: "paceOrSpeedUpdatesEnabled") as? Bool ?? true
        self.completionSummaryEnabled = userDefaults.object(forKey: "completionSummaryEnabled") as? Bool ?? true
        // Phase 39: Voice Coach (default ON)
        self.voiceCoachEnabled = userDefaults.object(forKey: "voiceCoachEnabled") as? Bool ?? true
        // Phase 40: Preferred calendar (default nil - uses system default)
        self.preferredCalendarIdentifier = userDefaults.string(forKey: "preferredCalendarIdentifier")
        // Phase 41: Weekly distance goal (default 25.0 miles)
        // Phase 74: Increased default to 75.0 miles for more realistic weekly pacing
        self.weeklyDistanceGoalMiles = userDefaults.object(forKey: "weeklyDistanceGoalMiles") as? Double ?? 75.0
        // Phase 51: Preferred music source (default Apple Music Synced)
        if let rawValue = userDefaults.string(forKey: "preferredMusicSource"),
           let source = MusicSourceMode(rawValue: rawValue) {
            self.preferredMusicSource = source
        } else {
            self.preferredMusicSource = .appleMusicSynced
        }
        
        print("Branchr UserPreferenceManager initialized")
        print("Branchr: Voice assistant enabled: \(voiceAssistantEnabled)")
        print("Branchr: Voice commands enabled: \(voiceCommandsEnabled)")
        print("Branchr: Audio announcements enabled: \(audioAnnouncementsEnabled)")
    }
    
    // MARK: - Public Methods
    
    /// Reset all preferences to default values
    func resetToDefaults() {
        voiceAssistantEnabled = true
        voiceCommandsEnabled = true
        audioAnnouncementsEnabled = true
        musicSyncEnabled = true
        hapticFeedbackEnabled = true
        darkModeEnabled = false
        voiceCoachEnabled = true // Phase 39
        preferredCalendarIdentifier = nil // Phase 40: Reset to system default
        weeklyDistanceGoalMiles = 25.0 // Phase 41: Reset to default goal
        preferredMusicSource = .appleMusicSynced // Phase 51: Reset to default
        
        print("Branchr: All preferences reset to defaults")
    }
    
    /// Get a specific preference value
    func getPreference<T>(for key: String, defaultValue: T) -> T {
        if let value = userDefaults.object(forKey: key) as? T {
            return value
        }
        return defaultValue
    }
    
    /// Set a specific preference value
    func setPreference<T>(_ value: T, for key: String) {
        userDefaults.set(value, forKey: key)
        print("Branchr: Preference '\(key)' set to: \(value)")
    }
    
    /// Check if voice assistant is fully enabled (both voice and commands)
    var isVoiceAssistantFullyEnabled: Bool {
        return voiceAssistantEnabled && voiceCommandsEnabled
    }
    
    /// Check if any audio features are enabled
    var isAnyAudioEnabled: Bool {
        return voiceAssistantEnabled || audioAnnouncementsEnabled || musicSyncEnabled
    }
}
