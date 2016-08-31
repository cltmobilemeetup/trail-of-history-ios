//
//  Trail.swift
//  Trail of History
//
//  Created by Dagna Bieda on 5/19/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import Foundation
import MapKit

final class TrailBounds {
    
    static let instance: TrailBounds? = TrailBounds()

    private let trailBoundsFileName = "TrailBounds"

    private let midCoordinate: CLLocationCoordinate2D
    private let topLeftCoordinate: CLLocationCoordinate2D
    private let topRightCoordinate: CLLocationCoordinate2D
    private let bottomLeftCoordinate: CLLocationCoordinate2D
    private let bottomRightCoordinate: CLLocationCoordinate2D

    private init?() {
        guard let filePath = NSBundle.mainBundle().pathForResource(trailBoundsFileName, ofType: "plist"), properties = NSDictionary(contentsOfFile: filePath)
            else {
                print("Cannot create the trail bounds from \(trailBoundsFileName)")
                return nil
        }
        
        func makeCoordinate(name: String) -> CLLocationCoordinate2D {
            let point = CGPointFromString(properties[name] as! String)
            return CLLocationCoordinate2DMake(CLLocationDegrees(point.x), CLLocationDegrees(point.y))
        }

        midCoordinate = makeCoordinate("midCoord")
        topLeftCoordinate = makeCoordinate("topLeftCoord")
        topRightCoordinate = makeCoordinate("topRightCoord")
        bottomLeftCoordinate = makeCoordinate("bottomLeftCoord")
        bottomRightCoordinate = CLLocationCoordinate2DMake(bottomLeftCoordinate.latitude, topRightCoordinate.longitude)
    }
    
    private(set) lazy var rect: MKMapRect = {
        let topLeft = MKMapPointForCoordinate(self.topLeftCoordinate);
        let topRight = MKMapPointForCoordinate(self.topRightCoordinate);
        let bottomLeft = MKMapPointForCoordinate(self.bottomLeftCoordinate);
        return MKMapRectMake(topLeft.x, topLeft.y, fabs(topLeft.x-topRight.x), fabs(topLeft.y - bottomLeft.y))
    }()
    
    private(set) lazy var region: MKCoordinateRegion = {
        let latitudeDelta = fabs(self.topLeftCoordinate.latitude - self.bottomRightCoordinate.latitude)
        let longitudeDelta = fabs(self.topLeftCoordinate.longitude - self.bottomRightCoordinate.longitude)
        let span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta)
        return MKCoordinateRegionMake(self.midCoordinate, span)
    }()
}
