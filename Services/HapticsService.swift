//
//  HapticsService.swift
//  branchr
//
//  Created by Joe Dormond on 10/21/25.
//

import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Service for providing tactile feedback through haptic responses
/// Provides different types of haptic feedback for various user actions
@MainActor
class HapticsService: ObservableObject {
    
    // MARK: - Singleton Instance
    static let shared = HapticsService()
    
    // MARK: - Private Properties
    #if canImport(UIKit)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let impactGenerator = UIImpactFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()
    #endif
    
    // MARK: - Initialization
    private init() {
        // Prepare generators for immediate use
        #if canImport(UIKit)
        notificationGenerator.prepare()
        impactGenerator.prepare()
        selectionGenerator.prepare()
        #endif
        
        print("Branchr HapticsService initialized")
    }
    
    // MARK: - Notification Feedback Methods
    
    /// Success haptic feedback
    func success() {
        #if canImport(UIKit)
        notificationGenerator.notificationOccurred(.success)
        #endif
        print("Branchr: Success haptic triggered")
    }
    
    /// Warning haptic feedback
    func warning() {
        #if canImport(UIKit)
        notificationGenerator.notificationOccurred(.warning)
        #endif
        print("Branchr: Warning haptic triggered")
    }
    
    /// Error haptic feedback
    func error() {
        #if canImport(UIKit)
        notificationGenerator.notificationOccurred(.error)
        #endif
        print("Branchr: Error haptic triggered")
    }
    
    // MARK: - Impact Feedback Methods
    
    /// Light impact haptic feedback
    func lightTap() {
        #if canImport(UIKit)
        impactGenerator.impactOccurred(intensity: 0.3)
        #endif
        print("Branchr: Light tap haptic triggered")
    }
    
    /// Medium impact haptic feedback
    func mediumTap() {
        #if canImport(UIKit)
        impactGenerator.impactOccurred(intensity: 0.6)
        #endif
        print("Branchr: Medium tap haptic triggered")
    }
    
    /// Heavy impact haptic feedback
    func heavyTap() {
        #if canImport(UIKit)
        impactGenerator.impactOccurred(intensity: 1.0)
        #endif
        print("Branchr: Heavy tap haptic triggered")
    }
    
    // MARK: - Selection Feedback Methods
    
    /// Selection haptic feedback (for UI interactions)
    func selection() {
        #if canImport(UIKit)
        selectionGenerator.selectionChanged()
        #endif
        print("Branchr: Selection haptic triggered")
    }
    
    // MARK: - Gesture-Specific Feedback Methods
    
    /// Haptic feedback for volume adjustments
    func volumeChange() {
        lightTap()
    }
    
    /// Haptic feedback for mode changes
    func modeChange() {
        success()
    }
    
    /// Haptic feedback for gesture recognition
    func gestureRecognized() {
        mediumTap()
    }
    
    /// Haptic feedback for connection events
    func connectionEvent() {
        success()
    }
    
    /// Haptic feedback for errors or failures
    func failure() {
        error()
    }
    
    // MARK: - Custom Intensity Methods
    
    /// Custom impact feedback with specific intensity
    func customImpact(intensity: Float) {
        let clampedIntensity = max(0.0, min(1.0, intensity))
        #if canImport(UIKit)
        impactGenerator.impactOccurred(intensity: CGFloat(clampedIntensity))
        #endif
        print("Branchr: Custom impact haptic triggered with intensity \(clampedIntensity)")
    }
    
    /// Custom notification feedback with specific type
    func customNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        #if canImport(UIKit)
        notificationGenerator.notificationOccurred(type)
        #endif
        print("Branchr: Custom notification haptic triggered: \(type)")
    }
    
    // MARK: - Batch Feedback Methods
    
    /// Multiple haptic feedbacks in sequence
    func sequence(_ feedbacks: [HapticFeedback]) {
        for (index, feedback) in feedbacks.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                self.executeFeedback(feedback)
            }
        }
    }
    
    /// Execute a specific haptic feedback
    private func executeFeedback(_ feedback: HapticFeedback) {
        switch feedback {
        case .success:
            success()
        case .warning:
            warning()
        case .error:
            error()
        case .lightTap:
            lightTap()
        case .mediumTap:
            mediumTap()
        case .heavyTap:
            heavyTap()
        case .selection:
            selection()
        case .volumeChange:
            volumeChange()
        case .modeChange:
            modeChange()
        case .gestureRecognized:
            gestureRecognized()
        case .connectionEvent:
            connectionEvent()
        case .failure:
            failure()
        case .customImpact(let intensity):
            customImpact(intensity: intensity)
        #if canImport(UIKit)
        case .customNotification(let type):
            customNotification(type)
        #endif
        }
    }
    
    // MARK: - Preparation Methods
    
    /// Prepare all generators for immediate use
    func prepareAll() {
        #if canImport(UIKit)
        notificationGenerator.prepare()
        impactGenerator.prepare()
        selectionGenerator.prepare()
        #endif
        print("Branchr: All haptic generators prepared")
    }
    
    /// Prepare specific generator
    func prepare(_ feedback: HapticFeedback) {
        #if canImport(UIKit)
        switch feedback {
        case .success, .warning, .error:
            notificationGenerator.prepare()
        case .lightTap, .mediumTap, .heavyTap, .customImpact:
            impactGenerator.prepare()
        case .selection:
            selectionGenerator.prepare()
        case .volumeChange, .modeChange, .gestureRecognized, .connectionEvent, .failure:
            // These use other generators, prepare all
            prepareAll()
        case .customNotification:
            notificationGenerator.prepare()
        }
        #endif
    }
}

// MARK: - Haptic Feedback Types
enum HapticFeedback {
    case success
    case warning
    case error
    case lightTap
    case mediumTap
    case heavyTap
    case selection
    case volumeChange
    case modeChange
    case gestureRecognized
    case connectionEvent
    case failure
    case customImpact(intensity: Float)
    #if canImport(UIKit)
    case customNotification(UINotificationFeedbackGenerator.FeedbackType)
    #endif
    
    var description: String {
        switch self {
        case .success: return "Success"
        case .warning: return "Warning"
        case .error: return "Error"
        case .lightTap: return "Light Tap"
        case .mediumTap: return "Medium Tap"
        case .heavyTap: return "Heavy Tap"
        case .selection: return "Selection"
        case .volumeChange: return "Volume Change"
        case .modeChange: return "Mode Change"
        case .gestureRecognized: return "Gesture Recognized"
        case .connectionEvent: return "Connection Event"
        case .failure: return "Failure"
        case .customImpact(let intensity): return "Custom Impact (\(intensity))"
        #if canImport(UIKit)
        case .customNotification(let type): return "Custom Notification (\(type))"
        #endif
        }
    }
}
