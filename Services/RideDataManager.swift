//
//  RideDataManager.swift
//  branchr
//
//  Created by Joe Dormond on 10/23/25.
//

import Foundation
import CoreLocation
import Combine
import CloudKit
import FirebaseAuth

/// Codable wrapper for CLLocationCoordinate2D
struct CoordinateData: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    
    init(from coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

/// Data model for storing ride information
struct RideRecord: Identifiable, Codable, Equatable {
    var id: UUID
    var date: Date
    var distance: Double // meters
    var duration: TimeInterval
    var averageSpeed: Double // m/s
    var calories: Double // kcal
    var route: [CoordinateData]
    var title: String?
    
    init(id: UUID = UUID(), 
         date: Date = Date(), 
         distance: Double, 
         duration: TimeInterval, 
         averageSpeed: Double, 
         calories: Double = 0.0,
         route: [CLLocationCoordinate2D],
         title: String? = nil) {
        self.id = id
        self.date = date
        self.distance = distance
        self.duration = duration
        self.averageSpeed = averageSpeed
        self.calories = calories
        self.route = route.map { CoordinateData(from: $0) }
        self.title = title
    }
}

/// Manager for persisting ride data locally
@MainActor
class RideDataManager: ObservableObject {
    
    // MARK: - Shared Instance (Phase 30)
    static let shared = RideDataManager()
    
    // MARK: - Published Properties
    @Published var rides: [RideRecord] = []
    
    // MARK: - Private Properties
    private let fileName = "branchr_rides.json"
    private let cloudSyncService = RideCloudSyncService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    private var fileURL: URL {
        documentsDirectory.appendingPathComponent(fileName)
    }
    
    // MARK: - Initialization
    init() {
        rides = loadRides()
        setupCloudSync()
        // Phase 32: Load rides from Firebase on init
        loadRidesFromFirebase()
        print("Branchr RideDataManager initialized with \(rides.count) rides")
    }
    
    // MARK: - Public Methods
    
    /// Save a ride to local storage
    func saveRide(_ ride: RideRecord) {
        rides.insert(ride, at: 0) // Add to beginning for newest first
        saveToFile()
        
        // Post notification that rides changed
        NotificationCenter.default.post(
            name: .branchrRidesDidChange,
            object: nil
        )
        
        // Sync to iCloud
        cloudSyncService.uploadRide(
            distance: ride.distance,
            duration: ride.duration,
            calories: ride.calories,
            mode: .ride // TODO: Get actual mode from ride
        )
        
        print("Branchr: Saved ride - \(ride.formattedDistance) in \(ride.formattedDuration)")
    }
    
    /// Load all rides from local storage
    func loadRides() -> [RideRecord] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("Branchr: No rides file found, starting with empty array")
            return []
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            rides = try decoder.decode([RideRecord].self, from: data)
            print("Branchr: Loaded \(rides.count) rides from storage")
            return rides
        } catch {
            print("Branchr: Failed to load rides - \(error.localizedDescription)")
            // If decoding fails, start with empty array and let new format take over
            rides = []
            saveToFile() // Write empty array in new format
            return []
        }
    }
    
    /// Clear all saved rides
    func clearAll() {
        rides.removeAll()
        saveToFile()
        print("Branchr: Cleared all rides")
    }
    
    /// Delete a specific ride
    func deleteRide(_ ride: RideRecord) {
        rides.removeAll { $0.id == ride.id }
        saveToFile()
        print("Branchr: Deleted ride \(ride.id)")
    }
    
    /// Get total distance of all rides
    var totalDistance: Double {
        return rides.reduce(0) { $0 + $1.distance }
    }
    
    /// Get total duration of all rides
    var totalDuration: TimeInterval {
        return rides.reduce(0) { $0 + $1.duration }
    }
    
    /// Get number of rides
    var rideCount: Int {
        return rides.count
    }
    
    // MARK: - Phase 34: Calendar Summary
    
    /// Get ride summary for a specific day
    func summary(for date: Date) -> DayRideSummary? {
        let calendar = Calendar.current
        let dayRides = rides.filter { calendar.isDate($0.date, inSameDayAs: date) }
        
        guard !dayRides.isEmpty else { return nil }
        
        let totalDistance = dayRides.reduce(0) { $0 + $1.distance }
        let totalDuration = dayRides.reduce(0) { $0 + $1.duration }
        
        return DayRideSummary(
            date: date,
            rides: dayRides,
            totalDistance: totalDistance,
            totalDuration: totalDuration
        )
    }
}

// MARK: - Phase 34: Day Ride Summary

struct DayRideSummary {
    let date: Date
    let rides: [RideRecord]
    let totalDistance: Double // meters
    let totalDuration: TimeInterval
    
    var totalDistanceInMiles: Double {
        totalDistance / 1609.34
    }
    
    var formattedDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Phase 32: Firebase Sync Extension
extension RideDataManager {
    
    /// Load rides from Firebase and merge with local rides
    func loadRidesFromFirebase() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("⚠️ RideDataManager: No user logged in, skipping Firebase fetch")
            return
        }
        
