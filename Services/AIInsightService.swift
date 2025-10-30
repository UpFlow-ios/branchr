//
//  AIInsightService.swift
//  branchr
//
//  Created by Joe Dormond on 10/23/25.
//

import Foundation
import SwiftUI

/// AI-powered service for generating ride insights and goal recommendations
/// Uses on-device calculations to analyze ride data and provide personalized feedback
@MainActor
class AIInsightService: ObservableObject {
    
    // MARK: - Data Structures
    
    struct RideInsight {
        let summary: String
        let comparison: String
        let nextGoal: String
        let improvementPercent: Double
        let streakMessage: String?
        let achievementBadge: String?
    }
    
    // MARK: - Configuration
    private let targetGrowthRate: Double = 0.08 // 8% improvement target
    private let minGrowthRate: Double = 0.05    // 5% minimum growth
    private let maxGrowthRate: Double = 0.15    // 15% maximum growth
    
    // MARK: - Initialization
    init() {
        print("Branchr AIInsightService initialized")
    }
    
    // MARK: - Public Methods
    
    /// Generate AI insights for a completed ride
    func generateInsights(for ride: RideRecord, history: [RideRecord]) -> RideInsight {
        let recentRides = Array(history.suffix(10)) // Last 10 rides for analysis
        
        // Generate summary
        let summary = generateSummary(for: ride)
        
        // Generate comparison
        let comparison = generateComparison(for: ride, history: recentRides)
        
        // Calculate improvement percentage
        let improvementPercent = calculateImprovementPercent(for: ride, history: recentRides)
        
        // Generate next goal
        let nextGoal = generateNextGoal(for: ride, improvementPercent: improvementPercent)
        
        // Generate streak message
        let streakMessage = generateStreakMessage(for: ride, history: recentRides)
        
        // Generate achievement badge
        let achievementBadge = generateAchievementBadge(for: ride, history: recentRides)
        
        return RideInsight(
            summary: summary,
            comparison: comparison,
            nextGoal: nextGoal,
            improvementPercent: improvementPercent,
            streakMessage: streakMessage,
            achievementBadge: achievementBadge
        )
    }
    
    // MARK: - Private Methods
    
    private func generateSummary(for ride: RideRecord) -> String {
        let distance = ride.formattedDistance
        let duration = ride.formattedDuration
        let avgSpeed = ride.formattedAverageSpeed
        
        // Determine pace quality
        let paceQuality = determinePaceQuality(ride: ride)
        
        return "You rode \(distance) in \(duration) — \(paceQuality)!"
    }
    
    private func generateComparison(for ride: RideRecord, history: [RideRecord]) -> String {
        guard let lastRide = history.last else {
            return "Great start! This is your first tracked ride."
        }
        
        let distanceDiff = ride.distance - lastRide.distance
        let speedDiff = ride.averageSpeed - lastRide.averageSpeed
        
        if distanceDiff > 0 {
            let improvement = String(format: "%.1f", distanceDiff / 1000) // Convert to km
            return "You went \(improvement) km farther than your last ride!"
        } else if speedDiff > 0 {
            let speedImprovement = String(format: "%.1f", speedDiff * 3.6) // Convert to km/h
            return "You were \(speedImprovement) km/h faster than last time!"
        } else {
            return "Consistent performance! Keep up the great work."
        }
    }
    
    private func calculateImprovementPercent(for ride: RideRecord, history: [RideRecord]) -> Double {
        guard let lastRide = history.last else { return 0.0 }
        
        let distanceImprovement = (ride.distance - lastRide.distance) / lastRide.distance
        let speedImprovement = (ride.averageSpeed - lastRide.averageSpeed) / lastRide.averageSpeed
        
        // Return the better of the two improvements
        return max(distanceImprovement, speedImprovement) * 100
    }
    
