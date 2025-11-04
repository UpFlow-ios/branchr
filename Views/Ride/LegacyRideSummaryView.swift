//
//  LegacyRideSummaryView.swift
//  branchr
//
//  Created by Joseph Dormond on 2025-11-03
//  Legacy Ride Summary View for RideRecord compatibility
//

import SwiftUI
import MapKit

/**
 * Legacy Ride Summary View
 *
 * Summary view for saved rides using RideRecord.
 * Compatible with RideHistoryView and RideMapView.
 */
struct RideSummaryView: View {
    let ride: RideRecord
    let rideDataManager: RideDataManager
    let onDismiss: () -> Void
    
    @ObservedObject private var theme = ThemeManager.shared
    @State private var region: MKCoordinateRegion
    
    init(ride: RideRecord, rideDataManager: RideDataManager, onDismiss: @escaping () -> Void) {
        self.ride = ride
        self.rideDataManager = rideDataManager
        self.onDismiss = onDismiss
        
        // Calculate map region from route
        if let firstCoordinate = ride.coordinateRoute.first {
            let center = CLLocationCoordinate2D(
                latitude: firstCoordinate.latitude,
                longitude: firstCoordinate.longitude
            )
            _region = State(initialValue: MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
            ))
        } else {
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
                        
                        Text(ride.formattedDate)
                            .font(.subheadline)
                            .foregroundColor(theme.primaryText.opacity(0.7))
                    }
                    .padding(.top, 20)
                    
                    // Map View
                    if !ride.coordinateRoute.isEmpty {
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
                    }
                    
                    // Statistics Cards
                    VStack(spacing: 16) {
                        LegacyStatCard(
                            title: "Distance",
                            value: ride.formattedDistance,
                            icon: "location.fill",
                            color: theme.accentColor
                        )
                        
                        LegacyStatCard(
                            title: "Duration",
                            value: ride.formattedDuration,
                            icon: "clock.fill",
                            color: theme.accentColor
                        )
                        
                        LegacyStatCard(
                            title: "Average Speed",
                            value: ride.formattedAverageSpeed,
                            icon: "speedometer",
                            color: theme.accentColor
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Done Button
                    BranchrButton(title: "Done", icon: "checkmark.circle.fill") {
                        onDismiss()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.primaryBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
    
    private var routeAnnotations: [RouteLocation] {
        ride.coordinateRoute.map { RouteLocation(coordinate: $0) }
    }
    
    private func updateMapRegion() {
        guard !ride.coordinateRoute.isEmpty else { return }
        
        let latitudes = ride.coordinateRoute.map { $0.latitude }
        let longitudes = ride.coordinateRoute.map { $0.longitude }
        
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

// MARK: - Legacy Stat Card

struct LegacyStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.15))
                .cornerRadius(12)
            
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

