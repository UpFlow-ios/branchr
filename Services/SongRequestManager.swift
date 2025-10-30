//
//  SongRequestManager.swift
//  branchr
//
//  Created by Joe Dormond on 10/24/25.
//

import Foundation
import Combine
import MultipeerConnectivity

/// Data model for song requests from riders to host
struct SongRequest: Identifiable, Codable {
    var id: UUID
    var requestedBy: String
    var title: String
    var artist: String?
    var timestamp: Date
    var status: RequestStatus
    
    init(id: UUID = UUID(), requestedBy: String, title: String, artist: String? = nil, timestamp: Date = Date(), status: RequestStatus = .pending) {
        self.id = id
        self.requestedBy = requestedBy
        self.title = title
        self.artist = artist
        self.timestamp = timestamp
        self.status = status
    }
}

/// Status of a song request
enum RequestStatus: String, Codable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
    case played = "played"
}

/// Manager for handling song requests between riders and host DJ
final class SongRequestManager: NSObject, ObservableObject {
    @Published var pendingRequests: [SongRequest] = []
    @Published var requestHistory: [SongRequest] = []
    
    private var groupSessionManager: GroupSessionManager?
    private let maxHistoryCount = 50
    
    override init() {
        super.init()
        print("Branchr: SongRequestManager initialized")
    }
    
    /// Set the group session manager for communication
    func setGroupSessionManager(_ manager: GroupSessionManager) {
        self.groupSessionManager = manager
    }
    
    /// Send a song request to the host DJ
    func sendRequest(title: String, artist: String?, requestedBy: String) async {
        let request = SongRequest(
            requestedBy: requestedBy,
            title: title,
            artist: artist
        )
        
        do {
            let data = try JSONEncoder().encode(request)
            let command = MusicCommand.songRequest(data)
            await groupSessionManager?.broadcastToPeers(command.data)
            print("Branchr: Sent song request: \(title) - \(artist ?? "Unknown Artist")")
        } catch {
            print("Branchr: Failed to encode song request: \(error)")
        }
    }
    
    /// Receive a song request (host only)
    func receiveRequest(_ request: SongRequest) {
        // Check if request already exists
        if !pendingRequests.contains(where: { $0.id == request.id }) {
            pendingRequests.append(request)
            print("Branchr: Received song request from \(request.requestedBy): \(request.title)")
        }
    }
    
    /// Approve a song request (host only)
    func approveRequest(_ request: SongRequest) async {
        guard let index = pendingRequests.firstIndex(where: { $0.id == request.id }) else { return }
        
        var approvedRequest = request
        approvedRequest.status = .approved
        
        // Move from pending to history
        pendingRequests.remove(at: index)
        addToHistory(approvedRequest)
        
        // Broadcast approval to all riders
        await broadcastRequestUpdate(approvedRequest)
        
        print("Branchr: Approved song request: \(request.title)")
    }
    
    /// Reject a song request (host only)
    func rejectRequest(_ request: SongRequest) async {
        guard let index = pendingRequests.firstIndex(where: { $0.id == request.id }) else { return }
        
        var rejectedRequest = request
        rejectedRequest.status = .rejected
        
        // Move from pending to history
        pendingRequests.remove(at: index)
        addToHistory(rejectedRequest)
        
        // Broadcast rejection to all riders
        await broadcastRequestUpdate(rejectedRequest)
        
        print("Branchr: Rejected song request: \(request.title)")
    }
    
    /// Clear a specific request
    func clearRequest(_ id: UUID) {
        pendingRequests.removeAll { $0.id == id }
        requestHistory.removeAll { $0.id == id }
    }
    
    /// Clear all pending requests
    func clearAllPendingRequests() {
        pendingRequests.removeAll()
    }
    
    /// Mark a request as played (host only)
    func markAsPlayed(_ request: SongRequest) async {
        guard let index = requestHistory.firstIndex(where: { $0.id == request.id }) else { return }
        
        var playedRequest = request
        playedRequest.status = .played
        
        requestHistory[index] = playedRequest
        
        // Broadcast update
        await broadcastRequestUpdate(playedRequest)
        
        print("Branchr: Marked song as played: \(request.title)")
    }
    
    /// Add request to history with size limit
    private func addToHistory(_ request: SongRequest) {
        requestHistory.insert(request, at: 0)
        
        // Keep history size manageable
        if requestHistory.count > maxHistoryCount {
            requestHistory = Array(requestHistory.prefix(maxHistoryCount))
        }
    }
    
    /// Broadcast request update to all riders
    private func broadcastRequestUpdate(_ request: SongRequest) async {
        do {
            let data = try JSONEncoder().encode(request)
            let command = MusicCommand.songRequest(data)
            await groupSessionManager?.broadcastToPeers(command.data)
        } catch {
            print("Branchr: Failed to encode request update: \(error)")
        }
    }
    
    /// Get requests by a specific rider
    func getRequestsByRider(_ riderName: String) -> [SongRequest] {
        return requestHistory.filter { $0.requestedBy == riderName }
    }
    
    /// Get pending requests count
    var pendingCount: Int {
        return pendingRequests.count
    }
    
    /// Get approved requests count
    var approvedCount: Int {
        return requestHistory.filter { $0.status == .approved }.count
    }
    
    /// Get rejected requests count
    var rejectedCount: Int {
        return requestHistory.filter { $0.status == .rejected }.count
    }
    
    /// Get most recent requests
    func getRecentRequests(limit: Int = 10) -> [SongRequest] {
        return Array(requestHistory.prefix(limit))
    }
    
    /// Check if a rider has pending requests
    func hasPendingRequests(for riderName: String) -> Bool {
        return pendingRequests.contains { $0.requestedBy == riderName }
    }
    
    /// Get the oldest pending request
    var oldestPendingRequest: SongRequest? {
        return pendingRequests.min { $0.timestamp < $1.timestamp }
    }
    
    /// Get the newest pending request
    var newestPendingRequest: SongRequest? {
        return pendingRequests.max { $0.timestamp < $1.timestamp }
    }
}
