//
//  RideDayDetailView.swift
//  branchr
//
//  Created by Joe Dormond on 10/23/25.
//

import SwiftUI

/// Detail view showing all rides for a specific date
struct RideDayDetailView: View {
    
    // MARK: - Properties
    let date: Date
    let rides: [RideRecord]
    let rideDataManager: RideDataManager
    
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRide: RideRecord?
    
    // MARK: - Computed Properties
    private var calendar: Calendar {
        Calendar.current
    }
    
    private var dayStats: DayStats {
        let totalDistance = rides.map { $0.distance }.reduce(0, +)
        let totalCalories = rides.map { $0.calories }.reduce(0, +)
        let totalDuration = rides.map { $0.duration }.reduce(0, +)
        
        return DayStats(
            totalDistance: totalDistance,
            totalCalories: totalCalories,
            totalDuration: totalDuration,
            rideCount: rides.count
        )
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header - Phase 37: Use theme-aware colors
                    VStack(spacing: 8) {
                        Text(formattedDate)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(theme.primaryText)
                            .multilineTextAlignment(.center)
                        
                        if rides.isEmpty {
                            Text("No rides recorded")
                                .font(.subheadline)
                                .foregroundColor(theme.secondaryText)
                        } else {
                            Text("\(rides.count) ride\(rides.count == 1 ? "" : "s")")
                                .font(.subheadline)
                                .foregroundColor(theme.secondaryText)
                        }
                    }
                    .padding(.top)
                    
                    // Day Summary (if rides exist)
                    if !rides.isEmpty {
                        DaySummaryCard(stats: dayStats)
                    }
                    
                    // Rides List
                    if rides.isEmpty {
                        EmptyStateView()
                    } else {
                        VStack(spacing: 12) {
                            ForEach(rides.sorted(by: { $0.date > $1.date })) { ride in
                                RideRowView(ride: ride) {
                                    selectedRide = ride
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .background(theme.primaryBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.accentColor)
                }
            }
        }
        .sheet(item: $selectedRide) { ride in
            RideSummaryView(
                ride: ride,
                rideDataManager: rideDataManager,
                onDismiss: {
                    selectedRide = nil
                }
            )
        }
    }
}

// MARK: - Stat Row View Component
struct StatRowView: View {
    let icon: String
    let title: String
    let value: String
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(theme.accentColor)
                .frame(width: 30)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(theme.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.primaryText)
        }
    }
}

// MARK: - Day Summary Card
struct DaySummaryCard: View {
    let stats: DayStats
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.title2)
                    .foregroundColor(theme.accentColor)
                
                Text("Day Summary")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                    StatRowView(
                    icon: "figure.walk",
                    title: "Total Distance",
                    value: stats.formattedTotalDistance
                )
                
                    StatRowView(
                    icon: "flame.fill",
                    title: "Total Calories",
                    value: stats.formattedTotalCalories
                )
                
                    StatRowView(
                    icon: "clock",
                    title: "Total Time",
                    value: stats.formattedTotalDuration
                )
                
                    StatRowView(
                    icon: "bicycle",
                    title: "Rides",
                    value: "\(stats.rideCount)"
                )
            }
        }
        .padding(20)
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Ride Row View
struct RideRowView: View {
    let ride: RideRecord
    let onTap: () -> Void
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Time
                VStack(alignment: .leading, spacing: 4) {
                    Text(timeFormatter.string(from: ride.date))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryText)
                    
                    Text(ride.formattedDuration)
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                }
                .frame(width: 80, alignment: .leading)
                
                // Distance
                VStack(alignment: .leading, spacing: 4) {
                    Text(ride.formattedDistance)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryText)
                    
                    Text(ride.formattedAverageSpeed)
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Calories
                VStack(alignment: .trailing, spacing: 4) {
                    Text(ride.formattedCalories)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.accentColor)
                    
                    Text("burned")
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                }
                .frame(width: 80, alignment: .trailing)
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }
            .padding(16)
            .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bicycle")
                .font(.system(size: 48))
                .foregroundColor(theme.secondaryText)
            
            Text("No Rides Today")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(theme.primaryText)
            
            Text("Start tracking your rides to see them here")
                .font(.body)
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Supporting Types
struct DayStats {
    let totalDistance: Double
    let totalCalories: Double
    let totalDuration: TimeInterval
    let rideCount: Int
    
    var formattedTotalDistance: String {
        let locale = Locale.current
        let isMetric = locale.usesMetricSystem
        
        if isMetric {
            return String(format: "%.1f km", totalDistance / 1000.0)
        } else {
            return String(format: "%.1f mi", totalDistance * 0.000621371)
        }
    }
    
    var formattedTotalCalories: String {
        return String(format: "%.0f cal", totalCalories)
    }
    
    var formattedTotalDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = Int(totalDuration) % 3600 / 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }
}

// MARK: - Preview
#Preview {
    let sampleRides = [
        RideRecord(
            distance: 5000,
            duration: 1800,
            averageSpeed: 5.0,
            calories: 250,
            route: []
        ),
        RideRecord(
            distance: 3000,
            duration: 1200,
            averageSpeed: 4.5,
            calories: 180,
            route: []
        )
    ]
    
    return RideDayDetailView(
        date: Date(),
        rides: sampleRides,
        rideDataManager: RideDataManager()
    )
    .preferredColorScheme(.dark)
}
