//
//  RideTrackingView.swift
//  branchr
//
//  Created by Joseph Dormond on 2025-11-04
//  Phase 31 - Unified Ride Tracking Flow (Sheet View)
//

import SwiftUI
import MapKit
import CoreLocation

/**
 * 🚴‍♂️ Ride Tracking View
 *
 * Unified ride tracking interface launched from HomeView as a sheet.
 * Features:
 * - Real-time map with route tracking
 * - Distance, time, and speed stats
 * - Play/Stop controls
 * - Voice announcements
 * - Branchr black/yellow theme
 */
struct RideTrackingView: View {
    @StateObject private var rideService = RideTrackingService()
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                theme.primaryBackground.ignoresSafeArea()
                
                // Map View
                Map(coordinateRegion: $region, 
                    interactionModes: [.pan, .zoom],
                    showsUserLocation: true,
                    userTrackingMode: .constant(.none),
                    annotationItems: rideService.route.isEmpty ? [] : [MapAnnotation(coordinate: rideService.route.last!)]) { _ in
                    MapPin(coordinate: rideService.route.last!, tint: .red)
                }
                .overlay(
                    // Route polyline overlay (using existing MapPolylineOverlay from MapComponents)
                    MapPolylineOverlay(coordinates: rideService.route)
                )
                .onChange(of: rideService.route.count) { _ in
                    updateMapRegion()
                }
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Ride Tracking")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(theme.primaryText)
                        
                        Spacer()
                        
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(theme.primaryText)
                                .padding(8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Stats HUD
                    HStack(spacing: 30) {
                        RideTrackingStatCard(
                            icon: "location.fill",
                            value: String(format: "%.2f", rideService.totalDistance / 1609.34), // Convert meters to miles
                            label: "Distance",
                            unit: "mi"
                        )
                        
                        RideTrackingStatCard(
                            icon: "clock.fill",
                            value: formatDuration(rideService.duration),
                            label: "Time"
                        )
                        
                        RideTrackingStatCard(
                            icon: "speedometer",
                            value: String(format: "%.1f", rideService.averageSpeed * 0.621371), // Convert km/h to mph
                            label: "Avg Speed",
                            unit: "mph"
                        )
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    
                    // Controls
                    HStack(spacing: 40) {
                        if rideService.rideState == .idle || rideService.rideState == .ended {
                            Button(action: {
                                rideService.startRide()
                                VoiceFeedbackService.shared.speak("Starting ride tracking")
                            }) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.green)
                            }
                        } else if rideService.rideState == .active {
                            Button(action: {
                                rideService.pauseRide()
                                VoiceFeedbackService.shared.speak("Ride paused")
                            }) {
                                Image(systemName: "pause.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.orange)
                            }
                            
                            Button(action: {
                                rideService.endRide()
                                VoiceFeedbackService.shared.speak("Ride ended")
                                // Show summary after a brief delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    dismiss()
                                }
                            }) {
                                Image(systemName: "stop.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.red)
                            }
                        } else if rideService.rideState == .paused {
                            Button(action: {
                                rideService.resumeRide()
                                VoiceFeedbackService.shared.speak("Ride resumed")
                            }) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.green)
                            }
                            
                            Button(action: {
                                rideService.endRide()
                                VoiceFeedbackService.shared.speak("Ride ended")
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    dismiss()
                                }
                            }) {
                                Image(systemName: "stop.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
        }
        .onAppear {
            // Request location permission if needed
            if rideService.rideState == .idle {
                // Initialize map region with current location if available
                updateMapRegion()
            }
        }
        .onChange(of: rideService.totalDistance) { distance in
            // Announce milestones (every 0.5 miles)
            let miles = distance / 1609.34
            let milestone = Int(miles / 0.5)
            let lastMilestone = Int((distance - 100) / 1609.34 / 0.5)
            
            if milestone > lastMilestone && milestone > 0 {
                VoiceFeedbackService.shared.speak("You've ridden \(String(format: "%.1f", miles)) miles")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateMapRegion() {
        guard !rideService.route.isEmpty else { return }
        
        let lastCoordinate = rideService.route.last!
        region = MKCoordinateRegion(
            center: lastCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}

// MARK: - Ride Stat Card Component (Phase 31 - Local to RideTrackingView)

struct RideTrackingStatCard: View {
    let icon: String
    let value: String
    let label: String
    let unit: String?
    
    @ObservedObject private var theme = ThemeManager.shared
    
    init(icon: String, value: String, label: String, unit: String? = nil) {
        self.icon = icon
        self.value = value
        self.label = label
        self.unit = unit
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(theme.primaryText)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.headline.bold())
                    .foregroundColor(theme.primaryText)
                
                if let unit = unit {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(theme.primaryText.opacity(0.7))
                }
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(theme.primaryText.opacity(0.7))
        }
        .frame(width: 100)
    }
}

// MARK: - Preview

#Preview {
    RideTrackingView()
        .preferredColorScheme(.dark)
}

