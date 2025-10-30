//
//  RideCloudSyncService.swift
//  branchr
//
//  Created by Joe Dormond on 2025-10-25.
//

import Foundation
import CloudKit
import Combine

/// Handles syncing ride data to and from iCloud using CloudKit
final class RideCloudSyncService: ObservableObject {
    static let shared = RideCloudSyncService()
    
    private let container = CKContainer.default()
    private let privateDB = CKContainer.default().privateCloudDatabase
    
    @Published var isSyncing = false
    @Published var lastSync: Date? = nil
    @Published var syncError: String? = nil
    
    private init() {
        // Load last sync date from UserDefaults
        if let lastSyncData = UserDefaults.standard.data(forKey: "lastCloudSync"),
           let lastSyncDate = try? JSONDecoder().decode(Date.self, from: lastSyncData) {
            self.lastSync = lastSyncDate
        }
    }
    
    // MARK: - Public Methods
    
    /// Upload a ride to iCloud
    func uploadRide(distance: Double, duration: TimeInterval, calories: Double, mode: BranchrMode = .ride) {
        let record = CKRecord(recordType: "Ride")
        record["distance"] = distance
        record["duration"] = duration
        record["calories"] = calories
        record["date"] = Date()
        record["mode"] = mode.rawValue
        
        isSyncing = true
        syncError = nil
        
        privateDB.save(record) { [weak self] _, error in
            DispatchQueue.main.async {
                self?.isSyncing = false
                if let error = error {
                    self?.syncError = error.localizedDescription
                    print("❌ Ride upload failed: \(error.localizedDescription)")
                } else {
                    self?.lastSync = Date()
                    self?.saveLastSyncDate()
                    print("☁️ Ride synced to iCloud")
                }
            }
        }
    }
    
    /// Fetch all rides from iCloud
    func fetchRides(completion: @escaping ([CKRecord]) -> Void) {
        let query = CKQuery(recordType: "Ride", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        privateDB.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: CKQueryOperation.maximumResults) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let queryResult):
                    let records = queryResult.matchResults.compactMap { _, recordResult in
                        switch recordResult {
                        case .success(let record):
                            return record
                        case .failure:
                            return nil
                        }
                    }
                    completion(records)
                    print("☁️ Fetched \(records.count) rides from iCloud")
                case .failure(let error):
                    print("⚠️ Fetch error: \(error.localizedDescription)")
                    completion([])
                }
            }
        }
    }
    
    /// Sync all local rides to iCloud
    @MainActor
    func syncAllRides(from rideDataManager: RideDataManager) {
        guard !isSyncing else { return }
        
        isSyncing = true
        syncError = nil
        
        let rides = rideDataManager.rides
        var completedUploads = 0
        let totalRides = rides.count
        
        if totalRides == 0 {
            isSyncing = false
            return
        }
        
        for ride in rides {
            let record = CKRecord(recordType: "Ride")
            record["distance"] = ride.distance
            record["duration"] = ride.duration
            record["calories"] = ride.calories
            record["date"] = ride.date
            record["mode"] = BranchrMode.ride.rawValue // Default to ride mode
            
            privateDB.save(record) { [weak self] _, error in
                Task { @MainActor in
                    completedUploads += 1
                    
                    if let error = error {
                        print("❌ Failed to sync ride: \(error.localizedDescription)")
                    } else {
                        print("☁️ Synced ride \(completedUploads)/\(totalRides)")
                    }
                    
                    if completedUploads == totalRides {
                        self?.isSyncing = false
                        self?.lastSync = Date()
                        self?.saveLastSyncDate()
                        print("☁️ All rides synced to iCloud")
                    }
                }
            }
        }
    }
    
    /// Check iCloud account status
    func checkAccountStatus(completion: @escaping (CKAccountStatus) -> Void) {
        container.accountStatus { status, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Account status check failed: \(error.localizedDescription)")
                }
                completion(status)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func saveLastSyncDate() {
        if let lastSync = lastSync,
           let data = try? JSONEncoder().encode(lastSync) {
            UserDefaults.standard.set(data, forKey: "lastCloudSync")
        }
    }
}
