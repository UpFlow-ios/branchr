//
//  RideTrackingService.swift
//  branchr
//
//  Created by Joseph Dormond on 2025-11-03
//  Phase 20 - Complete Ride Tracking System
//

import Foundation
import CoreLocation
import Combine
import SwiftUI

/**
 * 🚴‍♂️ Ride State
 *
 * Represents the current state of a ride tracking session.
 */
enum RideState {
    case idle      // No ride active
    case active    // Ride is currently being tracked
    case paused    // Ride is paused (user can resume or end)
    case ended     // Ride has been completed
    
    // Phase 35A: Button title and color
    var buttonTitle: String {
        switch self {
        case .idle, .ended: return "Start Ride Tracking"
        case .active: return "Pause Ride Tracking"
        case .paused: return "Resume Ride Tracking"
        }
    }
    
    var buttonColor: Color {
        switch self {
        case .idle, .ended: return .green
        case .active: return .red
        case .paused: return .orange
        }
    }
}

/**
 * 🚴‍♂️ RideTrackingService
 *
 * Handles complete ride tracking functionality including:
 * - GPS route tracking using CoreLocation
 * - Ride state management (Idle, Active, Paused, Ended)
 * - Statistics calculation (distance, duration, speed)
 * - Route coordinate storage
 */
