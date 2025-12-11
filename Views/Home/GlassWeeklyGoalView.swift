//
//  GlassWeeklyGoalView.swift
//  branchr
//
//  Created for Phase 76 - Compact Weekly Goal Glass Card
//

import SwiftUI

/**
 * 🎯 Glass Weekly Goal View
 *
 * Compact glass card showing weekly progress and streak.
 * Clean, fixed-height design that doesn't expand.
 */
struct GlassWeeklyGoalView: View {
    let weeklyMiles: Double
    let goalMiles: Double
    let streak: Int
    let bestStreak: Int
    
    @ObservedObject private var theme = ThemeManager.shared
    
    private var progress: Double {
        let safeGoal = max(goalMiles, 0.1)
        return min(weeklyMiles / safeGoal, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Title row
            HStack {
                Text("🎯 Weekly Goal")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.16), in: Capsule())
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(theme.rideRainbowGradient)
                        .frame(width: geometry.size.width * CGFloat(progress), height: 8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 8)
            
            // Info row
            HStack(spacing: 0) {
                Text(String(format: "%.1f / %.0f mi", weeklyMiles, goalMiles))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text("This week: " + String(format: "%.1f mi", weeklyMiles))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text("🔥 Streak: \(streak)  ·  Best: \(bestStreak)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
        .liquidGlass(cornerRadius: 24) // iOS 26 Interactive Liquid Glass
    }
}

