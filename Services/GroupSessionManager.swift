//
//  GroupSessionManager.swift
//  branchr
//
//  Created by Joe Dormond on 10/21/25.
//

import Foundation
import MultipeerConnectivity
import SwiftUI
import UIKit

// MARK: - Rider Profile Model (Phase 21B)

struct RiderProfile: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let bio: String
    let image: UIImage?
    
    static func == (lhs: RiderProfile, rhs: RiderProfile) -> Bool {
        lhs.id == rhs.id
    }
}

/// Manager for group ride sessions supporting up to 4 riders
/// Extends PeerConnectionService to handle multi-peer communication and music sync
@MainActor
class GroupSessionManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var connectedPeers: [MCPeerID] = []
    @Published var isHost = false
    @Published var groupSize: Int = 0
    @Published var sessionActive = false
    @Published var maxPeersReached = false
    @Published var peerProfiles: [MCPeerID: RiderProfile] = [:] // Phase 21B: Peer profile data
    
    // MARK: - Private Properties
    private let maxPeers = 10 // Phase 21: Support up to 10 riders
    private let serviceType = "branchr-group"
    private let myPeerID: MCPeerID
    private var session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    // MARK: - Initialization
    override init() {
        // Create unique peer ID based on device name
        let deviceName = UIDevice.current.name
        self.myPeerID = MCPeerID(displayName: deviceName)
        
        // Initialize session with required encryption
        self.session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        
        super.init()
        
        // Set session delegate
        self.session.delegate = self
        
        print("Branchr GroupSessionManager initialized for: \(deviceName)")
    }
    
    // MARK: - Public Methods
    
    /// Start hosting a group ride session
    func startGroupSession() {
        guard !sessionActive else { return }
        
        isHost = true
        sessionActive = true
        groupSize = 1
        
        let discoveryInfo = [
            "app": "branchr",
            "version": "1.0",
            "mode": "group",
            "host": myPeerID.displayName
        ]
        
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: discoveryInfo, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        
        // Phase 21: Also start browsing to connect with nearby riders
        if browser == nil {
            browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
            browser?.delegate = self
            browser?.startBrowsingForPeers()
        }
        
        print("Branchr: Started hosting group session (up to \(maxPeers) riders)")
    }
    
    /// Join an existing group ride session
    func joinGroupSession() {
        guard !sessionActive else { return }
        
        isHost = false
        sessionActive = true
        
        // Phase 21: Start browsing and advertising to connect
        if browser == nil {
            browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
            browser?.delegate = self
            browser?.startBrowsingForPeers()
        }
        
        // Also advertise to allow others to find us
        if advertiser == nil {
            let discoveryInfo = [
                "app": "branchr",
                "version": "1.0",
                "mode": "group"
            ]
            advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: discoveryInfo, serviceType: serviceType)
            advertiser?.delegate = self
            advertiser?.startAdvertisingPeer()
        }
        
        print("Branchr: Started browsing for group sessions")
    }
    
    /// Leave the current group session
    func leaveGroupSession() {
        sessionActive = false
        isHost = false
        groupSize = 0
        connectedPeers.removeAll()
        maxPeersReached = false
        
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        
        browser?.stopBrowsingForPeers()
        browser = nil
        
        session.disconnect()
        
        print("Branchr: Left group session")
    }
    
    /// Send data to all connected peers
    func broadcastToPeers(_ data: Data) {
        guard !connectedPeers.isEmpty else { return }
        
        do {
            try session.send(data, toPeers: connectedPeers, with: .reliable)
        } catch {
            print("Branchr: Failed to broadcast data: \(error)")
        }
    }
    
    /// Send data to a specific peer
    func sendToPeer(_ data: Data, peer: MCPeerID) {
        do {
            try session.send(data, toPeers: [peer], with: .reliable)
        } catch {
            print("Branchr: Failed to send data to \(peer.displayName): \(error)")
        }
    }
    
    /// Invite a discovered peer to join the group
    func invitePeer(_ peer: MCPeerID) {
        guard let browser = browser, groupSize < maxPeers else { return }
        
        browser.invitePeer(peer, to: session, withContext: nil, timeout: 30)
        print("Branchr: Inviting \(peer.displayName) to group session")
    }
    
    /// Get current peer's display name
    var myDisplayName: String {
        return myPeerID.displayName
    }
    
    /// Check if session is at capacity
    var isAtCapacity: Bool {
        return groupSize >= maxPeers
    }
    
    /// Get available slots
    var availableSlots: Int {
        return max(0, maxPeers - groupSize)
    }
    
    // MARK: - Phase 20: Host Controls & Broadcasts
    
    /// Broadcast mute all voices command (host only)
    func broadcastMuteAllVoices() {
        guard isHost else { return }
        let command = ["action": "muteAllVoices"]
        if let data = try? JSONSerialization.data(withJSONObject: command) {
            broadcastToPeers(data)
            print("Branchr: Host broadcasted mute all voices")
        }
    }
    
    /// Broadcast mute all music command (host only)
    func broadcastMusicMuteAll() {
        guard isHost else { return }
        let command = ["action": "muteAllMusic"]
        if let data = try? JSONSerialization.data(withJSONObject: command) {
            broadcastToPeers(data)
            print("Branchr: Host broadcasted mute all music")
        }
    }
    
    /// Trigger SOS emergency (host only)
    func triggerSOS() {
        guard isHost else { return }
        let command = ["action": "sos"]
        if let data = try? JSONSerialization.data(withJSONObject: command) {
            broadcastToPeers(data)
            print("Branchr: Host triggered SOS")
            
            // Also call emergency services
            if let url = URL(string: "tel://911") {
                UIApplication.shared.open(url)
            }
        }
    }
    
    /// End group session
    func endGroupSession() {
        let command = ["action": "endSession"]
        if let data = try? JSONSerialization.data(withJSONObject: command) {
            broadcastToPeers(data)
        }
        
        leaveGroupSession()
        print("Branchr: Group session ended")
    }
    
    // MARK: - Phase 21B: Profile Broadcasting
    
    /// Broadcast current user's profile to all connected peers
    func broadcastProfile() {
        guard !connectedPeers.isEmpty else { return }
        
        let userName = UserDefaults.standard.string(forKey: "userName") ?? "Rider"
        let userBio = UserDefaults.standard.string(forKey: "userBio") ?? "Let's ride together!"
        let imageData = UserDefaults.standard.data(forKey: "profileImageData")
        
        var payload: [String: Any] = [
            "type": "profile",
            "name": userName,
            "bio": userBio
        ]
        
        if let data = imageData {
            payload["imageData"] = data.base64EncodedString()
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            print("Branchr: Failed to serialize profile data")
            return
        }
        
        do {
            try session.send(jsonData, toPeers: connectedPeers, with: .reliable)
            print("Branchr: Broadcasted profile to \(connectedPeers.count) peer(s)")
        } catch {
            print("Branchr: Failed to broadcast profile: \(error)")
        }
    }
    
    /// Get profile for a specific peer (or default if not available)
    func getProfile(for peerID: MCPeerID) -> RiderProfile {
        if let profile = peerProfiles[peerID] {
            return profile
        }
        // Return default profile with device name
        return RiderProfile(name: peerID.displayName, bio: "", image: nil)
    }
    
    /// Get current user's profile
    var myProfile: RiderProfile {
        let userName = UserDefaults.standard.string(forKey: "userName") ?? "Rider"
        let userBio = UserDefaults.standard.string(forKey: "userBio") ?? "Let's ride together!"
        let imageData = UserDefaults.standard.data(forKey: "profileImageData")
        let image = imageData.flatMap { UIImage(data: $0) }
        
        return RiderProfile(name: userName, bio: userBio, image: image)
    }
}

