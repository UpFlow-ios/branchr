//
//  FCMService.swift
//  branchr
//
//  Created by Joseph Dormond on 2025-11-04
//  Phase 28 - Firebase Cloud Messaging for Realtime SOS Alerts
//

import Foundation
import FirebaseCore
import FirebaseMessaging
import FirebaseAuth
import FirebaseFirestore
import UserNotifications
import SwiftUI
import CoreLocation

/**
 * 🔔 FCM Service
 *
 * Handles Firebase Cloud Messaging for:
 * - Push notification registration
 * - SOS alert broadcasting
 * - Incoming notification handling
 * - Live alert updates
 */
@MainActor
class FCMService: NSObject, ObservableObject, MessagingDelegate, UNUserNotificationCenterDelegate {
    static let shared = FCMService()
    
    // MARK: - Published Properties
    @Published var latestSOSAlert: SOSAlert?
    
    // MARK: - Private Properties
    private let db = Firestore.firestore()
    private var userToken: String?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        configureNotifications()
        print("🔔 FCMService initialized")
    }
    
    // MARK: - Configuration
    
    func configureNotifications() {
        // Phase 35.4: Check Firebase without helper function
        if FirebaseApp.app() == nil {
            print("⚠️ Firebase not ready – delaying FCM setup…")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.configureNotifications()
            }
            return
        }
        
        // Set delegates
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        
        // Request notification permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            if let error = error {
                print("❌ Notification permission error: \(error.localizedDescription)")
                return
            }
            
            print("🔔 Notification permission: \(granted ? "granted" : "denied")")
            
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    // MARK: - FCM Token Management
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else {
            print("⚠️ FCM token is nil")
            return
        }
        
        self.userToken = token
        print("📱 FCM Token received: \(token.prefix(20))...")
        
        // Save token in Firestore
        if let uid = Auth.auth().currentUser?.uid {
            db.collection("users").document(uid).setData([
                "fcmToken": token,
                "fcmTokenUpdatedAt": Timestamp(date: Date())
            ], merge: true) { error in
                if let error = error {
                    print("❌ Failed to save FCM token: \(error.localizedDescription)")
                } else {
                    print("✅ FCM token saved to Firestore")
                }
            }
        }
        // Silently skip if user not signed in (expected until auth is implemented)
    }
    
    // MARK: - Send SOS Alert
    
    /// Send SOS alert to all connected riders via FCM
    func sendSOSAlert(senderName: String, location: CLLocationCoordinate2D) {
        guard let senderUID = Auth.auth().currentUser?.uid else {
            // Silently skip if user not signed in (expected until auth is implemented)
            return
        }
        
        // Get all connected riders' FCM tokens
        db.collection("users")
            .whereField("isOnline", isEqualTo: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error fetching online riders: \(error.localizedDescription)")
                    return
                }
                
                guard let docs = snapshot?.documents else {
                    print("⚠️ No online riders found")
                    return
                }
                
                // Filter out sender and get FCM tokens
                let recipientTokens = docs
                    .filter { $0.documentID != senderUID }
                    .compactMap { $0.data()["fcmToken"] as? String }
                
                if recipientTokens.isEmpty {
                    print("⚠️ No recipients with FCM tokens found")
                    return
                }
                
                print("📤 Sending SOS alert to \(recipientTokens.count) rider(s)")
                
                // Save alert to Firestore (this will trigger FCM via Cloud Functions in production)
                // For now, we'll use a direct Firestore listener approach
                let alertData: [String: Any] = [
                    "senderUID": senderUID,
                    "senderName": senderName,
                    "title": "🚨 SOS ALERT",
                    "body": "\(senderName) triggered SOS nearby!",
                    "latitude": location.latitude,
                    "longitude": location.longitude,
                    "timestamp": Timestamp(date: Date()),
                    "recipientTokens": recipientTokens
                ]
                
                self.db.collection("sosAlerts").addDocument(data: alertData) { error in
                    if let error = error {
                        print("❌ Error sending SOS alert: \(error.localizedDescription)")
                    } else {
                        print("🚨 SOS alert broadcasted successfully to Firestore")
                        // Note: In production, use Cloud Functions to send FCM push notifications
                    }
                }
            }
    }
    
    // MARK: - Listen for SOS Alerts
    
    /// Start listening for real-time SOS alerts from Firestore
    func startListeningForSOSAlerts() {
        guard let currentUID = Auth.auth().currentUser?.uid else {
            // Silently skip if user not signed in (expected until auth is implemented)
            return
        }
        
        db.collection("sosAlerts")
            .whereField("recipientTokens", arrayContains: userToken ?? "")
            .order(by: "timestamp", descending: true)
            .limit(to: 1)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ SOS alert listener error: \(error.localizedDescription)")
                    return
                }
                
                guard let docs = snapshot?.documents, let latestDoc = docs.first else {
                    return
                }
                
                let data = latestDoc.data()
                guard let senderName = data["senderName"] as? String,
                      let lat = data["latitude"] as? Double,
                      let lon = data["longitude"] as? Double else {
                    return
                }
                
                // Only show alerts not from current user
                if let senderUID = data["senderUID"] as? String, senderUID != currentUID {
                    self.latestSOSAlert = SOSAlert(
                        name: senderName,
                        latitude: lat,
                        longitude: lon,
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    )
                    print("🚨 Received SOS alert from \(senderName)")
                }
            }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    /// Handle notification while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let content = notification.request.content
        let userInfo = content.userInfo
        
        // Extract location from notification
        if let lat = userInfo["latitude"] as? Double,
           let lon = userInfo["longitude"] as? Double,
           let senderName = userInfo["senderName"] as? String {
            latestSOSAlert = SOSAlert(
                name: senderName,
                latitude: lat,
                longitude: lon,
                timestamp: Date()
            )
            print("🚨 Foreground SOS alert received from \(senderName)")
        }
        
        // Show banner and sound even when app is open
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Extract location from notification
        if let lat = userInfo["latitude"] as? Double,
           let lon = userInfo["longitude"] as? Double,
           let senderName = userInfo["senderName"] as? String {
            latestSOSAlert = SOSAlert(
                name: senderName,
                latitude: lat,
                longitude: lon,
                timestamp: Date()
            )
            print("🚨 Tapped SOS alert from \(senderName)")
        }
        
        completionHandler()
    }
}

// MARK: - SOS Alert Model

struct SOSAlert: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    
    /// Calculate distance from current location (optional helper)
    func distance(from location: CLLocation?) -> Double? {
        guard let location = location else { return nil }
        let alertLocation = CLLocation(latitude: latitude, longitude: longitude)
        return location.distance(from: alertLocation) / 1609.34 // Convert meters to miles
    }
    
    // Equatable conformance
    static func == (lhs: SOSAlert, rhs: SOSAlert) -> Bool {
        return lhs.id == rhs.id && 
               lhs.name == rhs.name &&
               lhs.latitude == rhs.latitude &&
               lhs.longitude == rhs.longitude
    }
}

