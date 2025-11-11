//
//  RideSummaryMapSection.swift
//  branchr
//
//  Created for Phase 35C - Mini Map in Ride Summary
//

import SwiftUI
import MapKit

struct RideSummaryMapSection: View {
    let locations: [CLLocationCoordinate2D]
    @State private var region: MKCoordinateRegion

    init(locations: [CLLocationCoordinate2D]) {
        self.locations = locations
        
        // Calculate initial region from locations
        if let first = locations.first {
            let center = first
            _region = State(initialValue: MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        } else {
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }

    var body: some View {
        ZStack {
            RideMapViewRepresentable(
                region: $region,
                coordinates: locations,
                showsUserLocation: false,
                riderAnnotations: []
            )
            .allowsHitTesting(false)

            // Optional gradient overlay for better readability
            LinearGradient(
                colors: [.black.opacity(0.25), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .allowsHitTesting(false)
        }
        .onAppear {
            updateRegion()
        }
    }
    
    private func updateRegion() {
        guard !locations.isEmpty else { return }
        
        let latitudes = locations.map { $0.latitude }
        let longitudes = locations.map { $0.longitude }
        
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

