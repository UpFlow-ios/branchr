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
    @Binding var selectedRider: UserAnnotation? // Phase 4: Selection support
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = showsUserLocation
        mapView.userTrackingMode = .none
        mapView.register(RiderAnnotationView.self, forAnnotationViewWithReuseIdentifier: RiderAnnotationView.reuseIdentifier)
        mapView.register(UserAnnotationView.self, forAnnotationViewWithReuseIdentifier: UserAnnotationView.reuseIdentifier)
        context.coordinator.parent = self
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
        
        // Phase 4: Update rider annotations with UserAnnotation support
        let existingRider = mapView.annotations.compactMap { $0 as? RiderPointAnnotation }
        let existingUser = mapView.annotations.compactMap { $0 as? UserAnnotation }
        mapView.removeAnnotations(existingRider + existingUser)
        
        var hostAnnotation: UserAnnotation? = nil
        riderAnnotations.forEach { rider in
            // Phase 4: Use UserAnnotation for Phase 4 features
            let annotation = UserAnnotation(
                coordinate: rider.coordinate,
                riderID: rider.id,
                name: rider.name,
                isHost: rider.isHost,
                profileImage: rider.profileImage
            )
            mapView.addAnnotation(annotation)
            if rider.isHost {
                hostAnnotation = annotation
            }
        }
        
        // Phase 5B: Log map updates with annotation info
        print("🗺️ Map updating with \(coordinates.count) coordinates, riders: \(riderAnnotations.count)")
        print("🗺 Added annotations – host: \(hostAnnotation != nil), riders: \(riderAnnotations.count)")
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: RideMapViewRepresentable
        
        init(parent: RideMapViewRepresentable) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                // Phase 35.7: Enhanced rainbow glow renderer with wider line
                let renderer = RainbowPolylineRenderer(polyline: polyline)
                renderer.lineWidth = 8  // Increased from 4 to 8
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Phase 4: Support UserAnnotation for host/rider markers
            if let userAnnotation = annotation as? UserAnnotation {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: UserAnnotationView.reuseIdentifier, for: userAnnotation) as! UserAnnotationView
                view.configure(with: userAnnotation)
                return view
            }
            
            // Fallback to existing RiderPointAnnotation for compatibility
            if let riderAnnotation = annotation as? RiderPointAnnotation {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: RiderAnnotationView.reuseIdentifier, for: riderAnnotation) as! RiderAnnotationView
                view.configure(with: riderAnnotation.rider)
                return view
            }
            
            return nil
        }
        
        // Phase 4: Handle annotation selection
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let userAnnotation = view.annotation as? UserAnnotation {
                parent.selectedRider = userAnnotation
            }
        }
        
        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            if view.annotation is UserAnnotation {
                parent.selectedRider = nil
            }
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
    let isHost: Bool // Phase 4: Host marker support
    let profileImage: UIImage? // Phase 4: Profile image support
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

// MARK: - Phase 4: UserAnnotationView for Host/Rider Markers

final class UserAnnotationView: MKAnnotationView {
    static let reuseIdentifier = "UserAnnotationView"
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        frame = CGRect(origin: .zero, size: CGSize(width: 44, height: 44))
        backgroundColor = .clear
        centerOffset = CGPoint(x: 0, y: -22)
        canShowCallout = false
    }
    
    func configure(with annotation: UserAnnotation) {
        let size: CGFloat = 44
        let imgView = UIImageView(frame: CGRect(x: 0, y: 0, width: size, height: size))
        imgView.layer.cornerRadius = size / 2
        imgView.clipsToBounds = true
        
        // Phase 4: Profile image or fallback color
        if let profile = annotation.profileImage {
            imgView.image = profile
        } else {
            // Host = yellow, Rider = red
            imgView.backgroundColor = annotation.isHost ? UIColor(Color.branchrAccent) : UIColor.red
        }
        
        // Phase 4: Green ring around marker
        imgView.layer.borderColor = UIColor.green.cgColor
        imgView.layer.borderWidth = 3
        
        // Drop shadow for definition
        imgView.layer.shadowColor = UIColor.black.cgColor
        imgView.layer.shadowOpacity = 0.3
        imgView.layer.shadowRadius = 4
        imgView.layer.shadowOffset = .zero
        
        // Remove old subviews
        subviews.forEach { $0.removeFromSuperview() }
        
        // Convert UIImageView to UIImage for annotation
        image = imgView.asImage()
    }
}

// MARK: - UIView Extension for Image Conversion

extension UIView {
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { _ in
            drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
    }
}

