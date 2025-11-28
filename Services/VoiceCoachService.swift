//
//  VoiceCoachService.swift
//  branchr
//
//  Created for Phase 39 - Smart Voice Coach & Audio Feedback Polish
//

import Foundation
import Combine

/**
 * 🎯 Voice Coach Service
 *
 * Provides periodic ride status updates during active rides.
 * Triggers voice announcements at regular intervals (time or distance).
 * Phase 39: Smart Voice Coach with user preference support.
 */
@MainActor
final class VoiceCoachService {
    static let shared = VoiceCoachService()
    
    // MARK: - Configuration
    
    /// Update interval: every 2 minutes OR every 0.5 miles (whichever comes first)
    private let timeInterval: TimeInterval = 120.0 // 2 minutes
    private let distanceInterval: Double = 0.5 // 0.5 miles
    
    // MARK: - State
    
    private var updateTimer: Timer?
    private var lastUpdateTime: Date?
    private var lastUpdateDistance: Double = 0.0 // in miles
    private var isActive = false
    
    // MARK: - Dependencies
    
    private let preferenceManager = UserPreferenceManager.shared
    private let voiceFeedback = VoiceFeedbackService.shared
    
    private init() {
        print("🎯 VoiceCoachService initialized")
    }
    
    // MARK: - Public Methods
    
    /// Start Voice Coach updates for an active ride
    func start() {
        guard !isActive else {
            print("🎯 VoiceCoachService: Already active, ignoring start")
            return
        }
        
        // Check if Voice Coach is enabled
        guard preferenceManager.voiceCoachEnabled else {
            print("🎯 VoiceCoachService: Voice Coach disabled in preferences, not starting")
            return
        }
        
        isActive = true
        lastUpdateTime = Date()
        lastUpdateDistance = 0.0
        
        // Start timer for time-based updates
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkForUpdate()
            }
        }
        
        print("🎯 VoiceCoachService: Started")
    }
    
    /// Stop Voice Coach updates
    func stop() {
        guard isActive else { return }
        
        isActive = false
        updateTimer?.invalidate()
        updateTimer = nil
        lastUpdateTime = nil
        lastUpdateDistance = 0.0
        
        print("🎯 VoiceCoachService: Stopped")
    }
    
    /// Check if Voice Coach is currently active
    var isCurrentlyActive: Bool {
        return isActive
    }
    
    // MARK: - Private Methods
    
    /// Check if it's time for an update and trigger if needed
    private func checkForUpdate() {
        guard isActive else { return }
        guard preferenceManager.voiceCoachEnabled else {
            // If disabled during ride, stop immediately
            stop()
            return
        }
        
        // Get current ride metrics from RideTrackingService
        let rideService = RideTrackingService.shared
        guard rideService.rideState == .active else {
            // Ride is not active, stop Voice Coach
            stop()
            return
        }
        
        let currentTime = Date()
        let currentDistance = rideService.totalDistanceMiles
        let currentDuration = rideService.totalDurationSeconds
        let currentSpeed = rideService.averageSpeedMph
        
        // Check if enough time has passed
        let timeSinceLastUpdate: TimeInterval
        if let lastTime = lastUpdateTime {
            timeSinceLastUpdate = currentTime.timeIntervalSince(lastTime)
        } else {
            timeSinceLastUpdate = timeInterval + 1 // Force first update
        }
        
        // Check if enough distance has been covered
        let distanceSinceLastUpdate = currentDistance - lastUpdateDistance
        
        // Trigger update if either threshold is met
        if timeSinceLastUpdate >= timeInterval || distanceSinceLastUpdate >= distanceInterval {
            speakStatusUpdate(
                distance: currentDistance,
                duration: currentDuration,
                averageSpeed: currentSpeed
            )
            
            lastUpdateTime = currentTime
            lastUpdateDistance = currentDistance
        }
    }
    
    /// Speak a status update with current ride metrics
    private func speakStatusUpdate(distance: Double, duration: TimeInterval, averageSpeed: Double) {
        // Format distance (1 decimal place)
        let distanceText = String(format: "%.1f", distance)
        
        // Format duration (minutes and seconds)
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let durationText: String
        if minutes > 0 {
            durationText = "\(minutes) minute\(minutes == 1 ? "" : "s")"
        } else {
            durationText = "\(seconds) second\(seconds == 1 ? "" : "s")"
        }
        
        // Format average speed (1 decimal place)
        let speedText = String(format: "%.1f", averageSpeed)
        
        // Construct message
        let message = "You've gone \(distanceText) miles in \(durationText). Average speed, \(speedText) miles per hour."
        
        voiceFeedback.speak(message)
        print("🎯 VoiceCoachService: Status update - \(message)")
    }
}

