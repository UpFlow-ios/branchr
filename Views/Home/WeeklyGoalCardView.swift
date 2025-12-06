//
//  WeeklyGoalCardView.swift
//  branchr
//
//  Created for Phase 41 - Weekly Ride Goals & Streaks
//

import SwiftUI

/**
 * 🎯 Weekly Goal Card View
 *
 * Displays weekly distance goal progress and current streak information.
 * Shows progress bar, goal status, and streak days.
 */
struct WeeklyGoalCardView: View {
    let totalThisWeekMiles: Double
    let goalMiles: Double
    let currentStreakDays: Int
    let bestStreakDays: Int
    
    @ObservedObject private var theme = ThemeManager.shared
    
    // Computed progress (0.0 to 1.0)
    private var progress: Double {
        let safeGoal = max(goalMiles, 0.1) // Avoid division by zero
        return min(totalThisWeekMiles / safeGoal, 1.0)
    }
    
    // Progress percentage for display
    private var progressPercent: Int {
        Int(progress * 100)
    }
    
    var body: some View {
        // Text colors tuned for glass over artwork
        let titleColor = Color.white
        let primaryTextColor = Color.white.opacity(0.95)
        let secondaryTextColor = Color.white.opacity(0.82)
        
        VStack(alignment: .leading, spacing: 12) {
            // Top row: Title + percent pill
            HStack {
                Text("🎯 Weekly Goal")
                    .font(.subheadline.bold())
                    .foregroundColor(titleColor)
                
                Spacer()
                
                // Percent pill capsule
                Text("\(progressPercent)%")
                    .font(.caption.bold())
                    .foregroundColor(primaryTextColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.18))
                    )
            }
            
            // Gradient progress bar
            VStack(alignment: .leading, spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        let trackColor = Color.white.opacity(0.20)
                        Capsule()
                            .fill(trackColor)
                            .frame(height: 12)
                        
                        // Rainbow progress fill
                        Capsule()
                            .fill(theme.rideRainbowGradient)
                            .frame(width: geometry.size.width * CGFloat(progress), height: 12)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
                    }
                }
                .frame(height: 12)
            }
            
            // Bottom row: Three segments
            HStack(spacing: 8) {
                Text(String(format: "%.1f / %.0f mi", totalThisWeekMiles, goalMiles))
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
                
                Text(String(format: "This week: %.1f mi", totalThisWeekMiles))
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
                
                Text("🔥 Streak: \(currentStreakDays) • Best: \(bestStreakDays) days")
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            // Glass background so you can see the artwork behind it
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.16), lineWidth: 0.75)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 14, x: 0, y: 6)
    }
}
