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
        // Phase 76: Shortened, compact design
        let titleColor = Color.white
        let secondaryTextColor = Color.white.opacity(0.80)
        
        VStack(alignment: .leading, spacing: 8) {
            // Top row: Title + percent pill
            HStack {
                Text("🎯 Weekly Goal")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(titleColor)
                
                Spacer()
                
                // Percent pill capsule
                Text("\(progressPercent)%")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.16))
                    )
            }
            
            // Rainbow gradient progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 6)
                    
                    // Rainbow progress fill
                    Capsule()
                        .fill(theme.rideRainbowGradient)
                        .frame(width: geometry.size.width * CGFloat(progress), height: 6)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 6)
            
            // Single compact info row
            HStack(spacing: 0) {
                Text(String(format: "%.1f / %.0f mi", totalThisWeekMiles, goalMiles))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(secondaryTextColor)
                
                Spacer()
                
                Text("This week: " + String(format: "%.1f mi", totalThisWeekMiles))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
                
                Text("🔥 \(currentStreakDays)  ·  Best: \(bestStreakDays)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(secondaryTextColor)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        // ✨ Enhanced glass background with depth
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.08),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 1.2)
        )
        // Enhanced neon-style glow (multi-layer)
        .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 8)
        .shadow(color: .white.opacity(0.12), radius: 6, x: 0, y: 0)
        .shadow(color: .purple.opacity(0.15), radius: 10, x: 0, y: 0)
    }
}
