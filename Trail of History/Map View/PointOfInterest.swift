//
//  PointOfInterest.swift
//  Trail of History
//
//  Created by Robert Vaessen on 8/30/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import UIKit
import MapKit


final class PointOfInterest: NSObject, MKAnnotation {

    // Sorted by longitude, westmost first
    static let pointsOfInterest: [PointOfInterest] = {
        var poiArray = [PointOfInterest]()

        for (title, data) in NSDictionary(contentsOfFile: NSBundle.mainBundle().pathForResource("PointsOfInterest", ofType: "plist")!)! {

            let location = CGPointFromString(data["location"] as! String)
            let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(location.x), longitude: CLLocationDegrees(location.y))
            
            poiArray.append(PointOfInterest(title: title as! String, coordinate: coordinate, information: data["description"] as! String))
        }
        
        return poiArray.sort { $0.coordinate.longitude < $1.coordinate.longitude }
    }()

    let information: String

    // MARK: - MKAnnotation implementation
    let title: String?
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D
    
    private init(title: String, coordinate: CLLocationCoordinate2D, information: String) {
        self.title = title
        self.subtitle = "lat \(coordinate.latitude), long \(coordinate.longitude)"
        self.coordinate = coordinate
        self.information = information
    }

    private(set) var distance: Double?
    
    func updateDistanceTo(userLocation location: CLLocationCoordinate2D) {
        // TODO:
    }
}
