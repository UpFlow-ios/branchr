//
//  RideCalendarView.swift
//  branchr
//
//  Created by Joseph Dormond on 2025-11-05
//  Phase 30 - Ride Calendar & History View
//

import SwiftUI

/**
 * 📅 Ride Calendar View
 *
 * Displays ride history in a calendar-like format.
 * Shows all recorded rides with date, distance, duration, and speed.
 */
struct RideCalendarView: View {
    @StateObject private var rideDataManager = RideDataManager.shared
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerSection
                    
                    // Stats Summary
                    if !rideDataManager.rides.isEmpty {
                        statsSummarySection
                    }
                    
                    // Ride List
                    if rideDataManager.rides.isEmpty {
                        emptyStateView
                    } else {
                        rideListSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(theme.primaryBackground.ignoresSafeArea())
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                // Refresh rides when view appears
                rideDataManager.rides = rideDataManager.loadRides()
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ride History")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(theme.primaryText)
            
            Text("Track your rides and progress")
                .font(.subheadline)
                .foregroundColor(theme.secondaryText)
        }
    }
    
    // MARK: - Stats Summary
    
    private var statsSummarySection: some View {
        HStack(spacing: 16) {
            CalendarStatCard(
                icon: "bicycle.circle.fill",
                title: "Total Rides",
                value: "\(rideDataManager.rideCount)",
                color: theme.accentColor
            )
            
            CalendarStatCard(
                icon: "location.fill",
                title: "Total Distance",
                value: String(format: "%.1f", rideDataManager.totalDistance / 1609.34),
                unit: "mi",
                color: theme.accentColor
            )
            
            CalendarStatCard(
                icon: "clock.fill",
                title: "Total Time",
                value: formatDuration(rideDataManager.totalDuration),
                color: theme.accentColor
            )
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 64))
                .foregroundColor(theme.secondaryText.opacity(0.5))
            
            Text("No rides recorded yet")
                .font(.headline)
                .foregroundColor(theme.primaryText)
            
            Text("Start a ride from the Home tab to begin tracking")
                .font(.subheadline)
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Ride List
    
    private var rideListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Rides")
                .font(.headline)
                .foregroundColor(theme.primaryText)
                .padding(.top, 8)
            
            ForEach(rideDataManager.rides) { ride in
                CalendarRideCard(ride: ride)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Calendar Stat Card Component (Phase 30)

struct CalendarStatCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String?
    let color: Color
    
    @ObservedObject private var theme = ThemeManager.shared
    
    init(icon: String, title: String, value: String, unit: String? = nil, color: Color) {
        self.icon = icon
        self.title = title
        self.value = value
        self.unit = unit
        self.color = color
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.headline.bold())
                    .foregroundColor(theme.primaryText)
                
                if let unit = unit {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                }
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Calendar Ride Card Component (Phase 30)

struct CalendarRideCard: View {
    let ride: RideRecord
    
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Calendar Icon
            VStack(spacing: 4) {
                Text(ride.calendarDayOfMonth)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(theme.accentColor)
                Text(ride.calendarMonthAbbreviation)
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }
            .frame(width: 50, height: 50)
            .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 8))
            
            // Ride Details
            VStack(alignment: .leading, spacing: 6) {
                Text(ride.displayTitle)
                    .font(.headline)
                    .foregroundColor(theme.primaryText)
                
                HStack(spacing: 16) {
                    Label(String(format: "%.2f mi", ride.calendarDistanceInMiles), systemImage: "location.fill")
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                    
                    Label(ride.formattedDuration, systemImage: "clock.fill")
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                }
            }
            
            Spacer()
            
            // Bike Icon
            Image(systemName: "bicycle.circle.fill")
                .font(.title2)
                .foregroundColor(theme.accentColor)
        }
        .padding()
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - RideRecord Extensions for Calendar View (Phase 30)

extension RideRecord {
    var calendarDayOfMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var calendarMonthAbbreviation: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
    
    var calendarDistanceInMiles: Double {
        return distance / 1609.34
    }
}

// MARK: - Preview

#Preview {
    RideCalendarView()
        .preferredColorScheme(.dark)
}

