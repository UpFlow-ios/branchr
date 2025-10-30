//
//  PeerConnectionService.swift
//  branchr
//
//  Created by Joe Dormond on 10/21/25.
//

import Foundation
import MultipeerConnectivity
import SwiftUI

/// Service for managing peer-to-peer connections using MultipeerConnectivity
/// Handles device discovery, invitation, and session management for Branchr voice chat
@MainActor
class PeerConnectionService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var connectedPeers: [MCPeerID] = []
    @Published var isAdvertising = false
    @Published var isBrowsing = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var discoveredPeers: [MCPeerID] = []
    
    // MARK: - Private Properties
    private let serviceType = "branchr-voice"
    private let myPeerID: MCPeerID
    private var session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    // MARK: - Connection Status Enum
    enum ConnectionStatus {
        case disconnected
        case advertising
        case browsing
        case connected
        case connecting
    }
    
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
        
        print("Branchr PeerConnectionService initialized for: \(deviceName)")
    }
    
    // MARK: - Public Methods
    
    /// Start advertising this device for peer discovery
    func startAdvertising() {
        guard !isAdvertising else { return }
        
        let discoveryInfo = ["app": "branchr", "version": "1.0"]
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: discoveryInfo, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        
        isAdvertising = true
        connectionStatus = .advertising
        print("Branchr: Started advertising for peers...")
    }
    
    /// Stop advertising this device
    func stopAdvertising() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        isAdvertising = false
        
        if connectionStatus == .advertising {
            connectionStatus = .disconnected
        }
        print("Branchr: Stopped advertising")
    }
    
    /// Start browsing for nearby devices
    func startBrowsing() {
        guard !isBrowsing else { return }
        
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        
        isBrowsing = true
        connectionStatus = .browsing
        print("Branchr: Started browsing for peers...")
    }
    
    /// Stop browsing for devices
    func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
        isBrowsing = false
        discoveredPeers.removeAll()
        
        if connectionStatus == .browsing {
            connectionStatus = .disconnected
        }
        print("Branchr: Stopped browsing")
    }
    
    /// Start connection process (advertise and browse simultaneously)
    func startConnection() {
        startAdvertising()
        startBrowsing()
    }
    
    /// Stop all connection activities
    func stopConnection() {
        stopAdvertising()
        stopBrowsing()
        disconnect()
    }
    
    /// Send invitation to a discovered peer
    func invitePeer(_ peer: MCPeerID) {
        guard let browser = browser else { return }
        
        connectionStatus = .connecting
        browser.invitePeer(peer, to: session, withContext: nil, timeout: 30)
        print("Branchr: Sending invitation to \(peer.displayName)...")
    }
    
    /// Disconnect from current session
    func disconnect() {
        session.disconnect()
        connectedPeers.removeAll()
        connectionStatus = .disconnected
        print("Branchr: Disconnected from session")
    }
    
    /// Get current peer's display name
    var myDisplayName: String {
        return myPeerID.displayName
    }
    
    /// Check if connected to any peers
    var isConnected: Bool {
        return !connectedPeers.isEmpty
    }
}

// MARK: - MCSessionDelegate
extension PeerConnectionService: MCSessionDelegate {
    
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                }
                self.connectionStatus = .connected
                print("Branchr: Connected to \(peerID.displayName)")
                
            case .connecting:
                self.connectionStatus = .connecting
                print("Branchr: Connecting to \(peerID.displayName)...")
                
            case .notConnected:
                self.connectedPeers.removeAll { $0 == peerID }
                if self.connectedPeers.isEmpty {
                    self.connectionStatus = .disconnected
                }
                print("Branchr: Disconnected from \(peerID.displayName)")
                
            @unknown default:
                print("Branchr: Unknown connection state for \(peerID.displayName)")
            }
        }
    }
    
    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // Handle received data if needed for future features
        print("Branchr: Received data from \(peerID.displayName)")
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
extension PeerConnectionService: MCNearbyServiceAdvertiserDelegate {
    
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        DispatchQueue.main.async {
            print("Branchr: Received invitation from \(peerID.displayName)")
            
            // Auto-accept invitations for now (can be made configurable later)
            invitationHandler(true, self.session)
        }
    }
    
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        DispatchQueue.main.async {
            print("Branchr: Failed to start advertising: \(error)")
            self.isAdvertising = false
            self.connectionStatus = .disconnected
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension PeerConnectionService: MCNearbyServiceBrowserDelegate {
    
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        DispatchQueue.main.async {
            if !self.discoveredPeers.contains(peerID) && peerID != self.myPeerID {
                self.discoveredPeers.append(peerID)
                print("Branchr: Found peer: \(peerID.displayName)")
            }
        }
    }
    
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.discoveredPeers.removeAll { $0 == peerID }
            print("Branchr: Lost peer: \(peerID.displayName)")
        }
    }
    
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        DispatchQueue.main.async {
            print("Branchr: Failed to start browsing: \(error)")
            self.isBrowsing = false
            self.connectionStatus = .disconnected
        }
    }
}
