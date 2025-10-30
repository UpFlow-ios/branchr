//
//  MapComponents.swift
//  branchr
//
//  Created by Joe Dormond on 10/23/25.
//

import SwiftUI
import MapKit
import CoreLocation

// MARK: - MapAnnotation
struct MapAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// MARK: - MapPolylineOverlay
struct MapPolylineOverlay: View {
    let coordinates: [CLLocationCoordinate2D]
    
    var body: some View {
        if coordinates.count > 1 {
            MapPolyline(coordinates: coordinates)
                .stroke(Color.blue, lineWidth: 4)
        }
    }
}

// MARK: - MapPolyline
struct MapPolyline: Shape {
    let coordinates: [CLLocationCoordinate2D]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        guard !coordinates.isEmpty else { return path }
        
        // Convert coordinates to points within the rect
        let points = coordinates.map { coordinate in
            CGPoint(
                x: rect.minX + (coordinate.longitude + 180) / 360 * rect.width,
                y: rect.minY + (90 - coordinate.latitude) / 180 * rect.height
            )
        }
        
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        
        return path
    }
}
