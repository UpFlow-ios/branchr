//
//  MotionDetectionService.swift
//  branchr
//
//  Created by Joe Dormond on 10/23/25.
//

import Foundation
import CoreMotion
import SwiftUI

/// Service for detecting motion activities and automatically prompting ride tracking
/// Uses CoreMotion to detect cycling, running, and walking activities
@MainActor
class MotionDetectionService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var rideDetected: Bool = false
    @Published var currentActivity: CMMotionActivity?
    @Published var isMonitoring: Bool = false
    @Published var lastPromptTime: Date?
    
    // MARK: - Private Properties
    private let motionManager = CMMotionActivityManager()
    private let queue = OperationQueue()
    
    // MARK: - Configuration
    private let promptCooldownInterval: TimeInterval = 600 // 10 minutes
    private let minimumConfidence: CMMotionActivityConfidence = .medium
    
    // MARK: - Initialization
    override init() {
        super.init()
        queue.name = "MotionDetectionQueue"
        queue.maxConcurrentOperationCount = 1
        
        print("Branchr MotionDetectionService initialized")
    }
    
    // MARK: - Public Methods
    
    /// Start monitoring motion activities
    func startMonitoring() {
        guard CMMotionActivityManager.isActivityAvailable() else {
            print("Branchr: Motion activity detection not available on this device")
            return
        }
        
        guard !isMonitoring else {
            print("Branchr: Motion monitoring already active")
            return
        }
        
        isMonitoring = true
        
        // Start monitoring motion activities
        motionManager.startActivityUpdates(to: queue) { [weak self] activity in
            DispatchQueue.main.async {
                self?.processMotionActivity(activity)
            }
        }
        
        print("Branchr: Motion monitoring started")
    }
    
    /// Stop monitoring motion activities
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        motionManager.stopActivityUpdates()
        isMonitoring = false
        
        print("Branchr: Motion monitoring stopped")
    }
    
    /// Reset ride detection state (called after user responds to prompt)
    func resetRideDetection() {
        rideDetected = false
        lastPromptTime = Date()
        
        print("Branchr: Ride detection reset")
    }
    
    /// Check if we should prompt the user (respects cooldown period)
    private func shouldPromptUser() -> Bool {
        guard let lastPrompt = lastPromptTime else { return true }
        
        let timeSinceLastPrompt = Date().timeIntervalSince(lastPrompt)
        return timeSinceLastPrompt >= promptCooldownInterval
    }
    
    // MARK: - Private Methods
    
    private func processMotionActivity(_ activity: CMMotionActivity?) {
        guard let activity = activity else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Update current activity
            self.currentActivity = activity
            
            // Check if this is a ride activity with sufficient confidence
            let isRideActivity = (activity.cycling || activity.running) && 
                               activity.confidence.rawValue >= self.minimumConfidence.rawValue
            
            // Only trigger prompt if:
            // 1. It's a ride activity
            // 2. We haven't already detected a ride
            // 3. We should prompt the user (respects cooldown)
            if isRideActivity && !self.rideDetected && self.shouldPromptUser() {
                self.rideDetected = true
                
                let activityType = activity.cycling ? "cycling" : "running"
                let confidence = activity.confidence.description
                
                print("Branchr: Ride activity detected - \(activityType) (confidence: \(confidence))")
            }
        }
    }
}

// MARK: - CMMotionActivityConfidence Extension
extension CMMotionActivityConfidence {
    var description: String {
        switch self {
        case .low:
            return "low"
        case .medium:
            return "medium"
        case .high:
            return "high"
        @unknown default:
            return "unknown"
        }
    }
}

// MARK: - Computed Properties
extension MotionDetectionService {
    
    /// Current activity type as a readable string
    var currentActivityDescription: String {
        guard let activity = currentActivity else { return "Unknown" }
        
        if activity.cycling {
            return "Cycling"
        } else if activity.running {
            return "Running"
        } else if activity.walking {
            return "Walking"
        } else if activity.automotive {
            return "Driving"
        } else if activity.stationary {
            return "Stationary"
        } else {
            return "Unknown"
        }
    }
    
    /// Whether we're currently detecting a ride activity
    var isRideActivity: Bool {
        guard let activity = currentActivity else { return false }
        return (activity.cycling || activity.running) && 
               activity.confidence.rawValue >= minimumConfidence.rawValue
    }
}