    private func generateNextGoal(for ride: RideRecord, improvementPercent: Double) -> String {
        let currentDistance = ride.distance / 1000 // Convert to km
        
        // Calculate target growth rate based on recent performance
        let growthRate = min(max(improvementPercent / 100, minGrowthRate), maxGrowthRate)
        let targetDistance = currentDistance * (1 + growthRate)
        
        let formattedTarget = String(format: "%.1f", targetDistance)
        let emoji = getMotivationalEmoji(for: improvementPercent)
        
        return "\(emoji) Goal: \(formattedTarget) km next ride"
    }
    
    private func generateStreakMessage(for ride: RideRecord, history: [RideRecord]) -> String? {
        let recentRides = history.filter { ride in
            Calendar.current.isDate(ride.date, inSameDayAs: Date()) ||
            Calendar.current.isDate(ride.date, inSameDayAs: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        }
        
        let streakCount = recentRides.count + 1 // +1 for current ride
        
        if streakCount >= 3 {
            return "🔥 \(streakCount) days in a row!"
        } else if streakCount == 2 {
            return "🔥 Building momentum!"
        }
        
        return nil
    }
    
    private func generateAchievementBadge(for ride: RideRecord, history: [RideRecord]) -> String? {
        // Distance achievements
        if ride.distance >= 10000 { // 10km+
            return "🏆 Distance Master"
        } else if ride.distance >= 5000 { // 5km+
            return "⭐ Distance Explorer"
        }
        
        // Speed achievements
        if ride.averageSpeed >= 8.0 { // ~29 km/h
            return "⚡ Speed Demon"
        } else if ride.averageSpeed >= 6.0 { // ~22 km/h
            return "🚀 Speed Runner"
        }
        
        // Consistency achievements
        if history.count >= 7 {
            return "📈 Consistency Champion"
        } else if history.count >= 3 {
            return "🎯 Getting Started"
        }
        
        return nil
    }
    
    private func determinePaceQuality(ride: RideRecord) -> String {
        let avgSpeedKmh = ride.averageSpeed * 3.6
        
        switch avgSpeedKmh {
        case 25...:
            return "incredible pace"
        case 20..<25:
            return "excellent pace"
        case 15..<20:
            return "great pace"
        case 10..<15:
            return "steady pace"
        default:
            return "relaxed pace"
        }
    }
    
    private func getMotivationalEmoji(for improvementPercent: Double) -> String {
        switch improvementPercent {
        case 20...:
            return "🚀"
        case 10..<20:
            return "💪"
        case 5..<10:
            return "🔥"
        case 0..<5:
            return "👍"
        default:
            return "🎯"
        }
    }
}

// MARK: - Extensions

extension AIInsightService {
    
    /// Get motivational message based on ride performance
    func getMotivationalMessage(for ride: RideRecord, history: [RideRecord]) -> String {
        let recentRides = Array(history.suffix(5))
        let avgDistance = recentRides.map { $0.distance }.reduce(0, +) / Double(max(recentRides.count, 1))
        
        if ride.distance > avgDistance * 1.2 {
            return "Outstanding effort! You're pushing your limits! 💪"
        } else if ride.distance > avgDistance {
            return "Great progress! You're getting stronger! 🔥"
        } else if ride.distance >= avgDistance * 0.8 {
            return "Solid performance! Consistency is key! ⭐"
        } else {
            return "Every ride counts! You're building the habit! 🎯"
        }
    }
    
    /// Get weekly progress summary
    func getWeeklyProgress(history: [RideRecord]) -> String {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        let weeklyRides = history.filter { $0.date >= weekAgo }
        let totalDistance = weeklyRides.map { $0.distance }.reduce(0, +)
        let avgDistance = totalDistance / Double(max(weeklyRides.count, 1))
        
        let formattedDistance = String(format: "%.1f", totalDistance / 1000)
        let formattedAvg = String(format: "%.1f", avgDistance / 1000)
        
        return "This week: \(formattedDistance) km total, \(formattedAvg) km average"
    }
}
