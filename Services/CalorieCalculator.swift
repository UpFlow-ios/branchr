//
//  CalorieCalculator.swift
//  branchr
//
//  Created by Joe Dormond on 10/23/25.
//

import Foundation

/// Service for calculating calories burned during rides
/// Uses MET (Metabolic Equivalent of Task) values and user weight
@MainActor
class CalorieCalculator: ObservableObject {
    
    // MARK: - Configuration
    @Published var userWeight: Double = 70.0 // kg (default 70kg = ~154 lbs)
    
    // MARK: - MET Values for Cycling
    private let cyclingMETs: [String: Double] = [
        "leisurely": 6.0,      // < 10 mph (16 km/h)
        "moderate": 8.0,       // 10-12 mph (16-19 km/h)
        "vigorous": 10.0,       // 12-16 mph (19-26 km/h)
        "racing": 12.0         // > 16 mph (26 km/h)
    ]
    
    // MARK: - Initialization
    init() {
        loadUserWeight()
        print("Branchr CalorieCalculator initialized - User weight: \(userWeight)kg")
    }
    
    // MARK: - Public Methods
    
    /// Calculate calories burned for a ride
    func calculateCalories(distance: Double, duration: TimeInterval, avgSpeed: Double) -> Double {
        let durationHours = duration / 3600.0 // Convert seconds to hours
        let met = getMETForSpeed(avgSpeed)
        
        // Formula: Calories = MET × Weight(kg) × Duration(hrs)
        let calories = met * userWeight * durationHours
        
        print("Branchr: Calories calculated - Distance: \(String(format: "%.1f", distance/1000))km, Duration: \(String(format: "%.1f", durationHours))hrs, Speed: \(String(format: "%.1f", avgSpeed*3.6))km/h, MET: \(met), Calories: \(String(format: "%.0f", calories))")
        
        return max(calories, 0) // Ensure non-negative
    }
    
    /// Calculate calories for a RideRecord
    func calculateCalories(for ride: RideRecord) -> Double {
        return calculateCalories(
            distance: ride.distance,
            duration: ride.duration,
            avgSpeed: ride.averageSpeed
        )
    }
    
    /// Update user weight
    func updateUserWeight(_ weight: Double) {
        userWeight = max(weight, 30.0) // Minimum 30kg
        saveUserWeight()
        print("Branchr: User weight updated to \(userWeight)kg")
    }
    
    /// Get formatted weight string
    var formattedWeight: String {
        return String(format: "%.1f kg", userWeight)
    }
    
    /// Get weight in pounds
    var weightInPounds: Double {
        return userWeight * 2.20462
    }
    
    /// Get formatted weight in pounds
    var formattedWeightInPounds: String {
        return String(format: "%.1f lbs", weightInPounds)
    }
    
    // MARK: - Private Methods
    
    private func getMETForSpeed(_ speed: Double) -> Double {
        let speedKmh = speed * 3.6 // Convert m/s to km/h
        
        switch speedKmh {
        case 0..<16:
            return cyclingMETs["leisurely"] ?? 6.0
        case 16..<19:
            return cyclingMETs["moderate"] ?? 8.0
        case 19..<26:
            return cyclingMETs["vigorous"] ?? 10.0
        default:
            return cyclingMETs["racing"] ?? 12.0
        }
    }
    
    private func loadUserWeight() {
        let savedWeight = UserDefaults.standard.double(forKey: "branchr_user_weight")
        if savedWeight > 0 {
            userWeight = savedWeight
        }
    }
    
    private func saveUserWeight() {
        UserDefaults.standard.set(userWeight, forKey: "branchr_user_weight")
    }
}

// MARK: - Extensions

extension CalorieCalculator {
    
    /// Get activity level description based on MET
    func getActivityLevelDescription(for speed: Double) -> String {
        let met = getMETForSpeed(speed)
        
        switch met {
        case 0..<7:
            return "Leisurely"
        case 7..<9:
            return "Moderate"
        case 9..<11:
            return "Vigorous"
        default:
            return "Racing"
        }
    }
    
    /// Get calorie burn rate per hour
    func getCalorieBurnRate(for speed: Double) -> Double {
        let met = getMETForSpeed(speed)
        return met * userWeight
    }
    
    /// Get formatted calorie burn rate
    func getFormattedCalorieBurnRate(for speed: Double) -> String {
        let rate = getCalorieBurnRate(for: speed)
        return String(format: "%.0f cal/hr", rate)
    }
    
    /// Calculate calories for a specific duration at a given speed
    func calculateCaloriesForDuration(duration: TimeInterval, avgSpeed: Double) -> Double {
        let durationHours = duration / 3600.0
        let met = getMETForSpeed(avgSpeed)
        return met * userWeight * durationHours
    }
    
    /// Get weekly calorie goal suggestion
    func getWeeklyCalorieGoal() -> Double {
        // Suggest burning 2000-3000 calories per week for fitness
        return 2500.0
    }
    
    /// Get monthly calorie goal suggestion
    func getMonthlyCalorieGoal() -> Double {
        return getWeeklyCalorieGoal() * 4.3 // ~4.3 weeks per month
    }
}

// MARK: - Sample Data for Testing

extension CalorieCalculator {
    
    /// Generate sample calorie data for testing
    static func generateSampleCalorieData() -> [(String, Double)] {
        return [
            ("5km ride, 20 min", 120.0),
            ("10km ride, 35 min", 280.0),
            ("15km ride, 50 min", 450.0),
            ("20km ride, 70 min", 650.0),
            ("30km ride, 100 min", 950.0)
        ]
    }
}
