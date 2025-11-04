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
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5.0 // Update every 5 meters
        locationManager.pausesLocationUpdatesAutomatically = false
        
        // Only enable background location updates if we have "Always" permission
        // and proper background capabilities
        let authStatus = locationManager.authorizationStatus
        if authStatus == .authorizedAlways {
            // Only set if we have Always permission
            locationManager.allowsBackgroundLocationUpdates = true
        } else {
            // For "When In Use" permission, background updates are not allowed
            locationManager.allowsBackgroundLocationUpdates = false
        }
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
            // Update background location setting based on permission
            if status == .authorizedAlways {
                locationManager.allowsBackgroundLocationUpdates = true
            } else {
                locationManager.allowsBackgroundLocationUpdates = false
            }
            
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
        
        // Update background location updates based on permission level
        if status == .authorizedAlways {
            locationManager.allowsBackgroundLocationUpdates = true
            print("✅ Location permission: Always (background updates enabled)")
        } else if status == .authorizedWhenInUse {
            locationManager.allowsBackgroundLocationUpdates = false
            print("✅ Location permission: When In Use (foreground only)")
        } else {
            locationManager.allowsBackgroundLocationUpdates = false
            print("⚠️ Location permission denied")
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
}

