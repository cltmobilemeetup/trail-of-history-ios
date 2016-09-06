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

    static let imageForCurrent = UIImage(named: "CurrentPoiAnnotation")
    static let imageForNotCurrent = UIImage(named: "PoiAnnotation")

    private static let YardsPerMeter = 1.0936

    // MARK: - MKAnnotation implementation
    let title: String?
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D
    
    let information: String
    var isCurrent: Bool = false
    let location: CLLocation
    private(set) var distance: Double?
    
    private init(title: String, coordinate: CLLocationCoordinate2D, information: String) {
        self.title = title
        self.coordinate = coordinate
        self.information = information
        subtitle = "lat \(coordinate.latitude), long \(coordinate.longitude)"
        location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    
    static func updateDistancesTo(userLocation location: CLLocation) {
        for poi in pointsOfInterest {
            poi.distance = location.distanceFromLocation(poi.location) * YardsPerMeter
        }
    }
}