// MARK: - MCSessionDelegate
extension GroupSessionManager: MCSessionDelegate {
    
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                    self.groupSize = self.connectedPeers.count + 1 // +1 for self
                    self.maxPeersReached = self.groupSize >= self.maxPeers
                    
                    // Phase 21B: Broadcast our profile when peer connects
                    self.broadcastProfile()
                }
                print("Branchr: \(peerID.displayName) joined group session")
                
            case .connecting:
                print("Branchr: \(peerID.displayName) is connecting to group...")
                
            case .notConnected:
                self.connectedPeers.removeAll { $0 == peerID }
                self.groupSize = self.connectedPeers.count + 1 // +1 for self
                self.maxPeersReached = self.groupSize >= self.maxPeers
                print("Branchr: \(peerID.displayName) left group session")
                
            @unknown default:
                print("Branchr: Unknown connection state for \(peerID.displayName)")
            }
        }
    }
    
    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            // Phase 21B: Handle profile data
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let type = json["type"] as? String, type == "profile" {
                // Profile data received
                let name = json["name"] as? String ?? peerID.displayName
                let bio = json["bio"] as? String ?? ""
                var image: UIImage? = nil
                
                if let base64String = json["imageData"] as? String,
                   let imageData = Data(base64Encoded: base64String) {
                    image = UIImage(data: imageData)
                }
                
                self.peerProfiles[peerID] = RiderProfile(name: name, bio: bio, image: image)
                print("Branchr: Received profile from \(peerID.displayName): \(name)")
            } else {
                // Other data (music sync, etc.)
                print("Branchr: Received data from \(peerID.displayName)")
                
                // Notify observers about received data
                NotificationCenter.default.post(
                    name: .groupSessionDataReceived,
                    object: nil,
                    userInfo: ["data": data, "peerID": peerID]
                )
            }
        }
    }
    
    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Handle received stream if needed for future features
        print("Branchr: Received stream '\(streamName)' from \(peerID.displayName)")
    }
    
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Handle resource transfer if needed for future features
        print("Branchr: Started receiving resource '\(resourceName)' from \(peerID.displayName)")
    }
    
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Handle completed resource transfer if needed for future features
        if let error = error {
            print("Branchr: Error receiving resource '\(resourceName)' from \(peerID.displayName): \(error)")
        } else {
            print("Branchr: Finished receiving resource '\(resourceName)' from \(peerID.displayName)")
        }
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension GroupSessionManager: MCNearbyServiceAdvertiserDelegate {
    
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        DispatchQueue.main.async {
            print("Branchr: Received group invitation from \(peerID.displayName)")
            
            // Check if we have room for another peer
            if self.groupSize < self.maxPeers {
                invitationHandler(true, self.session)
                print("Branchr: Accepted group invitation from \(peerID.displayName)")
            } else {
                invitationHandler(false, nil)
                print("Branchr: Rejected group invitation from \(peerID.displayName) - group full")
            }
        }
    }
    
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        DispatchQueue.main.async {
            print("Branchr: Failed to start group advertising: \(error)")
            self.sessionActive = false
            self.isHost = false
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension GroupSessionManager: MCNearbyServiceBrowserDelegate {
    
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        DispatchQueue.main.async {
            // Phase 21: Check if we have room and auto-invite
            guard self.groupSize < self.maxPeers else {
                print("Branchr: Found \(peerID.displayName) but group is full")
                return
            }
            
            print("Branchr: Found group host: \(peerID.displayName)")
            
            // Auto-invite to group session
            self.invitePeer(peerID)
        }
    }
    
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            print("Branchr: Lost group host: \(peerID.displayName)")
        }
    }
    
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        DispatchQueue.main.async {
            print("Branchr: Failed to start group browsing: \(error)")
            self.sessionActive = false
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let groupSessionDataReceived = Notification.Name("groupSessionDataReceived")
}
