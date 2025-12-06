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
        // Text colors tuned for glassy background
        let titleColor = Color.white
        let primaryTextColor = Color.white.opacity(0.94)
        let secondaryTextColor = Color.white.opacity(0.80)
        
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
                        Color.white.opacity(0.18),
                        in: Capsule()
                    )
            }
            
            // Gradient progress bar
            VStack(alignment: .leading, spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track - slightly lighter for clarity
                        let trackColor = Color.white.opacity(0.15)
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
                // Left: Distance vs goal
                Text(String(format: "%.1f / %.0f mi", totalThisWeekMiles, goalMiles))
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
                
                // Center: This week summary
                Text(String(format: "This week: %.1f mi", totalThisWeekMiles))
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
                
                // Right: Streak info
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
            // Glassy, more transparent background so artwork shows through
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            // Soft border to match system Now Playing style
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(0.35),
            radius: 20,
            x: 0,
            y: 10
        )
    }
}
