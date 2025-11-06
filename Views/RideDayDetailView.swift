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
                    // Header
                    VStack(spacing: 8) {
                        Text(formattedDate)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        if rides.isEmpty {
                            Text("No rides recorded")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        } else {
                            Text("\(rides.count) ride\(rides.count == 1 ? "" : "s")")
                                .font(.subheadline)
                                .foregroundColor(.gray)
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
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
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
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 30)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Day Summary Card
struct DaySummaryCard: View {
    let stats: DayStats
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("Day Summary")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
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
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Ride Row View
struct RideRowView: View {
    let ride: RideRecord
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Time
                VStack(alignment: .leading, spacing: 4) {
                    Text(timeFormatter.string(from: ride.date))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(ride.formattedDuration)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(width: 80, alignment: .leading)
                
                // Distance
                VStack(alignment: .leading, spacing: 4) {
                    Text(ride.formattedDistance)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(ride.formattedAverageSpeed)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Calories
                VStack(alignment: .trailing, spacing: 4) {
                    Text(ride.formattedCalories)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    
                    Text("burned")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(width: 80, alignment: .trailing)
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
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
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bicycle")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No Rides Today")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("Start tracking your rides to see them here")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
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
