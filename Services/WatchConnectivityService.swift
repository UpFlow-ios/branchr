//
//  WatchConnectivityService.swift
//  branchr
//
//  Created by Joe Dormond on 2025-10-25.
//

import Foundation
import WatchConnectivity
import Combine

/// Handles communication between iPhone and Apple Watch
final class WatchConnectivityService: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchConnectivityService()
    
    @Published var isWatchConnected = false
    @Published var isWatchReachable = false
    @Published var lastMessage: String? = nil
    
    private var session: WCSession?
    
    override init() {
        super.init()
        
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
            print("⌚ WatchConnectivityService initialized")
        } else {
            print("⌚ Watch Connectivity not supported on this device")
        }
    }
    
    // MARK: - Public Methods
    
    /// Send mode update to Apple Watch
    func sendModeUpdate(_ mode: BranchrMode) {
        guard let session = session, session.isReachable else {
            print("⌚ Watch not reachable, cannot send mode update")
            return
        }
        
        let message = [
            "type": "modeUpdate",
            "mode": mode.rawValue,
            "modeDisplayName": mode.displayName,
            "timestamp": Date().timeIntervalSince1970
        ] as [String : Any]
        
        session.sendMessage(message, replyHandler: { response in
            DispatchQueue.main.async {
                self.lastMessage = "Mode sent: \(mode.displayName)"
                print("📡 Mode sent to watch: \(mode.displayName)")
            }
        }, errorHandler: { error in
            DispatchQueue.main.async {
                self.lastMessage = "Failed to send: \(error.localizedDescription)"
                print("❌ Failed to send mode to watch: \(error.localizedDescription)")
            }
        })
    }
    
    /// Send ride data to Apple Watch
    func sendRideData(distance: Double, duration: TimeInterval, calories: Double) {
        guard let session = session, session.isReachable else {
            print("⌚ Watch not reachable, cannot send ride data")
            return
        }
        
        let message = [
            "type": "rideData",
            "distance": distance,
            "duration": duration,
            "calories": calories,
            "timestamp": Date().timeIntervalSince1970
        ] as [String : Any]
        
        session.sendMessage(message, replyHandler: { response in
            DispatchQueue.main.async {
                self.lastMessage = "Ride data sent"
                print("📡 Ride data sent to watch")
            }
        }, errorHandler: { error in
            DispatchQueue.main.async {
                self.lastMessage = "Failed to send ride data: \(error.localizedDescription)"
                print("❌ Failed to send ride data to watch: \(error.localizedDescription)")
            }
        })
    }
    
    /// Send voice command to Apple Watch
    func sendVoiceCommand(_ command: String) {
        guard let session = session, session.isReachable else {
            print("⌚ Watch not reachable, cannot send voice command")
            return
        }
        
        let message = [
            "type": "voiceCommand",
            "command": command,
            "timestamp": Date().timeIntervalSince1970
        ] as [String : Any]
        
        session.sendMessage(message, replyHandler: { response in
            DispatchQueue.main.async {
                self.lastMessage = "Voice command sent: \(command)"
                print("📡 Voice command sent to watch: \(command)")
            }
        }, errorHandler: { error in
            DispatchQueue.main.async {
                self.lastMessage = "Failed to send voice command: \(error.localizedDescription)"
                print("❌ Failed to send voice command to watch: \(error.localizedDescription)")
            }
        })
    }
    
    /// Update application context for background sync
    func updateApplicationContext(mode: BranchrMode, isTracking: Bool = false) {
        guard let session = session else { return }
        
        let context = [
            "mode": mode.rawValue,
            "isTracking": isTracking,
            "lastUpdate": Date().timeIntervalSince1970
        ] as [String : Any]
        
        do {
            try session.updateApplicationContext(context)
            print("📡 Application context updated for watch")
        } catch {
            print("❌ Failed to update application context: \(error.localizedDescription)")
        }
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchConnected = activationState == .activated
            if let error = error {
                print("❌ Watch session activation failed: \(error.localizedDescription)")
            } else {
                print("⌚ Watch session activated: \(activationState.rawValue)")
            }
        }
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchConnected = false
            print("⌚ Watch session became inactive")
        }
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchConnected = false
            print("⌚ Watch session deactivated")
        }
    }
    #endif
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
            print("⌚ Watch reachability changed: \(session.isReachable)")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.handleReceivedMessage(message)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        DispatchQueue.main.async {
            self.handleReceivedMessage(message)
            replyHandler(["status": "received"])
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            self.handleReceivedApplicationContext(applicationContext)
        }
    }
    
    // MARK: - Private Methods
    
    private func handleReceivedMessage(_ message: [String : Any]) {
        guard let type = message["type"] as? String else { return }
        
        switch type {
        case "modeUpdate":
            if let modeStr = message["mode"] as? String,
               let mode = BranchrMode(rawValue: modeStr) {
                // Update mode in main app
                NotificationCenter.default.post(name: .modeChanged, object: mode)
                self.lastMessage = "Mode received from watch: \(mode.displayName)"
                print("⌚ Mode received from watch: \(mode.displayName)")
            }
            
        case "voiceCommand":
            if let command = message["command"] as? String {
                // Handle voice command from watch
                self.lastMessage = "Voice command from watch: \(command)"
                print("⌚ Voice command received from watch: \(command)")
            }
            
        case "rideData":
            if let distance = message["distance"] as? Double,
               let duration = message["duration"] as? TimeInterval,
               let calories = message["calories"] as? Double {
                // Handle ride data from watch
                self.lastMessage = "Ride data received from watch"
                print("⌚ Ride data received from watch: \(distance)mi, \(duration)s, \(calories)cal")
            }
            
        default:
            print("⌚ Unknown message type received: \(type)")
        }
    }
    
    private func handleReceivedApplicationContext(_ context: [String : Any]) {
        if let modeStr = context["mode"] as? String,
           let mode = BranchrMode(rawValue: modeStr) {
            // Update mode from application context
            NotificationCenter.default.post(name: .modeChanged, object: mode)
            print("⌚ Mode updated from watch context: \(mode.displayName)")
        }
    }
}
