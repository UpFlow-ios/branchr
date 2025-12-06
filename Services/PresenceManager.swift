//
//  PresenceManager.swift
//  branchr
//
//  Created by Joseph Dormond on 2025-11-06
//  Phase 34 - Online Presence Manager
//

import SwiftUI
import FirebaseAuth

/**
 * 🟢 Presence Manager
 *
 * Manages user online/offline status for UI indicators.
 * Wraps FirebaseService for easy access to online status.
 */
@MainActor
class PresenceManager: ObservableObject {
    static let shared = PresenceManager()
    
    @Published var isOnline: Bool = false
    
    private init() {
        // Check initial online status from Firebase
        if let uid = Auth.auth().currentUser?.uid {
            FirebaseService.shared.fetchUserProfile(userID: uid) { [weak self] profile in
                DispatchQueue.main.async {
                    self?.isOnline = profile?.isOnline ?? false
                }
            }
        }
    }
    
    /// Update online status (only if user is signed in)
    func setOnline(_ online: Bool) {
        // Only update if user is signed in
        guard Auth.auth().currentUser != nil else {
            print("⚠️ PresenceManager: Cannot set online status - no user signed in")
            isOnline = false
            return
        }
        
        isOnline = online
        FirebaseService.shared.setUserOnlineStatus(isOnline: online)
    }
}

