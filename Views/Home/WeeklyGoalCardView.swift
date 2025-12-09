//
//  WeeklyGoalCardView.swift
//  branchr
//
//  Created for Phase 41 - Weekly Ride Goals & Streaks
//

import SwiftUI

struct WeeklyGoalCardView: View {
    let totalThisWeekMiles: Double
    let goalMiles: Double
    let currentStreakDays: Int
    let bestStreakDays: Int
    
    @ObservedObject private var theme = ThemeManager.shared
    
    private var progress: Double {
        let safeGoal = max(goalMiles, 0.1)
        return min(totalThisWeekMiles / safeGoal, 1.0)
    }
    
    private var progressPercent: Int {
        Int(progress * 100)
    }
    
    var body: some View {
        let titleColor = Color.white
        let secondaryTextColor = Color.white.opacity(0.8)
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🎯 Weekly Goal")
                    .font(.subheadline.bold())
                    .foregroundColor(titleColor)
                
                Spacer()
                
                Text("\(progressPercent)%")
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Color.white.opacity(0.20),
                        in: Capsule()
                    )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.18))
                            .frame(height: 12)
                        
                        Capsule()
                            .fill(theme.rideRainbowGradient)
                            .frame(width: geometry.size.width * CGFloat(progress), height: 12)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
                    }
                }
                .frame(height: 12)
            }
            
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
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }
}
