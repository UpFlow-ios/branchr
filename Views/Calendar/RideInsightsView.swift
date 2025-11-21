//
//  RideInsightsView.swift
//  branchr
//
//  Created for Phase 38 - Ride Insights Charts & Weekly Stats
//

import SwiftUI

/**
 * 📊 Ride Insights View
 *
 * Shows ride trends, weekly stats, and charts for recent rides.
 * Accessible from EnhancedRideSummaryView and RideCalendarView.
 */
struct RideInsightsView: View {
    @StateObject private var rideDataManager = RideDataManager.shared
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var trendPoints: [RideTrendPoint] = []
    @State private var weeklySummary: (thisWeekMiles: Double, lastWeekMiles: Double) = (0, 0)
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Ride Insights")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(theme.primaryText)
                        
                        Text("Your recent ride trends at a glance")
                            .font(.subheadline)
                            .foregroundColor(theme.secondaryText)
                    }
                    .padding(.top, 20)
                    
                    // Weekly Summary Card
                    if trendPoints.isEmpty {
                        EmptyInsightsView()
                    } else {
                        WeeklySummaryCard(
                            thisWeekMiles: weeklySummary.thisWeekMiles,
                            lastWeekMiles: weeklySummary.lastWeekMiles
                        )
                        .padding(.horizontal, 16)
                        
                        // Trend Chart Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Daily Distance Trend")
                                .font(.headline)
                                .foregroundColor(theme.primaryText)
                                .padding(.horizontal, 16)
                            
                            DistanceTrendChart(trendPoints: trendPoints)
                                .padding(.horizontal, 16)
                        }
                        
                        // Recent Days List
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Days")
                                .font(.headline)
                                .foregroundColor(theme.primaryText)
                                .padding(.horizontal, 16)
                            
                            ForEach(trendPoints.reversed()) { point in
                                TrendDayRow(point: point)
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.primaryBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.accentColor)
                }
            }
            .onAppear {
                trendPoints = rideDataManager.recentDailyTrend(lastNDays: 7)
                weeklySummary = rideDataManager.weeklySummary()
                print("📊 RideInsightsView: opened with \(trendPoints.count) days of data")
            }
        }
    }
}

// MARK: - Weekly Summary Card

struct WeeklySummaryCard: View {
    let thisWeekMiles: Double
    let lastWeekMiles: Double
    @ObservedObject private var theme = ThemeManager.shared
    
    private var comparisonText: String {
        if thisWeekMiles > lastWeekMiles {
            let diff = thisWeekMiles - lastWeekMiles
            return "▲ Up \(String(format: "%.1f", diff)) mi vs last week"
        } else if thisWeekMiles < lastWeekMiles {
            let diff = lastWeekMiles - thisWeekMiles
            return "▼ Down \(String(format: "%.1f", diff)) mi vs last week"
        } else {
            return "Same as last week"
        }
    }
    
    private var comparisonColor: Color {
        // Phase 38: Use theme-aware colors for comparison indicators
        if thisWeekMiles > lastWeekMiles {
            return theme.isDarkMode ? .green : Color(red: 0.0, green: 0.6, blue: 0.0) // Darker green for light mode
        } else if thisWeekMiles < lastWeekMiles {
            return theme.isDarkMode ? .orange : Color(red: 0.8, green: 0.4, blue: 0.0) // Darker orange for light mode
        } else {
            return theme.secondaryText
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Weekly Summary")
                    .font(.headline)
                    .foregroundColor(theme.primaryText)
                Spacer()
            }
            
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This Week")
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryText)
                    Text(String(format: "%.1f mi", thisWeekMiles))
                        .font(.title2.bold())
                        .foregroundColor(theme.primaryText)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Week")
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryText)
                    Text(String(format: "%.1f mi", lastWeekMiles))
                        .font(.title2.bold())
                        .foregroundColor(theme.primaryText)
                }
                
                Spacer()
            }
            
            HStack {
                Text(comparisonText)
                    .font(.caption)
                    .foregroundColor(comparisonColor)
                Spacer()
            }
        }
        .padding()
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Distance Trend Chart

struct DistanceTrendChart: View {
    let trendPoints: [RideTrendPoint]
    @ObservedObject private var theme = ThemeManager.shared
    
    private var maxDistance: Double {
        trendPoints.map { $0.totalDistanceMiles }.max() ?? 1.0
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Chart
            GeometryReader { geometry in
                if trendPoints.count > 1 && maxDistance > 0 {
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let barWidth = width / CGFloat(trendPoints.count) - 4
                    
                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(trendPoints) { point in
                            VStack {
                                Spacer()
                                
                                // Bar
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(theme.accentColor)
                                    .frame(width: barWidth, height: max(2, CGFloat(point.totalDistanceMiles / maxDistance) * height))
                                
                                // Day label
                                Text(dayLabel(for: point.date))
                                    .font(.caption2)
                                    .foregroundColor(theme.secondaryText)
                                    .frame(width: barWidth)
                            }
                        }
                    }
                    .frame(height: height)
                } else {
                    Text("No data")
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(height: 180)
            
            // Y-axis label
            HStack {
                Text("Distance (miles)")
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
                Spacer()
                Text(String(format: "Max: %.1f mi", maxDistance))
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }
        }
        .padding()
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E" // Mon, Tue, etc.
        return formatter.string(from: date)
    }
}

// MARK: - Trend Day Row

struct TrendDayRow: View {
    let point: RideTrendPoint
    @ObservedObject private var theme = ThemeManager.shared
    
    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter.string(from: point.date)
    }
    
    private var durationText: String {
        let hours = Int(point.totalDurationSeconds) / 3600
        let minutes = (Int(point.totalDurationSeconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(dateLabel)
                    .font(.subheadline.bold())
                    .foregroundColor(theme.primaryText)
                
                HStack(spacing: 12) {
                    Label(String(format: "%.2f mi", point.totalDistanceMiles), systemImage: "location.fill")
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                    
                    Label(durationText, systemImage: "clock.fill")
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                    
                    if point.averageSpeedMph > 0 {
                        Label(String(format: "%.1f mph", point.averageSpeedMph), systemImage: "speedometer")
                            .font(.caption)
                            .foregroundColor(theme.secondaryText)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Empty Insights View

struct EmptyInsightsView: View {
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(theme.secondaryText)
            
            Text("No rides yet")
                .font(.title2.bold())
                .foregroundColor(theme.primaryText)
            
            Text("Your ride trends will appear here after your first ride.")
                .font(.body)
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(40)
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
    }
}

