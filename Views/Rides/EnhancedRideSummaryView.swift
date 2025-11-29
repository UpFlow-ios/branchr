//
//  EnhancedRideSummaryView.swift
//  branchr
//
//  Created for Phase 35C - Enhanced Ride Summary with Mini Map and Charts
//

import SwiftUI
import MapKit

struct EnhancedRideSummaryView: View {
    let ride: RideRecord
    let onDone: (() -> Void)?
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @StateObject private var rideDataManager = RideDataManager.shared
    @State private var isSaved = false
    @State private var showFadeIn = false
    @State private var showRideInsights = false // Phase 38: Ride Insights sheet
    
    init(ride: RideRecord, onDone: (() -> Void)? = nil) {
        self.ride = ride
        self.onDone = onDone
    }

    // Computed properties for conversions
    private var distanceMiles: Double {
        ride.distance / 1609.34
    }
    
    private var durationText: String {
        let hours = Int(ride.duration) / 3600
        let minutes = (Int(ride.duration) % 3600) / 60
        let seconds = Int(ride.duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    private var averageSpeedMph: Double {
        ride.averageSpeed * 2.237 // Convert m/s to mph
    }
    
    private var averagePace: String {
        guard distanceMiles > 0 else { return "N/A" }
        let paceMinutes = Int(ride.duration / 60.0 / distanceMiles)
        let paceSeconds = Int((ride.duration / distanceMiles).truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d min/mi", paceMinutes, paceSeconds)
    }

    var body: some View {
        ZStack {
            // Full-screen background
            theme.primaryBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Top spacing
                    Spacer()
                        .frame(height: 16)
                    
                    // Phase 45: Header
                    headerSection
                        .padding(.horizontal, 16)
                    
                    // Phase 45: Main Metrics Card
                    mainMetricsCard
                        .padding(.horizontal, 16)
                        .scaleEffect(showFadeIn ? 1.0 : 0.98)
                        .opacity(showFadeIn ? 1.0 : 0.0)
                    
                    // Phase 45: Secondary Stats Row (optional)
                    if hasSecondaryStats {
                        secondaryStatsRow
                            .padding(.horizontal, 16)
                            .opacity(showFadeIn ? 1.0 : 0.0)
                    }
                    
                    // Phase 45: Actions Row
                    actionsRow
                        .padding(.horizontal, 16)
                        .padding(.bottom, 40)
                        .opacity(showFadeIn ? 1.0 : 0.0)
                }
            }
        }
        .sheet(isPresented: $showRideInsights) {
            RideInsightsView()
                .presentationDetents([.large])
        }
        .onAppear {
            // Check if ride is already saved
            isSaved = rideDataManager.rides.contains { $0.id == ride.id }
            
            // Auto-save only rides longer than 5 minutes
            if !isSaved && ride.duration >= 300 {
                saveRide(silent: true)
            }
            
            // Haptic feedback on appear
            HapticsService.shared.mediumTap()
            
            // Fade-in and scale animation
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showFadeIn = true
            }
        }
    }
    
    // MARK: - Phase 45: UI Components
    
    /// Header section with title
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Ride Summary")
                .font(.title3.bold())
                .foregroundColor(Color.white)
            
