//
//  RideCalendarView.swift
//  branchr
//
//  Created by Joe Dormond on 10/23/25.
//

import SwiftUI

/// Calendar view showing ride activity by date
struct RideCalendarView: View {
    
    // MARK: - Properties
    @StateObject private var rideDataManager = RideDataManager()
    @StateObject private var calorieCalculator = CalorieCalculator()
    @State private var selectedDate = Date()
    @State private var showingDayDetail = false
    @State private var showingWeightSettings = false
    
    // MARK: - Computed Properties
    private var calendar: Calendar {
        Calendar.current
    }
    
    private var currentMonth: Date {
        calendar.dateInterval(of: .month, for: selectedDate)?.start ?? selectedDate
    }
    
    private var monthRides: [RideRecord] {
        let startOfMonth = calendar.dateInterval(of: .month, for: selectedDate)?.start ?? selectedDate
        let endOfMonth = calendar.dateInterval(of: .month, for: selectedDate)?.end ?? selectedDate
        
        return rideDataManager.rides.filter { ride in
            ride.date >= startOfMonth && ride.date < endOfMonth
        }
    }
    
    private var monthStats: MonthStats {
        let totalDistance = monthRides.map { $0.distance }.reduce(0, +)
        let totalCalories = monthRides.map { $0.calories }.reduce(0, +)
        let totalRides = monthRides.count
        
        return MonthStats(
            totalDistance: totalDistance,
            totalCalories: totalCalories,
            totalRides: totalRides
        )
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Ride Calendar")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Track your fitness journey")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top)
                    
                    // Month Selector
                    HStack {
                        Button(action: previousMonth) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Text(monthFormatter.string(from: currentMonth))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: nextMonth) {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Calendar Grid
                    CalendarGridView(
                        month: currentMonth,
                        rides: monthRides,
                        selectedDate: $selectedDate,
                        onDateSelected: { date in
                            selectedDate = date
                            showingDayDetail = true
                        }
                    )
                    
                    // Month Summary
                    MonthSummaryCard(stats: monthStats)
                    
                    // Weight Settings
                    WeightSettingsCard(
                        calorieCalculator: calorieCalculator,
                        showingSettings: $showingWeightSettings
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .background(Color.black)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingDayDetail) {
            RideDayDetailView(
                date: selectedDate,
                rides: ridesForDate(selectedDate),
                rideDataManager: rideDataManager
            )
        }
        .sheet(isPresented: $showingWeightSettings) {
            WeightSettingsView(calorieCalculator: calorieCalculator)
        }
    }
    
    // MARK: - Private Methods
    
    private func previousMonth() {
        selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
    }
    
    private func nextMonth() {
        selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
    }
    
    private func ridesForDate(_ date: Date) -> [RideRecord] {
        return rideDataManager.rides.filter { ride in
            calendar.isDate(ride.date, inSameDayAs: date)
        }
    }
    
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
}

// MARK: - Calendar Grid View
struct CalendarGridView: View {
    let month: Date
    let rides: [RideRecord]
    @Binding var selectedDate: Date
    let onDateSelected: (Date) -> Void
    
    private var calendar: Calendar {
        Calendar.current
    }
    
    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else { return [] }
        
        let startOfMonth = monthInterval.start
        let endOfMonth = monthInterval.end
        
        var days: [Date] = []
        var currentDate = startOfMonth
        
        while currentDate < endOfMonth {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return days
    }
    
    private var firstWeekday: Int {
        guard let firstDay = daysInMonth.first else { return 0 }
        return calendar.component(.weekday, from: firstDay) - 1
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Weekday headers
            HStack {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                // Empty cells for days before month starts
                ForEach(0..<firstWeekday, id: \.self) { _ in
                    Color.clear
                        .frame(height: 40)
                }
                
                // Days of the month
                ForEach(daysInMonth, id: \.self) { date in
                    CalendarDayView(
                        date: date,
                        rides: ridesForDate(date),
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDate(date, inSameDayAs: Date())
                    ) {
                        selectedDate = date
                        onDateSelected(date)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func ridesForDate(_ date: Date) -> [RideRecord] {
        return rides.filter { ride in
            calendar.isDate(ride.date, inSameDayAs: date)
        }
    }
}

// MARK: - Calendar Day View
struct CalendarDayView: View {
    let date: Date
    let rides: [RideRecord]
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void
    
    private var calendar: Calendar {
        Calendar.current
    }
    
    private var dayNumber: Int {
        calendar.component(.day, from: date)
    }
    
    private var rideIntensity: RideIntensity {
        guard !rides.isEmpty else { return .none }
        
        let totalDistance = rides.map { $0.distance }.reduce(0, +)
        let distanceKm = totalDistance / 1000.0
        
        switch distanceKm {
        case 0..<5:
            return .light
        case 5..<15:
            return .medium
        default:
            return .heavy
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text("\(dayNumber)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(textColor)
                
                if !rides.isEmpty {
                    Circle()
                        .fill(intensityColor)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 40, height: 40)
            .background(backgroundColor, in: Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return .blue
        } else {
            return .white
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .blue
        } else if isToday {
            return .blue.opacity(0.2)
        } else {
            return .clear
        }
    }
    
    private var intensityColor: Color {
        switch rideIntensity {
        case .none:
            return .clear
        case .light:
            return .green
        case .medium:
            return .yellow
        case .heavy:
            return .red
        }
    }
}

// MARK: - Month Summary Card
struct MonthSummaryCard: View {
    let stats: MonthStats
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("This Month")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                StatRow(
                    icon: "figure.walk",
                    title: "Total Distance",
                    value: stats.formattedTotalDistance
                )
                
                StatRow(
                    icon: "flame.fill",
                    title: "Total Calories",
                    value: stats.formattedTotalCalories
                )
                
                StatRow(
                    icon: "bicycle",
                    title: "Total Rides",
                    value: "\(stats.totalRides)"
                )
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Weight Settings Card
struct WeightSettingsCard: View {
    @ObservedObject var calorieCalculator: CalorieCalculator
    @Binding var showingSettings: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "person.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("Weight Settings")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Edit") {
                    showingSettings = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Weight")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(calorieCalculator.formattedWeight)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Calorie Accuracy")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("Personalized")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(title)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Supporting Types
enum RideIntensity {
    case none
    case light
    case medium
    case heavy
}

struct MonthStats {
    let totalDistance: Double
    let totalCalories: Double
    let totalRides: Int
    
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
}

// MARK: - Preview
#Preview {
    RideCalendarView()
        .preferredColorScheme(.dark)
}