@MainActor
final class RideTrackingService: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    // MARK: - Phase 35A: Shared Singleton
    static let shared = RideTrackingService()
    
    // MARK: - Published Properties
    
    @Published var rideState: RideState = .idle
    @Published var totalDistance: Double = 0.0 // in meters
    @Published var duration: TimeInterval = 0 // in seconds
    @Published var route: [CLLocationCoordinate2D] = []
    @Published var averageSpeed: Double = 0.0 // in km/h
    @Published var currentSpeed: Double = 0.0 // in km/h
    
    // MARK: - Private Properties
    
    private var locationManager = CLLocationManager()
    private var startTime: Date?
    private var pausedTime: TimeInterval = 0.0
    private var lastPauseTime: Date?
    private var timer: Timer?
    private var lastLocation: CLLocation?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Background Location Helper
    
    /// Check if the app has background location capability configured
    private func hasBackgroundLocationCapability() -> Bool {
        guard let modes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] else {
            return false
        }
        return modes.contains("location")
    }
    
    /// Safely configure allowsBackgroundLocationUpdates based on capability and authorization
    private func configureBackgroundLocationUpdates(authStatus: CLAuthorizationStatus) {
        #if targetEnvironment(simulator)
        // Simulator cannot be made backgroundable, keep this off
        locationManager.allowsBackgroundLocationUpdates = false
        print("📍 RideTrackingService: Background location updates DISABLED (simulator)")
        #else
        if hasBackgroundLocationCapability() && authStatus == .authorizedAlways {
            locationManager.allowsBackgroundLocationUpdates = true
            print("📍 RideTrackingService: Background location updates ENABLED")
        } else {
            locationManager.allowsBackgroundLocationUpdates = false
            if !hasBackgroundLocationCapability() {
                print("📍 RideTrackingService: Background location updates DISABLED (no UIBackgroundModes 'location')")
            } else {
                print("📍 RideTrackingService: Background location updates DISABLED (not authorizedAlways)")
            }
        }
        #endif
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5.0 // Update every 5 meters
        locationManager.pausesLocationUpdatesAutomatically = false
        
        // IMPORTANT: Only enable background updates if the app is actually configured
        // for background location in Info.plist / Capabilities.
        let authStatus = locationManager.authorizationStatus
        configureBackgroundLocationUpdates(authStatus: authStatus)
    }
    
    // MARK: - Public Methods
    
    /**
     * 🚴 Start Ride Tracking
     *
     * Initiates a new ride tracking session.
     * Requests location permissions and starts GPS tracking.
     */
    func startRide() {
        guard rideState == .idle || rideState == .ended else {
            print("⚠️ Cannot start ride - already in progress")
            return
        }
        
        // Reset tracking data
        totalDistance = 0.0
        duration = 0.0
        route.removeAll()
        pausedTime = 0.0
        lastLocation = nil
        
        // Request location authorization if needed
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            // Wait for authorization callback before starting
            return
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            // Update background location setting based on capability and permission
            configureBackgroundLocationUpdates(authStatus: status)
            
            rideState = .active
            startTime = Date()
            locationManager.startUpdatingLocation()
            startTimer()
            print("🚴 Ride started")
        } else {
            print("⚠️ Location permission not granted")
        }
    }
    
    /**
     * ⏸ Pause Ride
     *
     * Pauses the current ride tracking session.
     * User can later resume or end the ride.
     */
    func pauseRide() {
        guard rideState == .active else { return }
        
        rideState = .paused
        locationManager.stopUpdatingLocation()
        stopTimer()
        lastPauseTime = Date()
        print("⏸ Ride paused")
    }
    
    /**
     * ▶️ Resume Ride
     *
     * Resumes a paused ride tracking session.
     */
    func resumeRide() {
        guard rideState == .paused else { return }
        
        // Calculate paused time
        if let pauseStart = lastPauseTime {
            pausedTime += Date().timeIntervalSince(pauseStart)
            lastPauseTime = nil
        }
        
        rideState = .active
        locationManager.startUpdatingLocation()
        startTimer()
        print("▶️ Ride resumed")
    }
    
    /**
     * 🏁 End Ride
     *
     * Ends the current ride tracking session.
     * Call this when user wants to finish and view summary.
     */
    func endRide() {
        guard rideState == .active || rideState == .paused else { return }
        
        rideState = .ended
        locationManager.stopUpdatingLocation()
        stopTimer()
        
        // Calculate final duration
        if let start = startTime {
            duration = Date().timeIntervalSince(start) - pausedTime
        }
        
        // Calculate final average speed
        if duration > 0 {
            averageSpeed = (totalDistance / duration) * 3.6 // m/s to km/h
        }
        
        print("🏁 Ride ended - Distance: \(String(format: "%.2f", totalDistance/1000)) km, Duration: \(formatTime(duration))")
    }
    
    /**
     * 🔄 Reset Ride
     *
     * Resets all tracking data and returns to idle state.
     */
    func resetRide() {
        rideState = .idle
        totalDistance = 0.0
        duration = 0.0
        route.removeAll()
        pausedTime = 0.0
        startTime = nil
        lastPauseTime = nil
        lastLocation = nil
        averageSpeed = 0.0
        currentSpeed = 0.0
        print("🔄 Ride reset")
    }
    
    // MARK: - Private Methods
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.startTime else { return }
            self.duration = Date().timeIntervalSince(start) - self.pausedTime
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard rideState == .active, let newLocation = locations.last else { return }
        
        // Filter out invalid locations
        guard newLocation.horizontalAccuracy > 0 && newLocation.horizontalAccuracy < 50 else {
            return
        }
        
        // Calculate distance from last location
        if let last = lastLocation {
            let distance = newLocation.distance(from: last)
            totalDistance += distance
            
            // Calculate current speed (m/s to km/h)
            currentSpeed = newLocation.speed >= 0 ? newLocation.speed * 3.6 : 0.0
        }
        
        // Add to route
        route.append(newLocation.coordinate)
        lastLocation = newLocation
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            print("❌ Location error: \(error.localizedDescription)")
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        
        // Update background location updates based on capability and permission level
        configureBackgroundLocationUpdates(authStatus: status)
        
        switch status {
        case .authorizedAlways:
            print("✅ Location permission: Always")
        case .authorizedWhenInUse:
            print("✅ Location permission: When In Use (foreground only)")
        case .denied, .restricted:
            print("⚠️ Location permission denied or restricted")
        case .notDetermined:
            print("📍 Location permission: Not determined")
        @unknown default:
            print("⚠️ Location permission: Unknown status")
        }
        
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            if rideState == .idle && startTime == nil {
                // User just granted permission, start tracking if needed
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /**
     * Format time interval as HH:MM:SS
     */
    func formatTime(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    /**
     * Get distance in kilometers
     */
    var distanceInKilometers: Double {
        totalDistance / 1000.0
    }
    
    /**
     * Get formatted distance string
     */
    var formattedDistance: String {
        String(format: "%.2f km", distanceInKilometers)
    }
    
    /**
     * Get formatted average speed
     */
    var formattedAverageSpeed: String {
        String(format: "%.1f km/h", averageSpeed)
    }
    
    // MARK: - Phase 4: Rider Info Helper Methods
    
    /**
     * Get speed for a specific rider (in mph)
     * Phase 4: Placeholder - returns current speed for now
     */
    func speedFor(riderID: String) -> Double {
        // Phase 4: In a full implementation, this would look up the rider's speed
        // For now, return current speed converted to mph
        return currentSpeed * 0.621371 // km/h to mph
    }
    
    /**
     * Get distance from host for a specific rider (in miles)
     * Phase 4: Placeholder - returns 0 for now
     */
    func distanceFromHost(riderID: String) -> Double {
        // Phase 4: In a full implementation, this would calculate distance
        // between the rider's location and the host's location
        // For now, return 0 as placeholder
        return 0.0
    }
    
    // MARK: - Phase 5: HUD Helper Methods
    
    /**
     * Get total distance in miles
     * Phase 5: Converts meters to miles
     */
    var totalDistanceMiles: Double {
        return totalDistance / 1609.34 // meters to miles
    }
    
    /**
     * Get current speed in mph
     * Phase 5: Converts km/h to mph
     */
    var currentSpeedMph: Double {
        return currentSpeed * 0.621371 // km/h to mph
    }
    
    /**
     * Get formatted duration string
     * Phase 5: Formats seconds into m:ss or h:mm:ss
     */
    var formattedDuration: String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

