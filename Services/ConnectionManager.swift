//
//  ConnectionManager.swift
//  branchr
//
//  Created by Joseph Dormond on 2025-11-04
//  Phase 25 - Start Connection System (Bluetooth + WiFi + Cellular Fallback)
//

import Foundation
import MultipeerConnectivity
import FirebaseFirestore
import FirebaseAuth
import CoreHaptics
import UIKit
import SwiftUI
import Combine
import Network

/**
 * 🔗 Connection Manager
 *
 * Handles peer connections via:
 * - MultipeerConnectivity (Bluetooth/WiFi for nearby riders)
 * - Firebase Firestore (Cloud fallback for remote riders)
 *
 * Features:
 * - Automatic fallback to Firebase if no local peers found
 * - Haptic feedback on successful connection
 * - Real-time connection status updates
 */
@MainActor
class ConnectionManager: NSObject, ObservableObject {
    static let shared = ConnectionManager()
    
    // MARK: - Published Properties
    @Published var connectedPeers: [MCPeerID] = []
    @Published var isConnecting = false
    @Published var isConnected = false
    @Published var connectionMethod: ConnectionMethod = .none
    
    // Phase 29C: Connection state enum for button logic
    enum ConnectionState {
        case idle        // not started
        case connecting  // in progress
        case connected  // active
    }
    
    @Published var state: ConnectionState = .idle
    
    // MARK: - Private Properties
    private let serviceType = "branchr-connect"
    private var peerID: MCPeerID!
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private let db = Firestore.firestore()
    private var hapticEngine: CHHapticEngine?
    private var firebaseFallbackTimer: Timer?
    
    enum ConnectionMethod {
        case none
        case bluetooth
        case firebase
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        let deviceName = UIDevice.current.name
        peerID = MCPeerID(displayName: deviceName)
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        prepareHaptics()
        print("🔗 ConnectionManager initialized for: \(deviceName)")
    }
    
    // MARK: - Public Methods
    
    /// Start connection - searches locally first, then falls back to Firebase
    func startConnection() {
        guard state == .idle else {
            print("⚠️ Connection already in progress")
            return
        }
        
        // Phase 29C: Update state and trigger haptic
        state = .connecting
        isConnecting = true
        isConnected = false
        connectedPeers.removeAll()
        connectionMethod = .none
        
        triggerHaptic(.warning) // Phase 29C: Use warning for connecting state
        
        // Start local peer discovery
        startLocalDiscovery()
        
        // Schedule Firebase fallback after 5 seconds if no local peers found
        firebaseFallbackTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            guard let self = self, self.connectedPeers.isEmpty else { return }
            self.connectViaFirebase()
        }
        
        print("🔍 Searching for nearby riders via Bluetooth/Wi-Fi...")
    }
    
    /// Stop all connections
    func stopConnection() {
        guard state == .connected || state == .connecting else {
            print("⚠️ No active connection to stop")
            return
        }
        
        // Phase 29C: Update state and trigger haptic
        state = .idle
        isConnecting = false
        isConnected = false
        connectionMethod = .none
        
        triggerHaptic(.warning)
        
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        advertiser = nil
        browser = nil
        
        session.disconnect()
        connectedPeers.removeAll()
        
        firebaseFallbackTimer?.invalidate()
        firebaseFallbackTimer = nil
        
        print("🔴 Disconnected from all peers")
    }
    
    // MARK: - Private Methods
    
    /// Start local peer discovery (Bluetooth/WiFi)
    private func startLocalDiscovery() {
        let discoveryInfo = [
            "app": "branchr",
            "version": "1.0"
        ]
        
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: discoveryInfo, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        
        print("📡 Started advertising and browsing for local peers")
    }
    
    /// Fallback to Firebase if no local peers found
    private func connectViaFirebase() {
        guard connectedPeers.isEmpty else {
            print("✅ Local peers already connected, skipping Firebase fallback")
            return
        }
        
        print("☁️ No local peers found. Checking Firebase presence...")
        guard let user = Auth.auth().currentUser else {
            print("⚠️ Cannot connect via Firebase - user not signed in")
            isConnecting = false
            return
        }
        
        // Check for online riders in Firestore
        db.collection("users")
            .whereField("isOnline", isEqualTo: true)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("❌ Firebase connection failed: \(error.localizedDescription)")
                        self.isConnecting = false
                        return
                    }
                    
                    guard let docs = snapshot?.documents else {
                        print("⚠️ No online riders found on Firebase")
                        self.isConnecting = false
                        return
                    }
                    
                    // Filter out current user
                    let onlineRiders = docs.filter { $0.documentID != user.uid }
                    
                    if !onlineRiders.isEmpty {
                        self.isConnected = true
                        self.state = .connected // Phase 29C: Update state
                        self.connectionMethod = .firebase
                        self.triggerHapticSuccess()
                        print("✅ Connected via Firebase to \(onlineRiders.count) online rider(s)")
                    } else {
                        self.state = .idle // Phase 29C: Reset to idle if no connection
                        print("⚠️ No other online riders found on Firebase")
                    }
                    
                    self.isConnecting = false
                    if !self.isConnected {
                        self.state = .idle // Phase 29C: Ensure state is idle if not connected
                    }
                }
            }
    }
    
    // MARK: - Haptics
    
    /// Prepare haptic engine for feedback
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("⚠️ Device does not support haptics")
            return
        }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            print("✅ Haptic engine initialized")
        } catch {
            print("⚠️ Failed to start haptic engine: \(error.localizedDescription)")
        }
    }
    
    /// Trigger success haptic feedback
    private func triggerHapticSuccess() {
        // Phase 29C: Use notification haptic for success
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        print("🎯 Haptic feedback triggered for successful connection")
    }
    
    // Phase 29C: Haptic feedback helper
    private func triggerHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
}

