//
//  RideDetailView.swift
//  branchr
//
//  Created for Phase 37 - Calendar Ride Detail Route Preview & Theme Polish
//

import SwiftUI
import MapKit
import CoreLocation

/**
 * 📆 Ride Detail View
 *
 * Shows a saved ride's route on a map with final metrics.
 * Used when tapping a ride from the Branchr calendar.
 */
struct RideDetailView: View {
    let ride: RideRecord
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var region: MKCoordinateRegion
    
    init(ride: RideRecord) {
        self.ride = ride
        
        // Phase 37: Calculate map region from route coordinates
        let coordinates = ride.coordinateRoute
        if !coordinates.isEmpty {
            let latitudes = coordinates.map { $0.latitude }
            let longitudes = coordinates.map { $0.longitude }
            
            let minLat = latitudes.min() ?? 0
            let maxLat = latitudes.max() ?? 0
            let minLon = longitudes.min() ?? 0
            let maxLon = longitudes.max() ?? 0
            
            let center = CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            )
            
            let latDelta = max((maxLat - minLat) * 1.3, 0.01)
            let lonDelta = max((maxLon - minLon) * 1.3, 0.01)
            
            _region = State(initialValue: MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
            ))
        } else {
            // Default region if no coordinates
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }
    
    // Computed properties for metrics
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
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: ride.date)
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // 1. Route Map
                    if !ride.coordinateRoute.isEmpty {
                        RideMapViewRepresentable(
                            region: $region,
                            coordinates: ride.coordinateRoute,
                            showsUserLocation: false,
                            riderAnnotations: [],
                            selectedRider: .constant(nil)
                        )
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal, 16)
                        .onAppear {
                            print("📆 RideDetailView: showing route with \(ride.coordinateRoute.count) points")
                        }
                    } else {
                        // Placeholder if no route
                        VStack(spacing: 12) {
                            Image(systemName: "map")
                                .font(.system(size: 48))
                                .foregroundColor(theme.secondaryText)
                            Text("No route data available")
                                .font(.subheadline)
                                .foregroundColor(theme.secondaryText)
                        }
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 16)
                    }
                    
                    // 2. Metrics Summary Cards
                    HStack(spacing: 16) {
                        MetricCard(
                            icon: "location.fill",
                            value: String(format: "%.2f", distanceMiles),
                            unit: "mi",
                            label: "Distance"
                        )
                        
                        MetricCard(
                            icon: "clock.fill",
                            value: durationText,
                            unit: nil,
                            label: "Duration"
                        )
                        
                        MetricCard(
                            icon: "speedometer",
                            value: String(format: "%.1f", averageSpeedMph),
                            unit: "mph",
                            label: "Avg Speed"
                        )
                    }
                    .padding(.horizontal, 16)
                    
                    // 3. Ride Metadata
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ride Details")
                            .font(.headline)
                            .foregroundColor(theme.primaryText)
                            .padding(.horizontal, 16)
                        
                        VStack(spacing: 8) {
                            DetailRow(label: "Date", value: formattedDate)
                            DetailRow(label: "Route Points", value: "\(ride.route.count)")
                            if let title = ride.title, !title.isEmpty {
                                DetailRow(label: "Title", value: title)
                            }
                        }
                        .padding()
                        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 16)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.top, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.primaryBackground.ignoresSafeArea())
            .navigationTitle("Ride Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Phase 46C: Clear exit control in leading position with haptic feedback
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        HapticsService.shared.mediumTap()
                        dismiss()
                    }
                    .foregroundColor(theme.brandYellow)
                    .font(.headline)
                }
            }
        }
    }
}

// MARK: - Metric Card Component

struct MetricCard: View {
    let icon: String
    let value: String
    let unit: String?
    let label: String
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(theme.accentColor)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(theme.primaryText)
                
                if let unit = unit {
                    Text(unit)
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryText)
                }
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Detail Row Component

struct DetailRow: View {
    let label: String
    let value: String
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(theme.secondaryText)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(theme.primaryText)
        }
    }
}


