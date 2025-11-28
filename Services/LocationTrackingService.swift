//
//  LocationTrackingService.swift
//  branchr
//
//  Created by Joe Dormond on 10/23/25.
//

import Foundation
import CoreLocation
import SwiftUI

/// Service for tracking GPS location during rides
/// Handles location updates, distance calculation, and ride timing
@MainActor
class LocationTrackingService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var locations: [CLLocation] = []
    @Published var distanceTraveled: Double = 0.0 // meters
    @Published var elapsedTime: TimeInterval = 0.0
    @Published var isTracking: Bool = false
    @Published var isPaused: Bool = false
    @Published var currentSpeed: Double = 0.0 // m/s
    @Published var averageSpeed: Double = 0.0 // m/s
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private var startTime: Date?
    private var pausedTime: TimeInterval = 0.0
    private var timer: Timer?
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
        print("Branchr LocationTrackingService initialized")
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
        // Simulator is not backgroundable – always disable to avoid assertion.
        locationManager.allowsBackgroundLocationUpdates = false
        print("LocationTrackingService: Background location updates DISABLED (simulator)")
        #else
        if hasBackgroundLocationCapability() && authStatus == .authorizedAlways {
            locationManager.allowsBackgroundLocationUpdates = true
            print("LocationTrackingService: Background location updates ENABLED (has capability + Always auth)")
        } else {
            locationManager.allowsBackgroundLocationUpdates = false
            if !hasBackgroundLocationCapability() {
                print("LocationTrackingService: UIBackgroundModes does not contain 'location'; background updates disabled.")
            } else {
                print("LocationTrackingService: Auth is not .authorizedAlways; background updates disabled.")
            }
        }
        #endif
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 1.0 // Update every meter
        locationManager.activityType = .fitness
        locationManager.pausesLocationUpdatesAutomatically = false
        
        // IMPORTANT: Only enable background updates if the app is actually configured
        // for background location in Info.plist / Capabilities AND user has authorizedAlways.
        let status = locationManager.authorizationStatus
        configureBackgroundLocationUpdates(authStatus: status)
        
        authorizationStatus = status
    }
    
    // MARK: - Public Methods
    
    /// Start tracking location
    func startTracking() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        
        isTracking = true
        isPaused = false
        startTime = Date()
        pausedTime = 0.0
        
        locationManager.startUpdatingLocation()
        startTimer()
        
        print("Branchr: Started location tracking")
    }
    
    /// Pause tracking (keeps location updates but stops timer)
    func pauseTracking() {
        guard isTracking else { return }
        
        isPaused = true
        timer?.invalidate()
        
        print("Branchr: Paused location tracking")
    }
    
    /// Resume tracking after pause
    func resumeTracking() {
        guard isTracking && isPaused else { return }
        
        isPaused = false
        startTimer()
        
        print("Branchr: Resumed location tracking")
    }
    
    /// Stop tracking completely
    func stopTracking() {
        isTracking = false
        isPaused = false
        
        locationManager.stopUpdatingLocation()
        timer?.invalidate()
        timer = nil
        
        print("Branchr: Stopped location tracking")
    }
    
    /// Reset all tracking data
    func reset() {
        stopTracking()
        locations.removeAll()
        distanceTraveled = 0.0
        elapsedTime = 0.0
        currentSpeed = 0.0
        averageSpeed = 0.0
        startTime = nil
        pausedTime = 0.0
        
        print("Branchr: Reset tracking data")
    }
    
    /// Request location permission
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Private Methods
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateElapsedTime()
        }
    }
    
    private func updateElapsedTime() {
        guard let startTime = startTime, !isPaused else { return }
        
        elapsedTime = Date().timeIntervalSince(startTime) - pausedTime
        updateAverageSpeed()
    }
    
    private func updateAverageSpeed() {
        guard elapsedTime > 0 else {
            averageSpeed = 0.0
            return
        }
        
        averageSpeed = distanceTraveled / elapsedTime
    }
    
    private func calculateDistance(from newLocation: CLLocation) {
        guard let lastLocation = locations.last else {
            locations.append(newLocation)
            return
        }
        
        let distance = newLocation.distance(from: lastLocation)
        
        // Only add distance if it's reasonable (filter out GPS noise)
        if distance > 0.5 && distance < 1000 { // Between 0.5m and 1km
            distanceTraveled += distance
            locations.append(newLocation)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationTrackingService: CLLocationManagerDelegate {
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        // Filter out inaccurate locations
        guard newLocation.horizontalAccuracy <= 10.0 else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.calculateDistance(from: newLocation)
            self.currentSpeed = max(0, newLocation.speed) // Ensure non-negative speed
            
            print("Branchr: Location updated - Distance: \(String(format: "%.2f", self.distanceTraveled))m, Speed: \(String(format: "%.1f", self.currentSpeed * 3.6))km/h")
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Branchr: Location tracking failed - \(error.localizedDescription)")
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            print("LocationTrackingService: auth changed to \(status.rawValue)")
            
            // Update background location updates based on capability and authorization
            self.configureBackgroundLocationUpdates(authStatus: status)
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                print("Branchr: Location permission granted")
            case .denied, .restricted:
                print("Branchr: Location permission denied")
            case .notDetermined:
                print("Branchr: Location permission not determined")
            @unknown default:
                print("Branchr: Unknown location permission status")
            }
        }
    }
}

// MARK: - Computed Properties
extension LocationTrackingService {
    
    /// Distance in miles
    var distanceInMiles: Double {
        return distanceTraveled * 0.000621371
    }
    
    /// Distance in kilometers
    var distanceInKilometers: Double {
        return distanceTraveled / 1000.0
    }
    
    /// Average speed in mph
    var averageSpeedInMPH: Double {
        return averageSpeed * 2.23694
    }
    
    /// Average speed in km/h
    var averageSpeedInKPH: Double {
        return averageSpeed * 3.6
    }
    
    /// Current speed in mph
    var currentSpeedInMPH: Double {
        return currentSpeed * 2.23694
    }
    
    /// Current speed in km/h
    var currentSpeedInKPH: Double {
        return currentSpeed * 3.6
    }
    
    /// Formatted elapsed time
    var formattedElapsedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = Int(elapsedTime) % 3600 / 60
        let seconds = Int(elapsedTime) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    /// Formatted distance based on locale
    var formattedDistance: String {
        let locale = Locale.current
        let isMetric = locale.measurementSystem == .metric
        
        if isMetric {
            return String(format: "%.2f km", distanceInKilometers)
        } else {
            return String(format: "%.2f mi", distanceInMiles)
        }
    }
    
    /// Formatted average speed based on locale
    var formattedAverageSpeed: String {
        let locale = Locale.current
        let isMetric = locale.measurementSystem == .metric
        
        if isMetric {
            return String(format: "%.1f km/h", averageSpeedInKPH)
        } else {
            return String(format: "%.1f mph", averageSpeedInMPH)
        }
    }
    
    /// Formatted current speed based on locale
    var formattedCurrentSpeed: String {
        let locale = Locale.current
        let isMetric = locale.measurementSystem == .metric
        
        if isMetric {
            return String(format: "%.1f km/h", currentSpeedInKPH)
        } else {
            return String(format: "%.1f mph", currentSpeedInMPH)
        }
    }
}
