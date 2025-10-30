//
//  AchievementTracker.swift
//  branchr
//
//  Created by Joe Dormond on 10/23/25.
//

import Foundation
import SwiftUI

/// Service for tracking user achievements and streaks
/// Maintains ride streaks, achievements, and motivational progress
@MainActor
class AchievementTracker: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentStreakDays: Int = 0
    @Published var longestStreakDays: Int = 0
    @Published var totalRides: Int = 0
    @Published var totalDistance: Double = 0.0 // meters
    @Published var achievements: [Achievement] = []
    
    // MARK: - Data Structures
    struct Achievement: Identifiable, Codable {
        let id: UUID
        let title: String
        let description: String
        let emoji: String
        let dateEarned: Date
        let category: AchievementCategory
        
        init(title: String, description: String, emoji: String, category: AchievementCategory) {
            self.id = UUID()
            self.title = title
            self.description = description
            self.emoji = emoji
            self.dateEarned = Date()
            self.category = category
        }
    }
    
    enum AchievementCategory: String, Codable, CaseIterable {
        case distance = "distance"
        case speed = "speed"
        case consistency = "consistency"
        case milestone = "milestone"
        case special = "special"
    }
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let streakKey = "branchr_current_streak"
    private let longestStreakKey = "branchr_longest_streak"
    private let totalRidesKey = "branchr_total_rides"
    private let totalDistanceKey = "branchr_total_distance"
    private let achievementsKey = "branchr_achievements"
    private let lastRideDateKey = "branchr_last_ride_date"
    
    // MARK: - Initialization
    init() {
        loadData()
        print("Branchr AchievementTracker initialized - Streak: \(currentStreakDays) days")
    }
    
    // MARK: - Public Methods
    
    /// Update achievements after a completed ride
    func updateAfterRide(_ ride: RideRecord) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastRideDate = userDefaults.object(forKey: lastRideDateKey) as? Date
        
        // Update streak
        updateStreak(lastRideDate: lastRideDate, today: today)
        
        // Update totals
        totalRides += 1
        totalDistance += ride.distance
        
        // Check for new achievements
        checkForNewAchievements(ride: ride)
        
        // Save data
        saveData()
        
        print("Branchr: Achievement updated - Streak: \(currentStreakDays), Total rides: \(totalRides)")
    }
    
    /// Reset streak (for testing or user preference)
    func resetStreak() {
        currentStreakDays = 0
        saveData()
        print("Branchr: Streak reset")
    }
    
    /// Get formatted streak message
    func getStreakMessage() -> String? {
        guard currentStreakDays > 0 else { return nil }
        
        switch currentStreakDays {
        case 1:
            return "🔥 Day 1 - Great start!"
        case 2:
            return "🔥 Day 2 - Building momentum!"
        case 3...6:
            return "🔥 \(currentStreakDays) days strong!"
        case 7...13:
            return "🔥 \(currentStreakDays) days - You're on fire!"
        case 14...29:
            return "🔥 \(currentStreakDays) days - Incredible dedication!"
        default:
            return "🔥 \(currentStreakDays) days - Legendary streak!"
        }
    }
    
    /// Get progress towards next milestone
    func getNextMilestone() -> String? {
        let milestones = [5, 10, 25, 50, 100, 250, 500]
        
        for milestone in milestones {
            if totalRides < milestone {
                let remaining = milestone - totalRides
                return "\(remaining) rides until \(milestone) milestone!"
            }
        }
        
        return nil
    }
    
    // MARK: - Private Methods
    
    private func updateStreak(lastRideDate: Date?, today: Date) {
        let calendar = Calendar.current
        
        guard let lastRideDate = lastRideDate else {
            // First ride
            currentStreakDays = 1
            userDefaults.set(today, forKey: lastRideDateKey)
            return
        }
        
        let lastRideDay = calendar.startOfDay(for: lastRideDate)
        let daysDifference = calendar.dateComponents([.day], from: lastRideDay, to: today).day ?? 0
        
        switch daysDifference {
        case 0:
            // Same day - no change to streak
            break
        case 1:
            // Next day - continue streak
            currentStreakDays += 1
            userDefaults.set(today, forKey: lastRideDateKey)
        default:
            // More than 1 day gap - reset streak
            currentStreakDays = 1
            userDefaults.set(today, forKey: lastRideDateKey)
        }
        
        // Update longest streak
        if currentStreakDays > longestStreakDays {
            longestStreakDays = currentStreakDays
        }
    }
    
    private func checkForNewAchievements(ride: RideRecord) {
        var newAchievements: [Achievement] = []
        
        // Distance achievements
        if ride.distance >= 10000 && !hasAchievement(title: "10K Master") {
            newAchievements.append(Achievement(
                title: "10K Master",
                description: "Completed a 10km+ ride",
                emoji: "🏆",
                category: .distance
            ))
        }
        
        if ride.distance >= 5000 && !hasAchievement(title: "5K Explorer") {
            newAchievements.append(Achievement(
                title: "5K Explorer",
                description: "Completed a 5km+ ride",
                emoji: "⭐",
                category: .distance
            ))
        }
        
        // Speed achievements
        if ride.averageSpeed >= 8.0 && !hasAchievement(title: "Speed Demon") {
            newAchievements.append(Achievement(
                title: "Speed Demon",
                description: "Averaged 29+ km/h",
                emoji: "⚡",
                category: .speed
            ))
        }
        
        if ride.averageSpeed >= 6.0 && !hasAchievement(title: "Speed Runner") {
            newAchievements.append(Achievement(
                title: "Speed Runner",
                description: "Averaged 22+ km/h",
                emoji: "🚀",
                category: .speed
            ))
        }
        
        // Consistency achievements
        if currentStreakDays == 7 && !hasAchievement(title: "Week Warrior") {
            newAchievements.append(Achievement(
                title: "Week Warrior",
                description: "7-day ride streak",
                emoji: "🔥",
                category: .consistency
            ))
        }
        
        if currentStreakDays == 30 && !hasAchievement(title: "Month Master") {
            newAchievements.append(Achievement(
                title: "Month Master",
                description: "30-day ride streak",
                emoji: "👑",
                category: .consistency
            ))
        }
        
        // Milestone achievements
        if totalRides == 10 && !hasAchievement(title: "Getting Started") {
            newAchievements.append(Achievement(
                title: "Getting Started",
                description: "Completed 10 rides",
                emoji: "🎯",
                category: .milestone
            ))
        }
        
        if totalRides == 50 && !hasAchievement(title: "Half Century") {
            newAchievements.append(Achievement(
                title: "Half Century",
                description: "Completed 50 rides",
                emoji: "🏅",
                category: .milestone
            ))
        }
        
        if totalRides == 100 && !hasAchievement(title: "Century Club") {
            newAchievements.append(Achievement(
                title: "Century Club",
                description: "Completed 100 rides",
                emoji: "💎",
                category: .milestone
            ))
        }
        
        // Add new achievements
        achievements.append(contentsOf: newAchievements)
        
        // Log new achievements
        for achievement in newAchievements {
            print("Branchr: New achievement earned - \(achievement.title) \(achievement.emoji)")
        }
    }
    
    private func hasAchievement(title: String) -> Bool {
        return achievements.contains { $0.title == title }
    }
    
    private func loadData() {
        currentStreakDays = userDefaults.integer(forKey: streakKey)
        longestStreakDays = userDefaults.integer(forKey: longestStreakKey)
        totalRides = userDefaults.integer(forKey: totalRidesKey)
        totalDistance = userDefaults.double(forKey: totalDistanceKey)
        
        // Load achievements
        if let data = userDefaults.data(forKey: achievementsKey),
           let decodedAchievements = try? JSONDecoder().decode([Achievement].self, from: data) {
            achievements = decodedAchievements
        }
    }
    
    private func saveData() {
        userDefaults.set(currentStreakDays, forKey: streakKey)
        userDefaults.set(longestStreakDays, forKey: longestStreakKey)
        userDefaults.set(totalRides, forKey: totalRidesKey)
        userDefaults.set(totalDistance, forKey: totalDistanceKey)
        
        // Save achievements
        if let data = try? JSONEncoder().encode(achievements) {
            userDefaults.set(data, forKey: achievementsKey)
        }
    }
}

// MARK: - Extensions

extension AchievementTracker {
    
    /// Get achievement statistics
    var achievementStats: (total: Int, byCategory: [AchievementCategory: Int]) {
        let byCategory = Dictionary(grouping: achievements, by: { $0.category })
            .mapValues { $0.count }
        
        return (total: achievements.count, byCategory: byCategory)
    }
    
    /// Get recent achievements (last 5)
    var recentAchievements: [Achievement] {
        return Array(achievements.suffix(5))
    }
    
    /// Get formatted total distance
    var formattedTotalDistance: String {
        let distanceKm = totalDistance / 1000
        return String(format: "%.1f km", distanceKm)
    }
    
    /// Get formatted average distance per ride
    var formattedAverageDistance: String {
        guard totalRides > 0 else { return "0.0 km" }
        let avgDistanceKm = (totalDistance / Double(totalRides)) / 1000
        return String(format: "%.1f km", avgDistanceKm)
    }
}