        FirebaseRideService.shared.fetchRides(for: userId) { [weak self] firebaseRides in
            guard let self = self else { return }
            DispatchQueue.main.async {
                // Convert Firebase RideData to RideRecord
                let newRides = firebaseRides.compactMap { firebaseRide -> RideRecord? in
                    // Check if ride already exists locally
                    let existingIds = Set(self.rides.map { $0.id.uuidString })
                    if existingIds.contains(firebaseRide.id) {
                        return nil // Skip duplicates
                    }
                    
                    // Convert route data back to coordinates
                    let coordinates = firebaseRide.route.compactMap { coordArray -> CLLocationCoordinate2D? in
                        guard coordArray.count >= 2 else { return nil }
                        return CLLocationCoordinate2D(latitude: coordArray[0], longitude: coordArray[1])
                    }
                    
                    return RideRecord(
                        id: UUID(uuidString: firebaseRide.id) ?? UUID(),
                        date: firebaseRide.date,
                        distance: firebaseRide.distance,
                        duration: firebaseRide.duration,
                        averageSpeed: firebaseRide.avgSpeed / 3.6, // Convert km/h to m/s
                        calories: 0,
                        route: coordinates
                    )
                }
                
                if !newRides.isEmpty {
                    self.rides.append(contentsOf: newRides)
                    self.rides.sort { $0.date > $1.date } // Sort by date, newest first
                    self.saveToFile()
                    print("✅ RideDataManager: Synced \(newRides.count) rides from Firebase")
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func saveToFile() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(rides)
            try data.write(to: fileURL)
            print("Branchr: Saved \(rides.count) rides to file")
        } catch {
            print("Branchr: Failed to save rides - \(error.localizedDescription)")
        }
    }
}

// MARK: - RideRecord Extensions
extension RideRecord {
    
    /// Distance in miles
    var distanceInMiles: Double {
        return distance * 0.000621371
    }
    
    /// Distance in kilometers
    var distanceInKilometers: Double {
        return distance / 1000.0
    }
    
    /// Average speed in mph
    var averageSpeedInMPH: Double {
        return averageSpeed * 2.23694
    }
    
    /// Average speed in km/h
    var averageSpeedInKPH: Double {
        return averageSpeed * 3.6
    }
    
    /// Formatted distance based on locale
    var formattedDistance: String {
        let locale = Locale.current
        let isMetric = locale.usesMetricSystem
        
        if isMetric {
            return String(format: "%.2f km", distanceInKilometers)
        } else {
            return String(format: "%.2f mi", distanceInMiles)
        }
    }
    
    /// Formatted duration
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    /// Formatted average speed based on locale
    var formattedAverageSpeed: String {
        let locale = Locale.current
        let isMetric = locale.usesMetricSystem
        
        if isMetric {
            return String(format: "%.1f km/h", averageSpeedInKPH)
        } else {
            return String(format: "%.1f mph", averageSpeedInMPH)
        }
    }
    
    /// Formatted calories burned
    var formattedCalories: String {
        return String(format: "%.0f cal", calories)
    }
    
    /// Formatted date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Display title (custom or generated)
    var displayTitle: String {
        if let title = title, !title.isEmpty {
            return title
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return "Ride on \(formatter.string(from: date))"
        }
    }
    
    /// Route as CLLocationCoordinate2D array
    var coordinateRoute: [CLLocationCoordinate2D] {
        return route.map { $0.coordinate }
    }
}

// MARK: - Cloud Sync Extension
extension RideDataManager {
    
    /// Setup cloud sync functionality
    private func setupCloudSync() {
        // Listen for cloud sync events
        cloudSyncService.$isSyncing
            .sink { [weak self] isSyncing in
                if isSyncing {
                    print("☁️ Cloud sync started")
                } else {
                    print("☁️ Cloud sync completed")
                }
            }
            .store(in: &cancellables)
    }
    
    /// Sync all rides to iCloud
    func syncAllRidesToCloud() {
        cloudSyncService.syncAllRides(from: self)
    }
    
    /// Fetch rides from iCloud
    func fetchRidesFromCloud() {
        cloudSyncService.fetchRides { [weak self] records in
            DispatchQueue.main.async {
                self?.processCloudRides(records)
            }
        }
    }
    
    /// Process rides fetched from iCloud
    private func processCloudRides(_ records: [CKRecord]) {
        var newRides: [RideRecord] = []
        
        for record in records {
            guard let distance = record["distance"] as? Double,
                  let duration = record["duration"] as? TimeInterval,
                  let calories = record["calories"] as? Double,
                  let date = record["date"] as? Date else {
                continue
            }
            
            let ride = RideRecord(
                id: UUID(),
                date: date,
                distance: distance,
                duration: duration,
                averageSpeed: distance / duration,
                calories: calories,
                route: [] // Cloud rides don't store route data
            )
            
            // Check if this ride already exists locally
            if !rides.contains(where: { $0.id == ride.id }) {
                newRides.append(ride)
            }
        }
        
        if !newRides.isEmpty {
            rides.append(contentsOf: newRides)
            rides.sort { $0.date > $1.date } // Sort by date, newest first
            saveToFile()
            print("☁️ Added \(newRides.count) rides from iCloud")
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let branchrRidesDidChange = Notification.Name("branchr.rides.changed")
}