// MARK: - MCSessionDelegate

extension ConnectionManager: MCSessionDelegate {
    
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                }
                self.isConnected = true
                self.isConnecting = false
                self.state = .connected // Phase 29C: Update state
                self.connectionMethod = .bluetooth
                self.triggerHapticSuccess()
                self.firebaseFallbackTimer?.invalidate()
                print("✅ Connected to \(peerID.displayName) via Bluetooth/WiFi")
                
            case .connecting:
                print("⏳ Connecting to \(peerID.displayName)...")
                
            case .notConnected:
                self.connectedPeers.removeAll { $0 == peerID }
                if self.connectedPeers.isEmpty {
                    self.isConnected = false
                    self.connectionMethod = .none
                }
                print("🔴 Disconnected from \(peerID.displayName)")
                
            @unknown default:
                break
            }
        }
    }
    
    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // Handle received data if needed
        print("📨 Received data from \(peerID.displayName)")
    }
    
    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("📡 Received stream '\(streamName)' from \(peerID.displayName)")
    }
    
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("📥 Started receiving resource '\(resourceName)' from \(peerID.displayName)")
    }
    
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        if let error = error {
            print("❌ Error receiving resource '\(resourceName)': \(error.localizedDescription)")
        } else {
            print("✅ Finished receiving resource '\(resourceName)' from \(peerID.displayName)")
        }
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension ConnectionManager: MCNearbyServiceAdvertiserDelegate {
    
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("📡 Received invitation from \(peerID.displayName)")
        // Auto-accept invitations - must access session on main actor
        DispatchQueue.main.async {
            invitationHandler(true, self.session)
        }
    }
    
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        DispatchQueue.main.async {
            print("❌ Failed to start advertising: \(error.localizedDescription)")
            // Try Firebase fallback if advertising fails
            if self.connectedPeers.isEmpty {
                self.connectViaFirebase()
            }
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension ConnectionManager: MCNearbyServiceBrowserDelegate {
    
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("👀 Found nearby rider: \(peerID.displayName)")
        // Auto-invite discovered peers - must access session on main actor
        DispatchQueue.main.async {
            browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
        }
    }
    
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("🚫 Lost connection with \(peerID.displayName)")
        DispatchQueue.main.async {
            self.connectedPeers.removeAll { $0 == peerID }
            if self.connectedPeers.isEmpty {
                self.isConnected = false
                self.connectionMethod = .none
            }
        }
    }
    
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        DispatchQueue.main.async {
            print("❌ Failed to start browsing: \(error.localizedDescription)")
            // Try Firebase fallback if browsing fails
            if self.connectedPeers.isEmpty {
                self.connectViaFirebase()
            }
        }
    }
}

