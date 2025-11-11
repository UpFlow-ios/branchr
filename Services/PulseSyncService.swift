//
//  PulseSyncService.swift
//  branchr
//
//  Created for Smart Group Ride System - Network-Synced Rainbow Pulse
//

import Foundation
import Combine

/**
 * 🌈 Pulse Sync Service
 *
 * Handles syncing of the pulse phase between host and connected riders.
 * When host starts a group ride, all connected riders' buttons pulse in perfect synchronization.
 * Phase 35.3: @MainActor for concurrency safety.
 */
@MainActor
final class PulseSyncService: ObservableObject {
    static let shared = PulseSyncService()
    
    @Published var syncPhase: Double = 0.0 // 0.0 - 1.0 pulse progress
    @Published var isSynced: Bool = false
    
    private var timer: Timer?
    private var startTime: TimeInterval?
    private let pulseCycleDuration: TimeInterval = 1.6 // matches pulse animation duration
    
    private init() {
        print("🌈 PulseSyncService initialized")
    }
    
    // MARK: - Start Sync
    
    func startSync(withHostTimestamp timestamp: TimeInterval) {
        self.startTime = timestamp
        self.isSynced = true
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.startTime else { return }
            let elapsed = Date().timeIntervalSince1970 - start
            self.syncPhase = (elapsed.truncatingRemainder(dividingBy: self.pulseCycleDuration)) / self.pulseCycleDuration
        }
        
        print("🌈 Pulse sync started with timestamp: \(timestamp)")
    }
    
    // MARK: - Stop Sync
    
    func stopSync() {
        timer?.invalidate()
        timer = nil
        isSynced = false
        syncPhase = 0.0
        startTime = nil
        print("🌈 Pulse sync stopped")
    }
    
    // MARK: - Host Broadcast
    
    func generateHostTimestamp() -> TimeInterval {
        let timestamp = Date().timeIntervalSince1970
        startSync(withHostTimestamp: timestamp)
        print("🌈 Host broadcasted pulse timestamp: \(timestamp)")
        return timestamp
    }
    
    // MARK: - Receive Sync From Network
    
    func handleReceivedSync(timestamp: TimeInterval) {
        startSync(withHostTimestamp: timestamp)
        print("🌈 Received pulse sync from host: \(timestamp)")
    }
}

