//
//  SOSManager.swift
//  branchr
//
//  Created by Joseph Dormond on 2025-11-04
//  Phase 27 - Safety & SOS System (Emergency Mode + Location Share + Alert Animation)
//

import Foundation
import CoreLocation
import FirebaseFirestore
import FirebaseAuth
import CoreHaptics
import UIKit
import SwiftUI
import MessageUI

/**
 * 🚨 SOS Manager
 *
 * Handles emergency SOS functionality:
 * - Location tracking and sharing
 * - Firebase Firestore alert storage
 * - Haptic feedback
 * - Emergency message sending
 * - Emergency contacts management
 */
@MainActor
class SOSManager: NSObject, ObservableObject {
    static let shared = SOSManager()
    
    // MARK: - Published Properties
    @Published var sosActive = false
    @Published var currentLocation: CLLocation?
    @Published var emergencyContacts: [String] = []
    @Published var lastSOSTimestamp: Date?
    
    // MARK: - Private Properties
    let locationManager = CLLocationManager()
    private let db = Firestore.firestore()
    private var hapticEngine: CHHapticEngine?
    private var sosTimer: Timer?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        prepareHaptics()
        loadEmergencyContacts()
        print("🚨 SOSManager initialized")
    }
    
    // MARK: - Public Methods
    
    /// Trigger emergency SOS
    func triggerSOS() {
        guard !sosActive else {
            print("⚠️ SOS already active")
            return
        }
        
        sosActive = true
        lastSOSTimestamp = Date()
        
        // Request location update
        locationManager.requestLocation()
        
        // Start continuous location updates
        locationManager.startUpdatingLocation()
        
        // Trigger haptic feedback
        triggerHapticAlert()
        
        // Save to Firebase
        saveSOSAlertToFirebase()
        
        // Phase 28: Send SOS alert via FCM to connected riders
        if let location = currentLocation {
            FCMService.shared.sendSOSAlert(
                senderName: UIDevice.current.name,
                location: location.coordinate
            )
        }
        
        // Send emergency messages
        sendEmergencyMessage(recipients: emergencyContacts)
        
        print("🚨 SOS Triggered at \(currentLocation?.coordinate.latitude ?? 0), \(currentLocation?.coordinate.longitude ?? 0)")
        
        // Auto-stop SOS after 5 minutes (safety feature)
        sosTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: false) { [weak self] _ in
            self?.deactivateSOS()
        }
    }
    
    /// Deactivate SOS
    func deactivateSOS() {
        guard sosActive else { return }
        
        sosActive = false
        locationManager.stopUpdatingLocation()
        sosTimer?.invalidate()
        sosTimer = nil
        
        print("✅ SOS Deactivated")
    }
    
    /// Send emergency message to contacts
    func sendEmergencyMessage(recipients: [String]) {
        guard let location = currentLocation else {
            print("⚠️ Cannot send emergency message - location not available")
            return
        }
        
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        let locationURL = "https://maps.apple.com/?q=\(latitude),\(longitude)"
        
        let message = """
        🚨 EMERGENCY ALERT 🚨
        
        I need help! My current location:
        \(locationURL)
        
        Sent from Branchr Safety System
        """
        
        // For now, print to console. In production, use MessageUI or SMS API
        print("📱 Emergency message to send:")
        print(message)
        print("Recipients: \(recipients)")
        
        // TODO: Phase 27B - Integrate with MessageUI or SMS API
        // For now, we'll create a share sheet that can be used
        NotificationCenter.default.post(
            name: .emergencyMessageReady,
            object: nil,
            userInfo: ["message": message, "recipients": recipients]
        )
    }
    
    /// Add emergency contact
    func addEmergencyContact(_ contact: String) {
        guard !emergencyContacts.contains(contact) else { return }
        emergencyContacts.append(contact)
        saveEmergencyContacts()
    }
    
    /// Remove emergency contact
    func removeEmergencyContact(_ contact: String) {
        emergencyContacts.removeAll { $0 == contact }
        saveEmergencyContacts()
    }
    
    // MARK: - Private Methods
    
    /// Save SOS alert to Firebase
    private func saveSOSAlertToFirebase() {
        guard let userID = Auth.auth().currentUser?.uid else {
            // Silently skip if user not signed in (expected until auth is implemented)
            return
        }
        
        guard let location = currentLocation else {
            print("⚠️ Cannot save SOS alert - location not available")
            return
        }
        
        let alertData: [String: Any] = [
            "userID": userID,
            "timestamp": Timestamp(date: Date()),
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "active": true,
            "contacts": emergencyContacts
        ]
        
        db.collection("sosAlerts").addDocument(data: alertData) { error in
            if let error = error {
                print("❌ Failed to save SOS alert to Firebase: \(error.localizedDescription)")
            } else {
                print("✅ SOS alert saved to Firebase")
            }
        }
    }
    
    /// Load emergency contacts from UserDefaults
    private func loadEmergencyContacts() {
        if let contacts = UserDefaults.standard.array(forKey: "emergencyContacts") as? [String] {
            emergencyContacts = contacts
        } else {
            // Default contacts (can be customized later)
            emergencyContacts = ["911"]
        }
    }
    
    /// Save emergency contacts to UserDefaults
    private func saveEmergencyContacts() {
        UserDefaults.standard.set(emergencyContacts, forKey: "emergencyContacts")
    }
    
    // MARK: - Haptics
    
    /// Prepare haptic engine
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("⚠️ Device does not support haptics")
            return
        }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            print("✅ SOS Haptic engine initialized")
        } catch {
            print("⚠️ Failed to start haptic engine: \(error.localizedDescription)")
        }
    }
    
    /// Trigger haptic alert for SOS
    private func triggerHapticAlert() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        // Create a strong, urgent haptic pattern
        let events: [CHHapticEvent] = [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                ],
                relativeTime: 0
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                ],
                relativeTime: 0.1
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                ],
                relativeTime: 0.2
            )
        ]
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
            print("🎯 SOS Haptic alert triggered")
        } catch {
            print("⚠️ Haptic alert failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension SOSManager: CLLocationManagerDelegate {
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.currentLocation = location
            print("📍 SOS Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            print("❌ Location error: \(error.localizedDescription)")
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                print("✅ Location authorization granted for SOS")
            case .denied, .restricted:
                print("⚠️ Location authorization denied - SOS features may be limited")
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            @unknown default:
                break
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let emergencyMessageReady = Notification.Name("emergencyMessageReady")
}

