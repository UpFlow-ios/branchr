//
//  RideCalendarView.swift
//  branchr
//
//  Created by Joseph Dormond on 2025-11-05
//  Phase 30 - Ride Calendar & History View
//  Phase 34 - Calendar Grid with Daily Stats
//

import SwiftUI

/**
 * 📅 Ride Calendar View
 *
 * Phase 34: Monthly calendar grid showing days with rides.
 * Tap a day to view stats for that day.
 */
struct RideCalendarView: View {
    @StateObject private var rideDataManager = RideDataManager.shared
    @ObservedObject private var theme = ThemeManager.shared
    @State private var selectedDay: Date? = nil
    @State private var showStatsSheet = false
    @State private var showNoRidesAlert = false
    @State private var noRidesMessage: String? = nil
    @State private var refreshTrigger = UUID()
    
    let calendar = Calendar.current
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Month/Year Header
                Text(currentMonthYear)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(theme.primaryText)
                    .padding(.top, 20)
                
                // Calendar Grid
                LazyVGrid(columns: columns, spacing: 12) {
                    // Day labels (Sun, Mon, Tue, etc.) - Phase 34E: Fix duplicate IDs
                    ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { _, day in
                        Text(day)
                            .font(.caption.bold())
                            .foregroundColor(theme.secondaryText)
                    }
                    
                    // Calendar days
                    ForEach(daysInMonth, id: \.self) { day in
                        CalendarDayCell(
                            day: day,
                            summary: rideDataManager.summary(for: day),
                            theme: theme
                        ) {
                            // Phase 34: Show stats if rides exist, otherwise show "No rides" message
                            if let summary = rideDataManager.summary(for: day), !summary.rides.isEmpty {
                                selectedDay = day
                                showStatsSheet = true
                            } else {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "MMM d"
                                noRidesMessage = "🚫 No rides on \(formatter.string(from: day))"
                                showNoRidesAlert = true
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.primaryBackground.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showStatsSheet) {
                if let day = selectedDay,
                   let summary = rideDataManager.summary(for: day) {
                    DayStatsSheet(day: day, summary: summary)
                        .transition(.opacity)
                }
            }
            .alert("No Rides", isPresented: $showNoRidesAlert) {
                Button("OK", role: .cancel) {
                    noRidesMessage = nil
                }
            } message: {
                if let message = noRidesMessage {
                    Text(message)
                }
            }
            .onAppear {
                rideDataManager.rides = rideDataManager.loadRides()
            }
            .onReceive(NotificationCenter.default.publisher(for: .branchrRidesDidChange)) { _ in
                // Refresh rides when notification is received
                rideDataManager.rides = rideDataManager.loadRides()
                refreshTrigger = UUID() // Force view refresh
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }
    
    private var daysInMonth: [Date] {
        let date = Date()
        guard let range = calendar.range(of: .day, in: .month, for: date),
              let start = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else {
            return []
        }
        
        // Add padding for days before month starts
        let firstWeekday = calendar.component(.weekday, from: start)
        let paddingDays = (firstWeekday - 1) % 7
        var days: [Date] = []
        
        // Add padding
        for i in 0..<paddingDays {
            if let paddingDate = calendar.date(byAdding: .day, value: -paddingDays + i, to: start) {
                days.append(paddingDate)
            }
        }
        
        // Add actual month days
        for dayOffset in 0..<range.count {
            if let day = calendar.date(byAdding: .day, value: dayOffset, to: start) {
                days.append(day)
            }
        }
        
        return days
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let day: Date
    let summary: DayRideSummary?
    let theme: ThemeManager
    let action: () -> Void
    
    private var calendar: Calendar { Calendar.current }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: day))")
                    .font(.headline)
                    .foregroundColor(isCurrentMonth ? theme.primaryText : theme.secondaryText.opacity(0.3))
                
                if let summary = summary {
                    Text(String(format: "%.1f", summary.totalDistanceInMiles))
                        .font(.caption2.bold())
                        .foregroundColor(theme.accentColor)
                }
            }
            .frame(width: 40, height: 40)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(summary != nil ? theme.accentColor.opacity(0.2) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(summary != nil ? theme.accentColor : Color.clear, lineWidth: 1)
            )
        }
        .disabled(!isCurrentMonth)
    }
    
    private var isCurrentMonth: Bool {
        calendar.isDate(day, equalTo: Date(), toGranularity: .month)
    }
}

// MARK: - Day Stats Sheet

struct DayStatsSheet: View {
    let day: Date
    let summary: DayRideSummary
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRide: RideRecord?
    @State private var showRideSummary = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Rides on \(day.formatted(date: .abbreviated, time: .omitted))")
                    .font(.title2.bold())
                    .foregroundColor(theme.primaryText)
                    .padding(.top, 20)
                
                VStack(spacing: 16) {
                    StatRow(label: "Total Distance", value: String(format: "%.2f mi", summary.totalDistanceInMiles))
                    StatRow(label: "Total Time", value: summary.formattedDuration)
                    StatRow(label: "Number of Rides", value: "\(summary.rides.count)")
                }
                .padding()
                .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)
                
                if summary.rides.count > 0 {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Individual Rides")
                            .font(.headline)
                            .foregroundColor(theme.primaryText)
                            .padding(.horizontal, 20)
                        
                        ForEach(summary.rides) { ride in
                            Button {
                                selectedRide = ride
                                showRideSummary = true
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(ride.displayTitle)
                                            .font(.subheadline.bold())
                                            .foregroundColor(theme.primaryText)
                                        Text("\(String(format: "%.2f", ride.distanceInMiles)) mi • \(ride.formattedDuration)")
                                            .font(.caption)
                                            .foregroundColor(theme.secondaryText)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.bold())
                                        .foregroundColor(theme.secondaryText)
                                }
                                .padding()
                                .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 8))
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                }
                
                Spacer()
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
            .sheet(isPresented: $showRideSummary) {
                if let ride = selectedRide {
                    EnhancedRideSummaryView(ride: ride, onDone: nil)
                        .presentationDetents([.large])
                }
            }
        }
    }
}

// MARK: - Stat Row

struct StatRow: View {
    let label: String
    let value: String
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(theme.secondaryText)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(theme.primaryText)
        }
    }
}

// MARK: - Preview

#Preview {
    RideCalendarView()
        .preferredColorScheme(.dark)
}
