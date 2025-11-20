//
//  RideMetricsCalculator.swift
//  branchr
//
//  Created for Phase 36 - Real Ride Metrics & Route Visualization
//

import Foundation
import CoreLocation

/**
 * 📊 Ride Metrics Calculator
 *
 * Pure helper for computing ride metrics from location samples.
 * No side effects, no UI dependencies - easy to test and reuse.
 */
struct RideMetricsCalculator {
    
    /**
     * Calculate ride metrics from location samples
     *
     * - Parameters:
     *   - locations: Ordered array of CLLocation samples representing the ride route
     *   - startTime: Optional start time (used if locations are empty or for duration fallback)
     *   - endTime: Optional end time (used for duration calculation)
     *   - duration: Optional pre-calculated duration (takes precedence over time difference)
     *
     * - Returns: Calculated metrics
     */
    static func calculateMetrics(
        from locations: [CLLocation],
        startTime: Date? = nil,
        endTime: Date? = nil,
        duration: TimeInterval? = nil
    ) -> RideMetrics {
        
        // Filter valid locations (reasonable accuracy, monotonically increasing timestamps)
        let validLocations = filterValidLocations(locations)
        
        guard !validLocations.isEmpty else {
            // No valid locations - return zero metrics
            let calculatedDuration = duration ?? calculateDuration(startTime: startTime, endTime: endTime)
            if locations.count < 2 {
                print("⚠️ RideMetrics: not enough samples (\(locations.count)), treating as zero-distance ride")
            }
            return RideMetrics(
                totalDistanceMeters: 0.0,
                totalDurationSeconds: calculatedDuration,
                averageSpeedMetersPerSecond: 0.0
            )
        }
        
        // Calculate total distance from consecutive locations
        let totalDistanceMeters = calculateTotalDistance(from: validLocations)
        
        // Calculate duration
        let totalDurationSeconds: TimeInterval
        if let duration = duration {
            totalDurationSeconds = duration
        } else if let start = validLocations.first?.timestamp,
                  let end = validLocations.last?.timestamp {
            totalDurationSeconds = end.timeIntervalSince(start)
        } else {
            totalDurationSeconds = calculateDuration(startTime: startTime, endTime: endTime)
        }
        
        // Calculate average speed
        let averageSpeedMetersPerSecond: Double
        if totalDurationSeconds > 0 && totalDistanceMeters > 0 {
            averageSpeedMetersPerSecond = totalDistanceMeters / totalDurationSeconds
        } else {
            averageSpeedMetersPerSecond = 0.0
        }
        
        return RideMetrics(
            totalDistanceMeters: totalDistanceMeters,
            totalDurationSeconds: totalDurationSeconds,
            averageSpeedMetersPerSecond: averageSpeedMetersPerSecond
        )
    }
    
    // MARK: - Private Helpers
    
    /// Filter locations to only include valid samples
    private static func filterValidLocations(_ locations: [CLLocation]) -> [CLLocation] {
        var validLocations: [CLLocation] = []
        var lastTimestamp: Date?
        
        for location in locations {
            // Skip invalid horizontal accuracy
            guard location.horizontalAccuracy > 0 && location.horizontalAccuracy < 100 else {
                continue
            }
            
            // Ensure timestamps are monotonically increasing
            if let last = lastTimestamp, location.timestamp <= last {
                continue
            }
            
            validLocations.append(location)
            lastTimestamp = location.timestamp
        }
        
        return validLocations
    }
    
    /// Calculate total distance from consecutive location samples
    private static func calculateTotalDistance(from locations: [CLLocation]) -> Double {
        guard locations.count > 1 else { return 0.0 }
        
        var totalDistance: Double = 0.0
        
        for i in 1..<locations.count {
            let previous = locations[i - 1]
            let current = locations[i]
            
            let distance = current.distance(from: previous)
            let timeDelta = current.timestamp.timeIntervalSince(previous.timestamp)
            
            // Filter out unreasonable jumps (likely GPS errors)
            // Check if speed would be > 60 mph (26.8 m/s) - filter GPS glitches
            if distance > 0 && timeDelta > 0 {
                let speedMps = distance / timeDelta
                let speedMph = speedMps * 2.23694
                
                // Only include segments with reasonable speeds (< 60 mph) and distance < 1km
                if speedMph > 0 && speedMph < 60 && distance < 1000 {
                    totalDistance += distance
                }
            } else if distance > 0 && distance < 1000 {
                // If no timestamp delta, just check distance threshold
                totalDistance += distance
            }
        }
        
        return totalDistance
    }
    
    /// Calculate duration from start/end times
    private static func calculateDuration(startTime: Date?, endTime: Date?) -> TimeInterval {
        guard let start = startTime, let end = endTime else {
            return 0.0
        }
        return end.timeIntervalSince(start)
    }
}

// MARK: - Ride Metrics Result

struct RideMetrics {
    let totalDistanceMeters: Double
    let totalDurationSeconds: TimeInterval
    let averageSpeedMetersPerSecond: Double
    
    // Convenience conversions for UI
    var totalDistanceMiles: Double {
        totalDistanceMeters / 1609.34
    }
    
    var averageSpeedMph: Double {
        averageSpeedMetersPerSecond * 2.237 // m/s to mph
    }
    
    var formattedDistanceMiles: String {
        String(format: "%.2f", totalDistanceMiles)
    }
    
    var formattedAverageSpeedMph: String {
        String(format: "%.1f", averageSpeedMph)
    }
}

