//
//  UserPreferenceSyncManager.swift
//  branchr
//
//  Created by Joe Dormond on 2025-10-25.
//

import Foundation
import Combine

/// Manages syncing user preferences across devices using App Groups
final class UserPreferenceSyncManager: ObservableObject {
    static let shared = UserPreferenceSyncManager()
    
    private let defaults = UserDefaults(suiteName: "group.com.joedormond.branchr")!
    private var cancellables = Set<AnyCancellable>()
    
    @Published var lastSync: Date? = nil
    
    private init() {
        setupModeSync()
        loadLastSyncDate()
    }
    
    // MARK: - Public Methods
    
    /// Save preferences to App Group for cross-device sync
    func savePreferences(mode: BranchrMode, aiVoice: String = "coach", voiceAssistantEnabled: Bool = true, voiceCommandsEnabled: Bool = true) {
        defaults.set(mode.rawValue, forKey: "branchrActiveMode")
        defaults.set(aiVoice, forKey: "aiVoice")
        defaults.set(voiceAssistantEnabled, forKey: "voiceAssistantEnabled")
        defaults.set(voiceCommandsEnabled, forKey: "voiceCommandsEnabled")
        defaults.set(Date(), forKey: "lastPreferenceSync")
        defaults.synchronize()
        
        lastSync = Date()
        print("💾 Preferences synced to App Group")
    }
    
    /// Load preferences from App Group
    func loadPreferences() -> (BranchrMode, String, Bool, Bool) {
        let modeRaw = defaults.string(forKey: "branchrActiveMode") ?? BranchrMode.ride.rawValue
        let mode = BranchrMode(rawValue: modeRaw) ?? .ride
        let aiVoice = defaults.string(forKey: "aiVoice") ?? "coach"
        let voiceAssistantEnabled = defaults.bool(forKey: "voiceAssistantEnabled")
        let voiceCommandsEnabled = defaults.bool(forKey: "voiceCommandsEnabled")
        
        return (mode, aiVoice, voiceAssistantEnabled, voiceCommandsEnabled)
    }
    
    /// Sync current mode to App Group
    func syncCurrentMode(_ mode: BranchrMode) {
        defaults.set(mode.rawValue, forKey: "branchrActiveMode")
        defaults.set(Date(), forKey: "lastPreferenceSync")
        defaults.synchronize()
        
        lastSync = Date()
        print("💾 Mode synced to App Group: \(mode.displayName)")
    }
    
    /// Sync voice assistant settings
    func syncVoiceSettings(assistantEnabled: Bool, commandsEnabled: Bool) {
        defaults.set(assistantEnabled, forKey: "voiceAssistantEnabled")
        defaults.set(commandsEnabled, forKey: "voiceCommandsEnabled")
        defaults.set(Date(), forKey: "lastPreferenceSync")
        defaults.synchronize()
        
        lastSync = Date()
        print("💾 Voice settings synced to App Group")
    }
    
    /// Check if preferences have been updated from another device
    func checkForUpdates() -> Bool {
        guard let lastSyncData = defaults.object(forKey: "lastPreferenceSync") as? Date else {
            return false
        }
        
        if let currentLastSync = lastSync {
            return lastSyncData > currentLastSync
        }
        
        return true
    }
    
    /// Get the last sync date from App Group
    func getLastSyncDate() -> Date? {
        return defaults.object(forKey: "lastPreferenceSync") as? Date
    }
    
    // MARK: - Private Methods
    
    private func setupModeSync() {
        // Listen for mode changes and sync them
        NotificationCenter.default.publisher(for: .modeChanged)
            .sink { [weak self] notification in
                if let mode = notification.object as? BranchrMode {
                    self?.syncCurrentMode(mode)
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadLastSyncDate() {
        lastSync = getLastSyncDate()
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let modeChanged = Notification.Name("modeChanged")
}
