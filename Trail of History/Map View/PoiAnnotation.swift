//
//  StatueAnnotation.swift
//  Trail of History
//
//  Created by Dagna Bieda on 5/20/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import UIKit
import MapKit

class PoiAnnotation: NSObject, MKAnnotation {

    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?

    init(coordinate: CLLocationCoordinate2D, title: String, description: String) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = description
    }

    static func makeAnnotations(fileName: String) -> [PoiAnnotation]? {
        guard let filePath = NSBundle.mainBundle().pathForResource(fileName, ofType: "plist"), pointsOfInterest = NSDictionary(contentsOfFile: filePath)
            else { return nil }
        
        var annotations = [PoiAnnotation]()

        for (title, data) in pointsOfInterest {
            let dictionary = data as! NSDictionary

            let point = CGPointFromString(dictionary["location"] as! String)
            let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(point.x), longitude: CLLocationDegrees(point.y))

            let description = dictionary["description"] as! String

            
            annotations.append(PoiAnnotation(coordinate: coordinate, title: title as! String, description: description))
        }

        return annotations
    }
}
