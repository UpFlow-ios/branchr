//
//  RideStatsView.swift
//  branchr
//
//  Created for Phase 49 - Monthly Ride Stats & Trends Screen
//

import SwiftUI

/**
 * 📊 Ride Stats View
 *
 * Shows monthly ride statistics, trends, and streaks for the selected month.
 * Accessible from RideCalendarView via the graph icon.
 */
struct RideStatsView: View {
    let month: Date // The month to display stats for
    var onClose: (() -> Void)? = nil
    var onSelectDay: ((Date) -> Void)? = nil
    
    @StateObject private var rideDataManager = RideDataManager.shared
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @State private var monthSummary: MonthRideSummary?
    @State private var dailyData: [DailyDistance] = []
    @State private var currentStreak: Int = 0
    @State private var bestStreak: Int = 0
    @State private var showConfetti = false
    
    private var calendar: Calendar { Calendar.current }
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: month)
    }
    
    private var maxDistance: Double {
        dailyData.map { $0.distanceMiles }.max() ?? 1.0
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Stats for \(monthName)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(theme.primaryText)
                    }
                    .padding(.top, 20)
                    
                    if let summary = monthSummary {
                        // Metrics Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            MonthlyStatCard(
                                title: "Total Distance",
                                value: String(format: "%.2f mi", summary.totalDistanceInMiles),
                                icon: "figure.run"
                            )
                            
                            MonthlyStatCard(
                                title: "Total Time",
                                value: summary.formattedDuration,
                                icon: "clock.fill"
                            )
                            
                            MonthlyStatCard(
                                title: "Total Rides",
                                value: "\(summary.totalRides)",
                                icon: "bicycle"
                            )
                            
                            MonthlyStatCard(
                                title: "Avg Distance",
                                value: String(format: "%.2f mi", summary.averageDistance),
                                icon: "ruler.fill"
                            )
                            
                            MonthlyStatCard(
                                title: "Avg Speed",
                                value: String(format: "%.1f mph", summary.averageSpeed),
                                icon: "speedometer"
                            )
                            
                            MonthlyStatCard(
                                title: "Current Streak",
                                value: "\(currentStreak) days",
                                icon: "flame.fill"
                            )
                        }
                        .padding(.horizontal, 16)
                        
                        // Best Streak Card
                        HStack(spacing: 12) {
                            Image(systemName: "trophy.fill")
                                .font(.title2)
                                .foregroundColor(theme.brandYellow)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Best Streak")
                                    .font(.subheadline)
                                    .foregroundColor(Color.white.opacity(0.7))
                                Text("\(bestStreak) days")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(theme.surfaceBackground)
                                .shadow(
                                    color: theme.isDarkMode ? .clear : Color.black.opacity(0.25),
                                    radius: theme.isDarkMode ? 0 : 18,
                                    x: 0,
                                    y: theme.isDarkMode ? 0 : 8
                                )
                        )
                        .padding(.horizontal, 16)
                        
                        // Phase 50: Achievements Section
                        if summary.hasCompletedGoals {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Achievements")
                                    .font(.headline.bold())
                                    .foregroundColor(theme.primaryText)
                                    .padding(.horizontal, 16)
                                
                                ForEach(summary.completedGoals) { goal in
                                    HStack(spacing: 12) {
                                        Image(systemName: "trophy.fill")
                                            .font(.title3)
                                            .foregroundColor(theme.brandYellow)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(goal.title)
                                                .font(.subheadline.bold())
                                                .foregroundColor(.white)
                                            Text(goal.description)
                                                .font(.caption)
                                                .foregroundColor(Color.white.opacity(0.7))
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundColor(theme.brandYellow)
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(theme.surfaceBackground)
                                            .shadow(
                                                color: theme.isDarkMode ? .clear : Color.black.opacity(0.25),
                                                radius: theme.isDarkMode ? 0 : 18,
                                                x: 0,
                                                y: theme.isDarkMode ? 0 : 8
                                            )
                                    )
                                    .padding(.horizontal, 16)
                                }
                            }
                            .padding(.top, 8)
                        }
                        
                        // Daily Trend Visualization
                        if !dailyData.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Daily Distance")
                                    .font(.headline.bold())
                                    .foregroundColor(theme.primaryText)
                                    .padding(.horizontal, 16)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(dailyData) { day in
                                            DailyDistanceBar(
                                                day: day.dayNumber,
                                                distance: day.distanceMiles,
                                                maxDistance: maxDistance,
                                                isBestDay: day.distanceMiles == maxDistance && maxDistance > 0,
                                                onTap: {
                                                    onSelectDay?(day.date)
                                                    onClose?()
                                                    dismiss()
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    } else {
                        // Empty state
                        VStack(spacing: 16) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 48))
                                .foregroundColor(theme.brandYellow)
                            
                            Text("No rides this month")
                                .font(.headline)
                                .foregroundColor(theme.secondaryText)
                            
                            Text("Start tracking rides to see your stats!")
                                .font(.subheadline)
                                .foregroundColor(theme.secondaryText.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    }
                }
                .padding(.bottom, 24)
                }
                .background(theme.primaryBackground.ignoresSafeArea())
                
                // Phase 50: Confetti overlay
                if showConfetti {
                    AchievementConfettiView()
                        .transition(.opacity)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation {
                                    showConfetti = false
                                }
                            }
                        }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        HapticsService.shared.mediumTap()
                        dismiss()
                    }
                    .foregroundColor(theme.brandYellow)
                    .font(.headline)
                }
            }
            .onAppear {
                loadStats()
            }
            .onReceive(NotificationCenter.default.publisher(for: .branchrRidesDidChange)) { _ in
                loadStats()
            }
        }
    }
    
    private func loadStats() {
        print("📊 RideStatsView: Loading stats for \(monthName)")
        let summary = rideDataManager.monthSummary(for: month)
        monthSummary = summary
        dailyData = rideDataManager.dailyDistanceForMonth(month)
        currentStreak = rideDataManager.currentStreakDays()
        bestStreak = rideDataManager.bestStreakDays()
        print("📊 RideStatsView: Loaded \(summary.totalRides) rides, \(dailyData.count) days")
        
        // Phase 50: Trigger confetti if goals are completed
        if summary.hasCompletedGoals {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation {
                    showConfetti = true
                }
            }
        }
    }
}

