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
        // Phase 47: Strictly filter rides by exact calendar day
        let dayRides = rides.filter { calendar.isDate($0.date, inSameDayAs: date) }
        
        // Phase 47: Debug logging
        print("📆 RideDataManager.summary(for: \(date)): found \(dayRides.count) rides")
        
        guard !dayRides.isEmpty else { return nil }
        
        let totalDistance = dayRides.reduce(0) { $0 + $1.distance }
        let totalDuration = dayRides.reduce(0) { $0 + $1.duration }
        
        return DayRideSummary(
            date: calendar.startOfDay(for: date), // Phase 47: Normalize to start of day
            rides: dayRides,
            totalDistance: totalDistance,
            totalDuration: totalDuration
        )
    }
    
    // MARK: - Phase 38: Trend Data & Aggregation
    
    /// Compute daily trend data for the last N days
    /// Groups rides by calendar day and aggregates distance, duration, and average speed
    /// Returns points sorted by date ascending, including days with zero rides
    func recentDailyTrend(lastNDays: Int = 7) -> [RideTrendPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Generate all days in the range (including days with no rides)
        var trendPoints: [RideTrendPoint] = []
        
        for dayOffset in (0..<lastNDays).reversed() {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let dayStart = calendar.startOfDay(for: day)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            // Filter rides for this day
            let dayRides = rides.filter { ride in
                ride.date >= dayStart && ride.date < dayEnd
            }
            
            // Aggregate metrics
            let totalDistanceMeters = dayRides.reduce(0.0) { $0 + $1.distance }
            let totalDistanceMiles = totalDistanceMeters / 1609.34
            let totalDurationSeconds = dayRides.reduce(0.0) { $0 + $1.duration }
            
            // Calculate average speed: total distance / total time (convert to mph)
            let averageSpeedMph: Double
            if totalDurationSeconds > 0 && totalDistanceMiles > 0 {
                let avgSpeedMps = totalDistanceMeters / totalDurationSeconds
                averageSpeedMph = avgSpeedMps * 2.237 // m/s to mph
            } else {
                averageSpeedMph = 0.0
            }
            
            trendPoints.append(RideTrendPoint(
                date: dayStart,
                totalDistanceMiles: totalDistanceMiles,
                totalDurationSeconds: totalDurationSeconds,
                averageSpeedMph: averageSpeedMph
            ))
        }
        
        print("📊 RideDataManager: computed daily trend for \(trendPoints.count) days")
        return trendPoints
    }
    
    /// Compute weekly summary comparing this week vs last week
    /// Uses calendar weeks starting on Sunday (standard iOS calendar)
    /// Returns (thisWeekMiles, lastWeekMiles)
    func weeklySummary() -> (thisWeekMiles: Double, lastWeekMiles: Double) {
        let calendar = Calendar.current
        let today = Date()
        
        // Get start of this week (Sunday)
        let thisWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let thisWeekEnd = calendar.date(byAdding: .day, value: 7, to: thisWeekStart)!
        
        // Get start of last week
        let lastWeekStart = calendar.date(byAdding: .day, value: -7, to: thisWeekStart)!
        let lastWeekEnd = thisWeekStart
        
        // Filter rides for this week
        let thisWeekRides = rides.filter { ride in
            ride.date >= thisWeekStart && ride.date < thisWeekEnd
        }
        let thisWeekMiles = thisWeekRides.reduce(0.0) { $0 + ($1.distance / 1609.34) }
        
        // Filter rides for last week
        let lastWeekRides = rides.filter { ride in
            ride.date >= lastWeekStart && ride.date < lastWeekEnd
        }
        let lastWeekMiles = lastWeekRides.reduce(0.0) { $0 + ($1.distance / 1609.34) }
        
        print("📊 RideDataManager: weekly summary – thisWeek=\(String(format: "%.2f", thisWeekMiles)), lastWeek=\(String(format: "%.2f", lastWeekMiles))")
        
        return (thisWeekMiles, lastWeekMiles)
    }
    
    // MARK: - Phase 41: Weekly Goal & Streak Helpers
    
    /// Compute total distance for the current calendar week (starting Sunday)
    /// - Returns: Total distance in miles, rounded to 2 decimal places
    func totalDistanceThisWeek() -> Double {
        let calendar = Calendar.current
        let today = Date()
        
        // Get start of this week (Sunday)
        let thisWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let thisWeekEnd = calendar.date(byAdding: .day, value: 7, to: thisWeekStart)!
        
        // Filter rides for this week
        let thisWeekRides = rides.filter { ride in
            ride.date >= thisWeekStart && ride.date < thisWeekEnd
        }
        
        let totalMeters = thisWeekRides.reduce(0.0) { $0 + $1.distance }
        let totalMiles = totalMeters / 1609.34
        let rounded = (totalMiles * 100).rounded() / 100 // Round to 2 decimal places
        
        print("📊 RideDataManager: totalDistanceThisWeek = \(String(format: "%.2f", rounded)) mi")
        return rounded
    }
    
    /// Compute consecutive days with at least one ride, ending on today
    /// - Returns: Number of consecutive days (0 if no recent rides)
    func currentStreakDays() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Group rides by day
        var ridesByDay: [Date: [RideRecord]] = [:]
        for ride in rides {
            let day = calendar.startOfDay(for: ride.date)
            ridesByDay[day, default: []].append(ride)
        }
        
        // Count consecutive days backward from today
        var streak = 0
        var currentDay = today
        
        while true {
            if ridesByDay[currentDay] != nil && !ridesByDay[currentDay]!.isEmpty {
                streak += 1
                // Move to previous day
                if let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDay) {
                    currentDay = previousDay
                } else {
                    break
                }
            } else {
                // No rides on this day - streak ends
                break
            }
        }
        
        print("📊 RideDataManager: currentStreakDays = \(streak)")
        return streak
    }
    
    // MARK: - Phase 49: Monthly Stats Helper
    
    /// Get all rides for a specific month
    /// - Parameter month: A date within the target month
    /// - Returns: Array of rides in that month
    func ridesForMonth(_ month: Date) -> [RideRecord] {
        let calendar = Calendar.current
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
              let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
            return []
        }
        
        return rides.filter { ride in
            ride.date >= monthStart && ride.date < monthEnd
        }
    }
    
    /// Compute monthly summary statistics
    /// - Parameter month: A date within the target month
    /// - Returns: Monthly stats (total distance, time, rides, averages)
    func monthSummary(for month: Date) -> MonthRideSummary {
        let monthRides = ridesForMonth(month)
        let calendar = Calendar.current
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
            return MonthRideSummary(month: month, rides: [], totalDistance: 0, totalDuration: 0, totalRides: 0, averageDistance: 0, averageSpeed: 0)
        }
        
        let totalDistance = monthRides.reduce(0.0) { $0 + $1.distance }
        let totalDuration = monthRides.reduce(0.0) { $0 + $1.duration }
        let totalRides = monthRides.count
        
        let averageDistance = totalRides > 0 ? (totalDistance / 1609.34) / Double(totalRides) : 0.0
        
        // Calculate average speed: weighted average of all rides
        let averageSpeed: Double
        if totalDuration > 0 && totalDistance > 0 {
            let totalDistanceMiles = totalDistance / 1609.34
            let totalTimeHours = totalDuration / 3600.0
            averageSpeed = totalDistanceMiles / totalTimeHours
        } else {
            averageSpeed = 0.0
        }
        
        return MonthRideSummary(
            month: monthStart,
            rides: monthRides,
            totalDistance: totalDistance,
            totalDuration: totalDuration,
            totalRides: totalRides,
            averageDistance: averageDistance,
            averageSpeed: averageSpeed
        )
    }
    
    /// Get daily distance data for a specific month (for trend visualization)
    /// - Parameter month: A date within the target month
    /// - Returns: Array of daily distance data for that month
    func dailyDistanceForMonth(_ month: Date) -> [DailyDistance] {
        let calendar = Calendar.current
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
              let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart),
              let daysInMonth = calendar.range(of: .day, in: .month, for: month) else {
            return []
        }
        
        var dailyData: [DailyDistance] = []
        
        for dayOffset in daysInMonth {
            guard let day = calendar.date(byAdding: .day, value: dayOffset - 1, to: monthStart) else { continue }
            let dayStart = calendar.startOfDay(for: day)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let dayRides = rides.filter { ride in
                ride.date >= dayStart && ride.date < dayEnd
            }
            
            let totalDistanceMiles = dayRides.reduce(0.0) { $0 + ($1.distance / 1609.34) }
            
            dailyData.append(DailyDistance(
                date: dayStart,
                dayNumber: dayOffset,
                distanceMiles: totalDistanceMiles
            ))
        }
        
        return dailyData
    }
    
    /// Compute the longest streak of consecutive days with at least one ride in entire history
    /// - Returns: Number of days in the best streak (0 if no rides)
    func bestStreakDays() -> Int {
        let calendar = Calendar.current
        
        // Group rides by day
        var ridesByDay: Set<Date> = []
        for ride in rides {
            let day = calendar.startOfDay(for: ride.date)
            ridesByDay.insert(day)
        }
        
        guard !ridesByDay.isEmpty else {
            return 0
        }
        
        // Sort days chronologically
        let sortedDays = ridesByDay.sorted()
        
        // Find longest consecutive sequence
        var bestStreak = 1
        var currentStreak = 1
        
        for i in 1..<sortedDays.count {
            // Check if this day is exactly one day after the previous day
            if let daysBetween = calendar.dateComponents([.day], from: sortedDays[i - 1], to: sortedDays[i]).day,
               daysBetween == 1 {
                // Consecutive day - continue streak
                currentStreak += 1
                bestStreak = max(bestStreak, currentStreak)
            } else {
                // Not consecutive - reset streak
                currentStreak = 1
            }
        }
        
        print("📊 RideDataManager: bestStreakDays = \(bestStreak)")
        return bestStreak
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

// MARK: - Phase 38: Ride Trend Point

struct RideTrendPoint: Identifiable {
    let id: UUID
    let date: Date // normalized to the day
    let totalDistanceMiles: Double
    let totalDurationSeconds: TimeInterval
    let averageSpeedMph: Double // distance / time for that day (or 0 if time == 0)
    
    init(id: UUID = UUID(), date: Date, totalDistanceMiles: Double, totalDurationSeconds: TimeInterval, averageSpeedMph: Double) {
        self.id = id
        self.date = date
        self.totalDistanceMiles = totalDistanceMiles
        self.totalDurationSeconds = totalDurationSeconds
        self.averageSpeedMph = averageSpeedMph
    }
}

// MARK: - Phase 49: Monthly Stats Data Structures

struct MonthRideSummary {
    let month: Date
    let rides: [RideRecord]
    let totalDistance: Double // meters
    let totalDuration: TimeInterval
    let totalRides: Int
    let averageDistance: Double // miles per ride
    let averageSpeed: Double // mph
    
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
    
    // Phase 50: Best streak within this month
    var bestStreakInMonth: Int {
        let calendar = Calendar.current
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
              let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
            return 0
        }
        
        // Get all days in this month that have rides
        var ridesByDay: Set<Date> = []
        for ride in rides {
            let day = calendar.startOfDay(for: ride.date)
            if day >= monthStart && day < monthEnd {
                ridesByDay.insert(day)
            }
        }
        
        guard !ridesByDay.isEmpty else {
            return 0
        }
        
        // Sort days chronologically
        let sortedDays = ridesByDay.sorted()
        
        // Find longest consecutive sequence within the month
        var bestStreak = 1
        var currentStreak = 1
        
        for i in 1..<sortedDays.count {
            if let daysBetween = calendar.dateComponents([.day], from: sortedDays[i - 1], to: sortedDays[i]).day,
               daysBetween == 1 {
                currentStreak += 1
                bestStreak = max(bestStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }
        
        return bestStreak
    }
    
    // Phase 50: Completed goals for this month
    var completedGoals: [RideGoal] {
        var goals: [RideGoal] = []
        
        // 200 miles in a month
        if totalDistanceInMiles >= 200.0 {
            goals.append(RideGoal(
                id: "monthly_distance_200",
                title: "200 Miles in a Month",
                description: "You rode at least 200 miles this month.",
                isCompleted: true
            ))
        }
        
        // 20 rides in a month
        if totalRides >= 20 {
            goals.append(RideGoal(
                id: "monthly_rides_20",
                title: "20 Rides in a Month",
                description: "You completed 20 or more rides this month.",
                isCompleted: true
            ))
        }
        
        // 5-day streak in a month
        if bestStreakInMonth >= 5 {
            goals.append(RideGoal(
                id: "streak_5_days",
                title: "5-Day Streak",
                description: "You kept riding for at least 5 days in a row this month.",
                isCompleted: true
            ))
        }
        
        return goals
    }
    
    var hasCompletedGoals: Bool {
        !completedGoals.isEmpty
    }
}

// MARK: - Phase 50: Ride Goal Model

struct RideGoal: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let isCompleted: Bool
}

struct DailyDistance: Identifiable {
    let id: UUID
    let date: Date
    let dayNumber: Int
    let distanceMiles: Double
    
    init(id: UUID = UUID(), date: Date, dayNumber: Int, distanceMiles: Double) {
        self.id = id
        self.date = date
        self.dayNumber = dayNumber
        self.distanceMiles = distanceMiles
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
