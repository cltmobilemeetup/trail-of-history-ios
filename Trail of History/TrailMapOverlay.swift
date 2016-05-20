//
//  TrailMapOverlay.swift
//  Trail of History
//
//  Created by Dagna Bieda on 5/20/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import UIKit
import MapKit

class TrailMapOverlay: NSObject, MKOverlay {
    var coordinate: CLLocationCoordinate2D
    var boundingMapRect: MKMapRect

    init(trail: Trail) {
        boundingMapRect = trail.overlayBoundingMapRect
        coordinate = trail.midCoordinate
    }
}
