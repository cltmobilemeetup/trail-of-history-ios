//
//  StatueAnnotation.swift
//  Trail of History
//
//  Created by Dagna Bieda on 5/20/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import UIKit
import MapKit

class PointOfInterest: NSObject, MKAnnotation {

    var title: String?
    var subtitle: String?
    var coordinate: CLLocationCoordinate2D

    init(coordinate: CLLocationCoordinate2D, title: String, description: String) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = description
    }

    private(set) static var pointsOfInterest: [PointOfInterest]? = {
        let poiFileName = "PointsOfInterest"
        guard let filePath = NSBundle.mainBundle().pathForResource(poiFileName, ofType: "plist"), poiDictionary = NSDictionary(contentsOfFile: filePath)
            else {
                print("Cannot create the points of interest from \(poiFileName)")
                return nil
        }
        
        var poiArray = [PointOfInterest]()

        for (title, data) in poiDictionary {

            let point = CGPointFromString(data["location"] as! String)
            let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(point.x), longitude: CLLocationDegrees(point.y))

            let description = data["description"] as! String

            poiArray.append(PointOfInterest(coordinate: coordinate, title: title as! String, description: description))
        }

        return poiArray
    }()
}
