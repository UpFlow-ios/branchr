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
    
    @Published var darkModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(darkModeEnabled, forKey: "darkModeEnabled")
            print("Branchr: Dark mode preference updated: \(darkModeEnabled)")
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
