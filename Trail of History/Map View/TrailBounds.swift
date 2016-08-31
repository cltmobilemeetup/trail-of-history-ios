//
//  Trail.swift
//  Trail of History
//
//  Created by Dagna Bieda on 5/19/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import Foundation
import MapKit

class TrailBounds {
    private let properties: NSDictionary

    private lazy var boundary: [CLLocationCoordinate2D] = {
        var boundary = [CLLocationCoordinate2D]()
        let textPoints = self.properties["boundary"] as! [String]
        for textPoint in textPoints {
            let point = CGPointFromString(textPoint)
            boundary += [CLLocationCoordinate2DMake(CLLocationDegrees(point.x), CLLocationDegrees(point.y))]
        }
        return boundary
    }()

    private lazy var midCoordinate: CLLocationCoordinate2D = { return self.makeCoordinate("midCoord") }()
    private lazy var topLeftCoordinate: CLLocationCoordinate2D = { return self.makeCoordinate("topLeftCoord") }()
    private lazy var topRightCoordinate: CLLocationCoordinate2D = { return self.makeCoordinate("topRightCoord") }()
    private lazy var bottomLeftCoordinate: CLLocationCoordinate2D = { return self.makeCoordinate("bottomLeftCoord") }()
    private lazy var bottomRightCoordinate: CLLocationCoordinate2D = { return CLLocationCoordinate2DMake(self.bottomLeftCoordinate.latitude, self.topRightCoordinate.longitude) }()

    init?(filename: String) {
        guard let filePath = NSBundle.mainBundle().pathForResource(filename, ofType: "plist"),
            properties = NSDictionary(contentsOfFile: filePath)
            else { return nil }
        
        self.properties = properties
    }
    
    var rect: MKMapRect {
        get {
            let topLeft = MKMapPointForCoordinate(topLeftCoordinate);
            let topRight = MKMapPointForCoordinate(topRightCoordinate);
            let bottomLeft = MKMapPointForCoordinate(bottomLeftCoordinate);
            return MKMapRectMake(topLeft.x, topLeft.y, fabs(topLeft.x-topRight.x), fabs(topLeft.y - bottomLeft.y))
        }
    }
    
    var region: MKCoordinateRegion {
        get {
            let latitudeDelta = fabs(topLeftCoordinate.latitude - bottomRightCoordinate.latitude)
            let longitudeDelta = fabs(topLeftCoordinate.longitude - bottomRightCoordinate.longitude)
            let span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta)
            return MKCoordinateRegionMake(midCoordinate, span)
        }
    }
    
    private func makeCoordinate(name: String) -> CLLocationCoordinate2D {
        let point = CGPointFromString(properties[name] as! String)
        return CLLocationCoordinate2DMake(CLLocationDegrees(point.x), CLLocationDegrees(point.y))
    }
}
