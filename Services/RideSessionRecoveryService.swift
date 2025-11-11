//
//  RideSessionRecoveryService.swift
//  branchr
//
//  Created for Phase 35 - Session Recovery System
//

import Foundation
import CoreLocation

/**
 * 🔄 Ride Session Recovery Service
 *
 * Handles saving and restoring ride sessions when the app closes or crashes.
 * Saves ride state to UserDefaults for recovery on next launch.
 */
@MainActor
final class RideSessionRecoveryService {
    static let shared = RideSessionRecoveryService()
    
    private let defaults = UserDefaults.standard
    private let rideStateKey = "branchr.recoveredRideState"
    private let rideDataKey = "branchr.recoveredRideData"
    
    private init() {
        print("🔄 RideSessionRecoveryService initialized")
    }
    
    // MARK: - Save Session
    
    /// Save current ride state for recovery
    func saveSession(
        state: RideSessionState,
        distance: Double,
        duration: TimeInterval,
        route: [CLLocationCoordinate2D],
        startTime: Date?,
        pausedTime: TimeInterval,
        isGroupRide: Bool,
        groupRideId: String?
    ) {
        guard state == .active || state == .paused else {
            // Clear recovery data if ride is ended or idle
            clearSession()
            return
        }
        
        let routeData = route.map { ["lat": $0.latitude, "lon": $0.longitude] }
        
        let sessionData: [String: Any] = [
            "state": state == .active ? "active" : "paused",
            "distance": distance,
            "duration": duration,
            "route": routeData,
            "startTime": startTime?.timeIntervalSince1970 ?? 0,
            "pausedTime": pausedTime,
            "isGroupRide": isGroupRide,
            "groupRideId": groupRideId ?? "",
            "savedAt": Date().timeIntervalSince1970
        ]
        
        defaults.set(sessionData, forKey: rideDataKey)
        defaults.set(true, forKey: rideStateKey)
        
        print("💾 Saved ride session for recovery: \(state)")
    }
    
    // MARK: - Restore Session
    
    /// Check if there's a recoverable session
    func hasRecoverableSession() -> Bool {
        return defaults.bool(forKey: rideStateKey) && defaults.object(forKey: rideDataKey) != nil
    }
    
    /// Restore ride session data
    func restoreSession() -> RecoveredRideSession? {
        guard let data = defaults.dictionary(forKey: rideDataKey) else {
            return nil
        }
        
        guard let stateString = data["state"] as? String,
              let distance = data["distance"] as? Double,
              let duration = data["duration"] as? TimeInterval,
              let routeData = data["route"] as? [[String: Double]],
              let startTimeInterval = data["startTime"] as? TimeInterval,
              let pausedTime = data["pausedTime"] as? TimeInterval,
              let isGroupRide = data["isGroupRide"] as? Bool,
              let groupRideId = data["groupRideId"] as? String,
              let savedAt = data["savedAt"] as? TimeInterval else {
            clearSession()
            return nil
        }
        
        // Check if session is too old (more than 24 hours)
        let savedDate = Date(timeIntervalSince1970: savedAt)
        if Date().timeIntervalSince(savedDate) > 86400 {
            clearSession()
            return nil
        }
        
        let state: RideSessionState = stateString == "active" ? .active : .paused
        let startTime = startTimeInterval > 0 ? Date(timeIntervalSince1970: startTimeInterval) : nil
        
        let route = routeData.compactMap { coordDict -> CLLocationCoordinate2D? in
            guard let lat = coordDict["lat"], let lon = coordDict["lon"] else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        
        return RecoveredRideSession(
            state: state,
            distance: distance,
            duration: duration,
            route: route,
            startTime: startTime,
            pausedTime: pausedTime,
            isGroupRide: isGroupRide,
            groupRideId: groupRideId.isEmpty ? nil : groupRideId
        )
    }
    
    // MARK: - Clear Session
    
    /// Clear saved session data
    func clearSession() {
        defaults.removeObject(forKey: rideStateKey)
        defaults.removeObject(forKey: rideDataKey)
        print("🗑️ Cleared ride session recovery data")
    }
}

// MARK: - Recovered Ride Session Model

struct RecoveredRideSession {
    let state: RideSessionState
    let distance: Double
    let duration: TimeInterval
    let route: [CLLocationCoordinate2D]
    let startTime: Date?
    let pausedTime: TimeInterval
    let isGroupRide: Bool
    let groupRideId: String?
}