// MARK: - Monthly Stat Card

struct MonthlyStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(theme.brandYellow)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(theme.surfaceBackground)
                .shadow(
                    color: theme.isDarkMode ? .clear : Color.black.opacity(0.25),
                    radius: theme.isDarkMode ? 0 : 18,
                    x: 0,
                    y: theme.isDarkMode ? 0 : 8
                )
        )
    }
}

// MARK: - Daily Distance Bar

struct DailyDistanceBar: View {
    let day: Int
    let distance: Double
    let maxDistance: Double
    let isBestDay: Bool
    let onTap: () -> Void
    
    @ObservedObject private var theme = ThemeManager.shared
    
    private var barHeight: CGFloat {
        guard maxDistance > 0 else { return 0 }
        let ratio = distance / maxDistance
        return max(4, min(120, ratio * 120)) // Min 4pt, max 120pt
    }
    
    // Phase 67: Use rainbow gradient for all bars
    private var barGradient: LinearGradient {
        theme.rideRainbowGradientVertical
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                // Bar
                ZStack(alignment: .bottom) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(theme.neutralAccent.opacity(0.3))
                        .frame(width: 24, height: 120)
                    
                    // Phase 67: Filled bar with rainbow gradient
                    if distance > 0 {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(barGradient)
                            .frame(width: 24, height: barHeight)
                            .shadow(
                                color: isBestDay ? theme.brandYellow.opacity(0.5) : .clear,
                                radius: isBestDay ? 4 : 0
                            )
                    }
                }
                
                // Day number
                Text("\(day)")
                    .font(.caption2.bold())
                    .foregroundColor(isBestDay ? theme.brandYellow : theme.primaryText)
            }
            .frame(width: 32)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Phase 50: Achievement Confetti View

struct AchievementConfettiView: View {
    @State private var animate = false
    
    private let emojis = ["🎉", "🚴‍♂️", "⭐️", "🏆", "🔥", "💪", "✨", "🎊"]
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<16, id: \.self) { index in
                    let x = CGFloat.random(in: 0...proxy.size.width)
                    let delay = Double(index) * 0.03
                    let emoji = emojis.randomElement() ?? "🎉"
                    
                    Text(emoji)
                        .font(.title)
                        .position(
                            x: x,
                            y: animate ? proxy.size.height + 40 : -40
                        )
                        .opacity(animate ? 0 : 1)
                        .animation(
                            .easeOut(duration: 1.4)
                                .delay(delay),
                            value: animate
                        )
                }
            }
            .onAppear {
                animate = true
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Preview

#Preview {
    RideStatsView(month: Date())
        .preferredColorScheme(.dark)
}

