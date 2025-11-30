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
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedDay: Date? = nil
    @State private var selectedSummary: DayRideSummary? = nil
    @State private var selectedRide: RideRecord? = nil
    @State private var showRideDetail = false
    @State private var showNoRidesAlert = false
    @State private var noRidesMessage: String? = nil
    @State private var refreshTrigger = UUID()
    @State private var showRideInsights = false // Phase 38: Ride Insights sheet
    @State private var showRideStats = false // Phase 49: Monthly Ride Stats
    
    // Phase 47: Month navigation state
    @State private var displayedMonth: Date = {
        let calendar = Calendar.current
        let now = Date()
        return calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
    }()
    
    let calendar = Calendar.current
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                // Phase 47: Month/Year Header with Navigation
                HStack(spacing: 16) {
                    Button {
                        changeMonth(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .foregroundColor(theme.brandYellow)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    Text(currentMonthYear)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(theme.primaryText)
                    
                    Spacer()
                    
                    Button {
                        changeMonth(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.headline)
                            .foregroundColor(theme.brandYellow)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 16)
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
                            theme: theme,
                            isSelected: selectedDay.map { calendar.isDate(day, inSameDayAs: $0) } ?? false,
                            isInDisplayedMonth: calendar.isDate(day, equalTo: displayedMonth, toGranularity: .month)
                        ) {
                            // Phase 46C: Toggle selection - tap same day to deselect (with debug verification)
                            if let summary = rideDataManager.summary(for: day), !summary.rides.isEmpty {
                                // Check if this is the same day already selected
                                if let currentSelected = selectedDay, calendar.isDate(day, inSameDayAs: currentSelected) {
                                    // Deselect: hide the card
                                    print("📅 RideCalendarView: Deselecting day (second tap)")
                                    selectedDay = nil
                                    selectedSummary = nil
                                    print("📅 RideCalendarView: selectedDay = nil, selectedSummary = nil")
                                } else {
                                    // Select: show the card
                                    print("📅 RideCalendarView: Selecting day (first tap)")
                                    selectedDay = day
                                    selectedSummary = summary
                                    print("📅 RideCalendarView: selectedDay = \(day), selectedSummary has \(summary.rides.count) rides")
                                }
                                HapticsService.shared.lightTap()
                            } else {
                                // Day has no rides - show alert
                                let formatter = DateFormatter()
                                formatter.dateFormat = "MMM d"
                                noRidesMessage = "🚫 No rides on \(formatter.string(from: day))"
                                showNoRidesAlert = true
                                selectedSummary = nil
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                
                // Phase 46: Selected day ride list / summary
                if let day = selectedDay, let summary = selectedSummary {
                    SelectedDayRideCard(day: day, summary: summary) { ride in
                        selectedRide = ride
                        showRideDetail = true
                        HapticsService.shared.mediumTap()
                    }
                    .padding(.horizontal, 16)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(
                        .spring(response: 0.25, dampingFraction: 0.85),
                        value: summary.date
                    )
                }
                }
                .padding(.bottom, 24)
            }
            .background(theme.primaryBackground.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showRideStats = true
                        print("📊 RideCalendarView: opening RideStatsView for \(currentMonthYear)")
                    } label: {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(theme.accentColor)
                    }
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
            .sheet(isPresented: $showRideInsights) {
                RideInsightsView()
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showRideStats) {
                RideStatsView(
                    month: displayedMonth,
                    onClose: {
                        showRideStats = false
                    },
                    onSelectDay: { date in
                        // Phase 50: Update calendar selection and close stats
                        selectedDay = date
                        if let summary = rideDataManager.summary(for: date) {
                            selectedSummary = summary
                        }
                        showRideStats = false
                        HapticsService.shared.mediumTap()
                    }
                )
                .presentationDetents([.large])
            }
            .sheet(isPresented: $showRideDetail) {
                if let ride = selectedRide {
                    // Phase 46C: RideDetailView already has NavigationView and Done button
                    RideDetailView(ride: ride)
                        .presentationDetents([.large])
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .branchrRidesDidChange)) { _ in
                // Refresh rides when notification is received
                // Phase 46C: Do NOT reset selectedDay/selectedSummary here - preserve user selection
                rideDataManager.rides = rideDataManager.loadRides()
                refreshTrigger = UUID() // Force view refresh
                // If a day is selected, refresh its summary but keep the selection
                if let day = selectedDay {
                    selectedSummary = rideDataManager.summary(for: day)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    // Phase 47: Use displayedMonth instead of Date()
    private var currentMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }
    
    private var daysInMonth: [Date] {
        let date = displayedMonth
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
    
    // Phase 47: Month navigation handler
    private func changeMonth(by offset: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: offset, to: displayedMonth) {
            displayedMonth = newMonth
            // When month changes, clear selection to avoid mismatched days
            selectedDay = nil
            selectedSummary = nil
            HapticsService.shared.lightTap()
        }
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let day: Date
    let summary: DayRideSummary?
    let theme: ThemeManager
    let isSelected: Bool
    let isInDisplayedMonth: Bool // Phase 47: Use displayedMonth instead of Date()
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var calendar: Calendar { Calendar.current }
    private var hasRides: Bool {
        if let summary = summary {
            return !summary.rides.isEmpty
        }
        return false
    }
    
    // Phase 48: Theme-aware colors for unified pill + dot layout
    private var isDark: Bool {
        colorScheme == .dark
    }
    
    private var accentColor: Color {
        isDark ? theme.brandYellow : theme.primaryText
    }
    
    private var textColor: Color {
        if isSelected {
            return isDark ? .black : theme.surfaceBackground
        } else if !isInDisplayedMonth {
            return theme.primaryText.opacity(0.3)
        } else {
            return theme.primaryText
        }
    }
    
    private var pillFill: Color {
        isSelected ? accentColor : .clear
    }
    
    private var pillStroke: Color? {
        hasRides ? accentColor : nil
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Phase 48: Filled pill for selected day
                Capsule()
                    .fill(pillFill)
                
                // Phase 48: Stroke outline when there are rides
                if let pillStroke = pillStroke {
                    Capsule()
                        .stroke(pillStroke, lineWidth: isSelected ? 2 : 1.2)
                }
                
                VStack(spacing: 4) {
                    Text("\(calendar.component(.day, from: day))")
                        .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(textColor)
                    
                    // Phase 48: Dot indicator for days with rides
                    if hasRides {
                        Circle()
                            .fill(isSelected ? textColor : accentColor)
                            .frame(width: 4, height: 4)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
            }
            .opacity(isInDisplayedMonth ? 1.0 : 0.3)
        }
        .buttonStyle(.plain)
        .disabled(!isInDisplayedMonth)
    }
}

// MARK: - Phase 46: Selected Day Ride Card

struct SelectedDayRideCard: View {
    let day: Date
    let summary: DayRideSummary
    let onRideTap: (RideRecord) -> Void
    
    @ObservedObject private var theme = ThemeManager.shared
    
    private var calendar: Calendar { Calendar.current }
    
    private var formattedDate: String {
        day.formatted(date: .abbreviated, time: .omitted)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("Rides on \(formattedDate)")
                .font(.headline.bold())
                .foregroundColor(.white)
            
            // Aggregated stats row
            HStack(spacing: 16) {
                aggregatedStat(label: "Total Distance",
                               value: String(format: "%.2f mi", summary.totalDistanceInMiles))
                aggregatedStat(label: "Total Time",
                               value: summary.formattedDuration)
                aggregatedStat(label: "Rides",
                               value: "\(summary.rides.count)")
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            if summary.rides.isEmpty {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "bicycle")
                        .font(.system(size: 32))
                        .foregroundColor(theme.brandYellow)
                    Text("No rides on this day yet")
                        .font(.subheadline)
                        .foregroundColor(Color.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                // Phase 48: LazyVStack for scrollable rides list (no height constraints)
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(summary.rides) { ride in
                        Button {
                            onRideTap(ride)
                        } label: {
                            rideRow(for: ride)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(theme.surfaceBackground)
                .shadow(
                    color: theme.isDarkMode ? .clear : Color.black.opacity(0.25),
                    radius: theme.isDarkMode ? 0 : 18,
                    x: 0,
                    y: theme.isDarkMode ? 0 : 8
                )
        )
    }
    
    private func aggregatedStat(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(Color.white.opacity(0.7))
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func rideRow(for ride: RideRecord) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: "%.2f mi", ride.distanceInMiles))
                    .font(.headline.bold())
                    .foregroundColor(.white)
                
                Text("\(ride.formattedDuration) • \(String(format: "%.1f mph", ride.averageSpeedInMPH))")
                    .font(.subheadline)
                    .foregroundColor(Color.white.opacity(0.7))
            }
            
            Spacer()
            
            Text(startTimeString(for: ride.date))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(theme.brandYellow)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.7))
        )
    }
    
    private func startTimeString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
                    // Phase 37: Show RideDetailView instead of EnhancedRideSummaryView for calendar rides
                    RideDetailView(ride: ride)
                        .presentationDetents([.large])
                        .onAppear {
                            print("📆 RideCalendarView: selected ride id \(ride.id)")
                        }
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
