//
//  RideMapViewRepresentable.swift
//  branchr
//
//  Created for Phase 34 - Clean Black Polyline
//

import SwiftUI
import MapKit
import CoreLocation

/// Map view with custom black polyline renderer
struct RideMapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let coordinates: [CLLocationCoordinate2D]
    let showsUserLocation: Bool
    let riderAnnotations: [RiderAnnotation]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = showsUserLocation
        mapView.userTrackingMode = .none
        mapView.register(RiderAnnotationView.self, forAnnotationViewWithReuseIdentifier: RiderAnnotationView.reuseIdentifier)
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(region, animated: true)
        
        // Remove old overlays
        mapView.removeOverlays(mapView.overlays)
        
        // Add new polyline if we have coordinates
        if coordinates.count > 1 {
            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
            mapView.addOverlay(polyline)
        }
        
        // Update rider annotations
        let existing = mapView.annotations.compactMap { $0 as? RiderPointAnnotation }
        mapView.removeAnnotations(existing)
        
        riderAnnotations.forEach { rider in
            let annotation = RiderPointAnnotation(rider: rider)
            mapView.addAnnotation(annotation)
        }
        
        // Phase 35.5: Log map updates to verify continuous tracking
        print("🗺️ Map updating with \(coordinates.count) coordinates, riders: \(riderAnnotations.count)")
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                // Phase 35.3: Use rainbow glow renderer
                let renderer = RainbowPolylineRenderer(polyline: polyline)
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let riderAnnotation = annotation as? RiderPointAnnotation else {
                return nil
            }
            
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: RiderAnnotationView.reuseIdentifier, for: riderAnnotation) as! RiderAnnotationView
            view.configure(with: riderAnnotation.rider)
            return view
        }
    }
}

// MARK: - Rider Annotation Models

struct RiderAnnotation: Identifiable {
    let id: String
    let name: String
    let photoURL: String?
    let coordinate: CLLocationCoordinate2D
    let isOnline: Bool
}

final class RiderPointAnnotation: NSObject, MKAnnotation {
    let rider: RiderAnnotation
    dynamic var coordinate: CLLocationCoordinate2D
    var title: String? { rider.name }
    
    init(rider: RiderAnnotation) {
        self.rider = rider
        self.coordinate = rider.coordinate
        super.init()
    }
}

final class RiderAnnotationView: MKAnnotationView {
    static let reuseIdentifier = "RiderAnnotationView"
    private var hostController: UIHostingController<MapRiderAnnotationView>?
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        frame = CGRect(origin: .zero, size: CGSize(width: 48, height: 48))
        backgroundColor = .clear
        centerOffset = CGPoint(x: 0, y: -24)
    }
    
    func configure(with rider: RiderAnnotation) {
        let view = MapRiderAnnotationView(name: rider.name, photoURL: rider.photoURL, isOnline: rider.isOnline)
        if hostController == nil {
            let controller = UIHostingController(rootView: view)
            controller.view.backgroundColor = .clear
            controller.view.frame = bounds
            addSubview(controller.view)
            hostController = controller
        } else {
            hostController?.rootView = view
            hostController?.view.frame = bounds
        }
    }
}