            Text("Nice ride!")
                .font(.subheadline)
                .foregroundColor(Color.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    /// Main metrics card with distance, duration, and avg speed
    private var mainMetricsCard: some View {
        HStack(spacing: 24) {
            // Distance
            MetricDisplay(
                icon: "location.fill",
                value: String(format: "%.2f", distanceMiles),
                unit: "mi",
                label: "Distance"
            )
            
            // Duration
            MetricDisplay(
                icon: "clock.fill",
                value: durationText,
                unit: nil,
                label: "Duration"
            )
            
            // Avg Speed
            MetricDisplay(
                icon: "speedometer",
                value: String(format: "%.1f", averageSpeedMph),
                unit: "mph",
                label: "Avg Speed"
            )
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(theme.surfaceBackground)
                .shadow(
                    color: theme.isDarkMode ? .clear : Color.black.opacity(0.25),
                    radius: theme.isDarkMode ? 0 : 18,
                    x: 0,
                    y: theme.isDarkMode ? 0 : 8
                )
        )
    }
    
    /// Secondary stats row (pace, calories, route points)
    private var secondaryStatsRow: some View {
        HStack(spacing: 12) {
            SecondaryStatPill(
                icon: "figure.run",
                label: "Pace",
                value: averagePace
            )
            
            if ride.calories > 0 {
                SecondaryStatPill(
                    icon: "flame.fill",
                    label: "Calories",
                    value: String(format: "%.0f", ride.calories)
                )
            }
            
            SecondaryStatPill(
                icon: "map.fill",
                label: "Route",
                value: "\(ride.route.count) pts"
            )
        }
    }
    
    /// Check if secondary stats are available
    private var hasSecondaryStats: Bool {
        averagePace != "N/A" || ride.calories > 0 || !ride.route.isEmpty
    }
    
    /// Actions row with primary and secondary buttons
    private var actionsRow: some View {
        VStack(spacing: 12) {
            // Primary button
            Button(action: {
                NotificationCenter.default.post(
                    name: NSNotification.Name("EnhancedRideSummaryCloseRequested"),
                    object: nil
                )
                onDone?()
                dismiss()
            }) {
                Text("Done")
                    .font(.headline.bold())
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(theme.brandYellow)
                            .shadow(
                                color: Color.black.opacity(0.2),
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                    )
            }
            .buttonStyle(.plain)
            
            // Secondary button - View Ride Insights
            Button(action: {
                showRideInsights = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.caption)
                    Text("View Ride Insights")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(Color.white.opacity(0.85))
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Save Action
    
    private func saveRide(silent: Bool = false) {
        // Check if already saved to avoid duplicates
        guard !rideDataManager.rides.contains(where: { $0.id == ride.id }) else {
            isSaved = true
            return
        }
        
        rideDataManager.saveRide(ride)
        isSaved = true
        
        if !silent {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            VoiceFeedbackService.shared.speak("Ride saved")
        }
        
        // Upload to Firebase
        FirebaseRideService.shared.uploadRide(ride) { error in
            if let error = error {
                print("❌ Failed to upload ride: \(error.localizedDescription)")
            } else {
                print("☁️ Ride synced to Firebase successfully")
            }
        }
        
        // Post notification for calendar refresh
        NotificationCenter.default.post(name: .branchrRidesDidChange, object: nil)
    }
}

// MARK: - Phase 45: Metric Display Component

/// Large, readable metric display for main stats card
struct MetricDisplay: View {
    let icon: String
    let value: String
    let unit: String?
    let label: String
    
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(theme.brandYellow)
            
            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white)
                    
                    if let unit = unit {
                        Text(unit)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.78))
                    }
                }
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Phase 45: Secondary Stat Pill Component

/// Compact pill for secondary stats
struct SecondaryStatPill: View {
    let icon: String
    let label: String
    let value: String
    
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(theme.brandYellow)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(Color.white.opacity(0.7))
                Text(value)
                    .font(.caption.bold())
                    .foregroundColor(Color.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.6))
        )
    }
}

// MARK: - Insight Card Component

struct InsightCard: View {
    let icon: String
    let title: String
    let value: String
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(theme.accentColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryText)
                
                Text(value)
                    .font(.headline)
                    .foregroundColor(theme.primaryText)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.accentColor.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: theme.primaryBackground.opacity(0.3), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Preview

#Preview {
    EnhancedRideSummaryView(
        ride: RideRecord(
            distance: 5000, // meters
            duration: 1800, // 30 minutes
            averageSpeed: 2.78, // m/s (~10 mph)
            calories: 250,
            route: []
        )
    )
    .preferredColorScheme(.dark)
}
