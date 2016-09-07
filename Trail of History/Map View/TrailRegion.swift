//
//  TrailRegion.swift
//  Trail of History
//
//  Created by Robert Vaessen on 8/22/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import Foundation
import MapKit

final class TrailRegion {
    
    static let instance: TrailRegion = TrailRegion()

    let region: MKCoordinateRegion

    private init() {
        let properties = NSDictionary(contentsOfFile: NSBundle.mainBundle().pathForResource("TrailBounds", ofType: "plist")!)!
       
        func makeCoordinate(name: String) -> CLLocationCoordinate2D {
            let point = CGPointFromString(properties[name] as! String)
            return CLLocationCoordinate2DMake(CLLocationDegrees(point.x), CLLocationDegrees(point.y))
        }

        let midCoordinate = makeCoordinate("midCoord")
        let topLeftCoordinate = makeCoordinate("topLeftCoord")
        let topRightCoordinate = makeCoordinate("topRightCoord")
        let bottomLeftCoordinate = makeCoordinate("bottomLeftCoord")
        
        let latitudeDelta = fabs(topLeftCoordinate.latitude - bottomLeftCoordinate.latitude)
        let longitudeDelta = fabs(topLeftCoordinate.longitude - topRightCoordinate.longitude)
        let span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta)
        region = MKCoordinateRegionMake(midCoordinate, span)
    }
}
