//
//  StatueAnnotation.swift
//  Trail of History
//
//  Created by Dagna Bieda on 5/20/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import UIKit
import MapKit

class StatueAnnotation: NSObject, MKAnnotation {

    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?

    init(coordinate: CLLocationCoordinate2D, title: String, description: String) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = description
    }
}
