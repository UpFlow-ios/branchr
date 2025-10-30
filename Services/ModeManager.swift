//
//  ModeManager.swift
//  Branchr
//
//  Created by Joe Dormond on 2025-10-24.
//

import Foundation
import Combine
import SwiftUI

final class ModeManager: ObservableObject {
    static let shared = ModeManager()
    
    @Published var activeMode: BranchrMode
    @Published var configuration: ModeConfiguration
    
    private let modeKey = "branchrActiveMode"
    private let appGroupID = "group.com.joedormond.branchr"
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Initialize cancellables first
        cancellables = Set<AnyCancellable>()
        
        // Load saved mode or default from App Groups
        let defaults = UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard
        let initialMode: BranchrMode
        if let saved = defaults.string(forKey: modeKey),
           let savedMode = BranchrMode(rawValue: saved) {
            initialMode = savedMode
        } else {
            initialMode = .ride
        }
        
        // Initialize stored properties
        activeMode = initialMode
        configuration = ModeConfiguration.preset(for: initialMode)
        
        // Setup auto-save when changed (after initialization)
        setupModeChangeObserver()
    }
    
    private func setupModeChangeObserver() {
        $activeMode
            .sink { [weak self] mode in
                guard let self = self else { return }
                
                // Save to App Groups for widget access
                let defaults = UserDefaults(suiteName: self.appGroupID) ?? UserDefaults.standard
                defaults.set(mode.rawValue, forKey: self.modeKey)
                
                // Update configuration and notify
                self.configuration = ModeConfiguration.preset(for: mode)
                NotificationCenter.default.post(name: .branchrModeChanged, object: mode)
                print("🌐 Branchr mode changed to \(mode.rawValue.capitalized)")
            }
            .store(in: &cancellables)
    }
    
    func setMode(_ mode: BranchrMode) {
        activeMode = mode
    }
}

extension Notification.Name {
    static let branchrModeChanged = Notification.Name("branchrModeChanged")
}
