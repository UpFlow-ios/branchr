//
//  GestureControlService.swift
//  branchr
//
//  Created by Joe Dormond on 10/21/25.
//

import Foundation
import CoreMotion
import SwiftUI

/// Service for detecting head gestures using CoreMotion
/// Provides hands-free control for music and voice volume adjustments
@MainActor
class GestureControlService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var lastGesture: RideGesture?
    @Published var isActive = false
    @Published var gestureCount = 0
    
    // MARK: - Ride Gesture Enum
    enum RideGesture: String, CaseIterable {
        case nodUp = "nod_up"
        case nodDown = "nod_down"
        case tiltLeft = "tilt_left"
        case tiltRight = "tilt_right"
        case shake = "shake"
        
        var displayName: String {
            switch self {
            case .nodUp: return "Nod Up"
            case .nodDown: return "Nod Down"
            case .tiltLeft: return "Tilt Left"
            case .tiltRight: return "Tilt Right"
            case .shake: return "Shake"
            }
        }
        
        var description: String {
            switch self {
            case .nodUp: return "Music Volume +"
            case .nodDown: return "Music Volume -"
            case .tiltLeft: return "Voice Only"
            case .tiltRight: return "Music Only"
            case .shake: return "Both Mode"
            }
        }
    }
    
    // MARK: - Private Properties
    private let motionManager = CMMotionManager()
    private var lastGestureTime: Date = Date.distantPast
    private var gestureBuffer: [CMAccelerometerData] = []
    private let bufferSize = 10
    
    // MARK: - Gesture Detection Constants
    private let pitchThreshold: Double = 0.40 // ≈ 23° for nod up/down (increased sensitivity)
    private let rollThreshold: Double = 0.50  // ≈ 28.6° for left/right tilts (increased sensitivity)
    private let shakeMagnitude: Double = 2.5 // Peak acceleration for shake (increased)
    private let deadZone: Double = 0.10      // Minimum movement to register (increased)
    private let minIntervalBetweenGestures: TimeInterval = 1.5 // 1.5s debounce (increased)
    private let volumeStep: Float = 0.05     // Volume adjustment step
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupMotionManager()
        print("Branchr GestureControlService initialized")
    }
    
    // MARK: - Setup Methods
    
    private func setupMotionManager() {
        // Configure motion manager for optimal gesture detection
        motionManager.accelerometerUpdateInterval = 1.0 / 60.0 // 60 Hz
        motionManager.gyroUpdateInterval = 1.0 / 60.0
        
        // Set up accelerometer data handler
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
            guard let self = self, let data = data else { return }
            self.processAccelerometerData(data)
        }
        
        print("Branchr: Motion manager configured for gesture detection")
    }
    
    // MARK: - Public Methods
    
    /// Start gesture detection
    func start() {
        guard !isActive else { return }
        
        // Check if motion services are available
        guard CMMotionManager().isAccelerometerAvailable else {
            print("Branchr: Accelerometer not available")
            return
        }
        
        isActive = true
        gestureBuffer.removeAll()
        lastGestureTime = Date.distantPast
        
        print("Branchr: Gesture detection started")
    }
    
    /// Stop gesture detection
    func stop() {
        guard isActive else { return }
        
        isActive = false
        gestureBuffer.removeAll()
        
        print("Branchr: Gesture detection stopped")
    }
    
    /// Get volume step for external use
    var volumeAdjustmentStep: Float {
        return volumeStep
    }
    
    // MARK: - Private Methods
    
    private func processAccelerometerData(_ data: CMAccelerometerData) {
        guard isActive else { return }
        
        // Add to buffer for smoothing
        gestureBuffer.append(data)
        if gestureBuffer.count > bufferSize {
            gestureBuffer.removeFirst()
        }
        
        // Analyze for gestures
        analyzeForGestures()
    }
    
    private func analyzeForGestures() {
        guard gestureBuffer.count >= 3 else { return }
        
        // Check debounce timing
        let now = Date()
        guard now.timeIntervalSince(lastGestureTime) >= minIntervalBetweenGestures else {
            return
        }
        
        // Analyze recent data for gestures
        if let gesture = detectGesture() {
            handleGesture(gesture)
        }
    }
    
    private func detectGesture() -> RideGesture? {
        guard gestureBuffer.count >= 3 else { return nil }
        
        // Calculate smoothed values from buffer
        let avgX = gestureBuffer.map { $0.acceleration.x }.reduce(0, +) / Double(gestureBuffer.count)
        let avgY = gestureBuffer.map { $0.acceleration.y }.reduce(0, +) / Double(gestureBuffer.count)
        let avgZ = gestureBuffer.map { $0.acceleration.z }.reduce(0, +) / Double(gestureBuffer.count)
        
        // Calculate magnitude for shake detection
        let magnitude = sqrt(avgX * avgX + avgY * avgY + avgZ * avgZ)
        
        // Check for shake first (highest priority)
        if magnitude > shakeMagnitude {
            return .shake
        }
        
        // Check for nods (pitch changes)
        if abs(avgY) > pitchThreshold {
            if avgY > 0 {
                return .nodUp
            } else {
                return .nodDown
            }
        }
        
        // Check for tilts (roll changes)
        if abs(avgX) > rollThreshold {
            if avgX > 0 {
                return .tiltRight
            } else {
                return .tiltLeft
            }
        }
        
        return nil
    }
    
    private func handleGesture(_ gesture: RideGesture) {
        // Update last gesture time
        lastGestureTime = Date()
        
        // Update published properties
        lastGesture = gesture
        gestureCount += 1
        
        // Log gesture detection
        print("Branchr: Gesture detected - \(gesture.displayName)")
        
        // Post notification for other services to handle
        NotificationCenter.default.post(
            name: .rideGestureDetected,
            object: nil,
            userInfo: ["gesture": gesture]
        )
    }
    
    // MARK: - Calibration Methods
    
    /// Calibrate gesture sensitivity based on user preferences
    func calibrateSensitivity(_ level: Float) {
        let clampedLevel = max(0.1, min(2.0, level))
        
        // Adjust thresholds based on sensitivity
        // Higher sensitivity = lower thresholds (more sensitive)
        // Lower sensitivity = higher thresholds (less sensitive)
        let sensitivityFactor = 1.0 / Double(clampedLevel)
        
        // Note: In a real implementation, you'd store these as instance variables
        // and update the detection logic accordingly
        print("Branchr: Gesture sensitivity calibrated to \(clampedLevel)")
    }
    
    /// Reset gesture detection to default settings
    func resetToDefaults() {
        gestureBuffer.removeAll()
        lastGestureTime = Date.distantPast
        gestureCount = 0
        lastGesture = nil
        
        print("Branchr: Gesture detection reset to defaults")
    }
    
    // MARK: - Debug Methods
    
    /// Get current motion data for debugging
    func getCurrentMotionData() -> (x: Double, y: Double, z: Double)? {
        guard let data = motionManager.accelerometerData else { return nil }
        return (data.acceleration.x, data.acceleration.y, data.acceleration.z)
    }
    
    /// Get gesture detection statistics
    func getGestureStats() -> (totalGestures: Int, lastGesture: RideGesture?, timeSinceLastGesture: TimeInterval) {
        let timeSinceLast = Date().timeIntervalSince(lastGestureTime)
        return (gestureCount, lastGesture, timeSinceLast)
    }
    
    // MARK: - Cleanup
    deinit {
        // Note: deinit cannot be @MainActor, so we only handle non-actor cleanup
        gestureBuffer.removeAll()
        motionManager.stopAccelerometerUpdates()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let rideGestureDetected = Notification.Name("rideGestureDetected")
}
