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
            // Full-screen dark background
            theme.primaryBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // 1. PRIMARY STATS ROW
                    HStack(spacing: 16) {
                        PrimaryStatCard(
                            icon: "location.fill",
                            value: String(format: "%.2f", distanceMiles),
                            unit: "mi",
                            label: "Distance"
                        )
                        
                        PrimaryStatCard(
                            icon: "clock.fill",
                            value: durationText,
                            unit: nil,
                            label: "Duration"
                        )
                        
                        PrimaryStatCard(
                            icon: "speedometer",
                            value: String(format: "%.1f", averageSpeedMph),
                            unit: "mph",
                            label: "Avg Speed"
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    
                    // 2. RIDE INSIGHTS SECTION
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ride Insights")
                            .font(.headline)
                            .foregroundColor(Color.branchrAccent)
                            .padding(.horizontal, 16)
                        
                        VStack(spacing: 12) {
                            InsightCard(
                                icon: "figure.run",
                                title: "Average Pace",
                                value: averagePace
                            )
                            
                            InsightCard(
                                icon: "flame.fill",
                                title: "Estimated Calories",
                                value: ride.calories > 0 ? String(format: "%.0f cal", ride.calories) : "Coming soon"
                            )
                            
                            InsightCard(
                                icon: "map.fill",
                                title: "Route Samples",
                                value: "\(ride.route.count) points"
                            )
                            
                            // Future charts note
                            HStack(spacing: 8) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .foregroundColor(Color.branchrAccent.opacity(0.7))
                                Text("Speed and distance trend charts coming in future phases")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(0.3))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.branchrAccent.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // 3. DONE BUTTON - Phase 35B: Call onDone closure for finalization
                    Button(action: {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("EnhancedRideSummaryCloseRequested"),
                            object: nil
                        )
                        onDone?()
                        dismiss()
                    }) {
                        Text("Done")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.branchrAccent)
                                    .shadow(color: Color.branchrAccent.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
        }
        .preferredColorScheme(.dark)
        .opacity(showFadeIn ? 1.0 : 0.0)
        .onAppear {
            // Check if ride is already saved
            isSaved = rideDataManager.rides.contains { $0.id == ride.id }
            
            // Auto-save only rides longer than 5 minutes
            if !isSaved && ride.duration >= 300 {
                saveRide(silent: true)
            }
            
            // Fade-in animation
            withAnimation(.easeIn(duration: 0.4)) {
                showFadeIn = true
            }
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

// MARK: - Primary Stat Card Component

struct PrimaryStatCard: View {
    let icon: String
    let value: String
    let unit: String?
    let label: String
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color.branchrAccent)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.headline.bold())
                    .foregroundColor(.white)
                
                if let unit = unit {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(Color.branchrAccent.opacity(0.7))
                }
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.branchrAccent.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: Color.branchrAccent.opacity(0.2), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Insight Card Component

struct InsightCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color.branchrAccent)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(value)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.branchrAccent.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
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
