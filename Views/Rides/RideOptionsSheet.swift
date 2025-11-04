//
//  RideOptionsSheet.swift
//  branchr
//
//  Created by Joseph Dormond on 2025-11-03
//  Phase 20 - Ride Options Modal
//

import SwiftUI

/**
 * 🚴‍♂️ Ride Options Sheet
 *
 * Bottom sheet modal that appears when user taps "Stop Ride Tracking".
 * Provides options to: Resume, End Ride, or trigger SOS Emergency.
 */
struct RideOptionsSheet: View {
    
    @ObservedObject var rideService: RideTrackingService
    @Binding var showSummary: Bool
    @Binding var dismiss: Bool
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            // Drag handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
            
            Text("Ride Options")
                .font(.title2.bold())
                .foregroundColor(theme.primaryText)
                .padding(.top, 8)
            
            // Current ride stats (if active)
            if rideService.rideState == .active {
                VStack(spacing: 8) {
                    HStack {
                        Text("Distance:")
                            .font(.subheadline)
                            .foregroundColor(theme.primaryText.opacity(0.7))
                        Spacer()
                        Text(rideService.formattedDistance)
                            .font(.subheadline.bold())
                            .foregroundColor(theme.accentColor)
                    }
                    
                    HStack {
                        Text("Duration:")
                            .font(.subheadline)
                            .foregroundColor(theme.primaryText.opacity(0.7))
                        Spacer()
                        Text(rideService.formatTime(rideService.duration))
                            .font(.subheadline.bold())
                            .foregroundColor(theme.accentColor)
                    }
                }
                .padding()
                .background(theme.cardBackground)
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            // Action buttons
            VStack(spacing: 14) {
                // Resume Ride (if paused)
                if rideService.rideState == .paused {
                    BranchrButton(
                        title: "Resume Ride",
                        icon: "play.fill"
                    ) {
                        rideService.resumeRide()
                        dismiss = false
                    }
                }
                
                // End Ride
                BranchrButton(
                    title: "End Ride",
                    icon: "flag.checkered"
                ) {
                    rideService.endRide()
                    dismiss = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showSummary = true
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                
                // SOS Emergency
                Button(action: {
                    // Call emergency services
                    if let url = URL(string: "tel://911") {
                        UIApplication.shared.open(url)
                    }
                    // Also trigger SOS in app
                    print("🚨 SOS Emergency triggered")
                }) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.headline)
                        Text("🚨 SOS Emergency")
                            .font(.headline.bold())
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.red, lineWidth: 2)
                    )
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.vertical)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.primaryBackground.ignoresSafeArea())
        .presentationDetents([.fraction(0.4)])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Preview

#Preview {
    RideOptionsSheet(
        rideService: RideTrackingService(),
        showSummary: .constant(false),
        dismiss: .constant(true)
    )
}

