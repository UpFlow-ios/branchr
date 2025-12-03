//
//  MusicKitService.swift
//  branchr
//
//  Created by Joseph Dormond on 2025-01-27
//  Phase 61 - MusicKit Re-enabled
//  Phase 62 - Observable authorization status tracking
//

import Foundation
import MusicKit  // Phase 61: Re-enabled

/**
 * 🎵 MusicKitService
 *
 * Validates MusicKit access and authorization status
 * Phase 61: Re-enabled with proper MusicKit integration
 * Phase 62: Observable status tracking for UI
 */
@MainActor
final class MusicKitService: ObservableObject {
    static let shared = MusicKitService()
    
    // Phase 62: Published authorization status for UI observation
    @Published private(set) var authorizationStatus: MusicAuthorization.Status = .notDetermined
    
    private init() {
        print("🎵 Branchr MusicKitService: Initialized")
        // Phase 62: Initialize status on creation
        Task {
            await refreshAuthorizationStatus(requestIfNeeded: false)
        }
    }
    
    /**
     * ✅ Validate MusicKit Access
     *
     * Checks MusicKit authorization status and logs result
     * Phase 61: Re-enabled with proper authorization check
     */
    static func validateMusicKitAccess() {
        Task { @MainActor in
            await MusicKitService.shared.refreshAuthorizationStatus(requestIfNeeded: false)
        }
    }
    
    /**
     * Phase 62: Refresh authorization status
     *
     * Reads current authorization and optionally requests it
     * Updates authorizationStatus on the main actor
     */
    func refreshAuthorizationStatus(requestIfNeeded: Bool = false) async {
        let current = MusicAuthorization.currentStatus
        
        if requestIfNeeded && current == .notDetermined {
            let result = await MusicAuthorization.request()
            self.authorizationStatus = result
            logAuthorizationStatus(result, requested: true)
        } else {
            self.authorizationStatus = current
            logAuthorizationStatus(current, requested: false)
        }
    }
    
    // Phase 62: Helper to log authorization status
    private func logAuthorizationStatus(_ status: MusicAuthorization.Status, requested: Bool) {
        let action = requested ? "request result" : "status"
        switch status {
        case .authorized:
            print("✅ Branchr MusicKitService: MusicKit authorization \(action): authorized")
        case .denied:
            print("⚠️ Branchr MusicKitService: MusicKit authorization \(action): denied")
        case .notDetermined:
            print("🟡 Branchr MusicKitService: MusicKit authorization \(action): not yet requested")
        case .restricted:
            print("⚠️ Branchr MusicKitService: MusicKit authorization \(action): restricted")
        @unknown default:
            print("⚠️ Branchr MusicKitService: MusicKit authorization \(action): unknown")
        }
    }
}
