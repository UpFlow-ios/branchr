//
//  RideSummaryView.swift
//  branchr
//
//  Created by Joseph Dormond on 2025-11-03
//  Phase 20 - Ride Summary Screen
//

import SwiftUI
import MapKit
import FirebaseAuth

/**
 * 🚴‍♂️ Ride Summary View (Phase 20)
 *
 * Full-screen summary view displayed after a ride ends.
 * Shows: GPS route map, distance, duration, and average speed.
 * 
 * This is the Phase 20 version that uses RideTrackingService.
 * For legacy views using RideRecord, see the old RideSummaryView.
 */
struct Phase20RideSummaryView: View {
    
    @ObservedObject var rideService: RideTrackingService
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var theme = ThemeManager.shared
    
    // Map region
    @State private var region: MKCoordinateRegion
    
    init(rideService: RideTrackingService) {
        self.rideService = rideService
        
        // Calculate initial map region from route
        if let firstCoordinate = rideService.route.first {
            let center = CLLocationCoordinate2D(
                latitude: firstCoordinate.latitude,
                longitude: firstCoordinate.longitude
            )
            _region = State(initialValue: MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
            ))
        } else {
            // Default region (San Francisco)
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Ride Summary")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(theme.primaryText)
                        
                        Text("Great ride!")
                            .font(.subheadline)
                            .foregroundColor(theme.primaryText.opacity(0.7))
                    }
                    .padding(.top, 20)
                    
                    // Map View
                    if !rideService.route.isEmpty {
                        Map(coordinateRegion: $region, showsUserLocation: false, annotationItems: routeAnnotations) { location in
                            MapPin(coordinate: location.coordinate, tint: theme.accentColor)
                        }
                        .frame(height: 300)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(theme.accentColor.opacity(0.3), lineWidth: 2)
                        )
                        .padding(.horizontal, 20)
                        .onAppear {
                            updateMapRegion()
                        }
                    } else {
                        // No route available
                        RoundedRectangle(cornerRadius: 16)
                            .fill(theme.cardBackground)
                            .frame(height: 300)
                            .overlay(
                                VStack {
                                    Image(systemName: "map")
                                        .font(.system(size: 48))
                                        .foregroundColor(theme.primaryText.opacity(0.5))
                                    Text("No route data")
                                        .font(.subheadline)
                                        .foregroundColor(theme.primaryText.opacity(0.5))
                                }
                            )
                            .padding(.horizontal, 20)
                    }
                    
                    // Statistics Cards
                    VStack(spacing: 16) {
                        RideStatCard(
                            title: "Distance",
                            value: rideService.formattedDistance,
                            icon: "location.fill",
                            color: theme.accentColor
                        )
                        
                        RideStatCard(
                            title: "Duration",
                            value: rideService.formatTime(rideService.duration),
                            icon: "clock.fill",
                            color: theme.accentColor
                        )
                        
                        RideStatCard(
                            title: "Average Speed",
                            value: rideService.formattedAverageSpeed,
                            icon: "speedometer",
                            color: theme.accentColor
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Phase 34: Auto-save ride on appear (save is ON by default)
                    // Save ride automatically when summary appears
                    .onAppear {
                        // Create RideRecord from service data
                        let avgSpeed = rideService.totalDistance > 0 && rideService.duration > 0
                            ? rideService.totalDistance / rideService.duration // m/s
                            : 0
                        
                        let rideRecord = RideRecord(
                            distance: rideService.totalDistance,
                            duration: rideService.duration,
                            averageSpeed: avgSpeed,
                            calories: 0, // Calculate if needed
                            route: rideService.route
                        )
                        
                        // Save locally
                        RideDataManager.shared.saveRide(rideRecord)
                        
                        // Upload to Firebase
                        FirebaseRideService.shared.uploadRide(rideRecord) { error in
                            if let error = error {
                                print("❌ Failed to upload ride: \(error.localizedDescription)")
                            } else {
                                print("☁️ Ride synced to Firebase successfully")
                            }
                        }
                        
                        // Haptic feedback on save
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }
                    
                    // Phase 34E: Save Ride Button (theme-aware for light/dark mode)
                    Button(action: {
                        rideService.resetRide()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Ride")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(theme.isDarkMode ? .black : theme.accentColor) // Phase 34E: Yellow text in light mode, black in dark
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(theme.isDarkMode ? theme.accentColor : Color.black) // Phase 34E: Black bg in light mode, yellow in dark
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Phase 34E: Done Button (theme-aware)
                    Button(action: {
                        rideService.resetRide()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Done")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(theme.isDarkMode ? .black : theme.accentColor) // Phase 34E: Yellow text in light mode, black in dark
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(theme.isDarkMode ? theme.accentColor : Color.black) // Phase 34E: Black bg in light mode, yellow in dark
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.primaryBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Computed Properties
    
    private var routeAnnotations: [RouteLocation] {
        rideService.route.map { RouteLocation(coordinate: $0) }
    }
    
    private var avgSpeed: Double {
        guard rideService.duration > 0 else { return 0 }
        return (rideService.totalDistance / rideService.duration) * 3.6 // m/s → km/h
    }
    
    // MARK: - Methods
    
    private func updateMapRegion() {
        guard !rideService.route.isEmpty else { return }
        
        // Calculate bounds of route
        let latitudes = rideService.route.map { $0.latitude }
        let longitudes = rideService.route.map { $0.longitude }
        
        guard let minLat = latitudes.min(),
              let maxLat = latitudes.max(),
              let minLon = longitudes.min(),
              let maxLon = longitudes.max() else { return }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.3, 0.01),
            longitudeDelta: max((maxLon - minLon) * 1.3, 0.01)
        )
        
        region = MKCoordinateRegion(center: center, span: span)
    }
}

// MARK: - Stat Card Component

struct RideStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.15))
                .cornerRadius(12)
            
            // Stats
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(theme.primaryText.opacity(0.7))
                
                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(theme.primaryText)
            }
            
            Spacer()
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(16)
        .shadow(color: theme.accentColor.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Route Location Model

struct RouteLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Preview

#Preview {
    let service = RideTrackingService()
    service.rideState = .ended
    service.totalDistance = 5000 // 5 km
    service.duration = 1800 // 30 minutes
    service.route = [
        CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
        CLLocationCoordinate2D(latitude: 37.3350, longitude: -122.0091),
        CLLocationCoordinate2D(latitude: 37.3351, longitude: -122.0092)
    ]
    
    return Phase20RideSummaryView(rideService: service)
        .preferredColorScheme(.dark)
}

