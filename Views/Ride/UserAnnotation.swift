//
//  UserAnnotation.swift
//  branchr
//
//  Created for Phase 4 - Host + Rider Map Markers
//

import MapKit
import UIKit

/// Custom annotation for host and rider markers on the map
class UserAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let riderID: String
    let isHost: Bool
    let name: String
    let profileImage: UIImage?
    var title: String? { name }
    
    init(
        coordinate: CLLocationCoordinate2D,
        riderID: String,
        name: String,
        isHost: Bool,
        profileImage: UIImage?
    ) {
        self.coordinate = coordinate
        self.riderID = riderID
        self.name = name
        self.isHost = isHost
        self.profileImage = profileImage
        super.init()
    }
}

