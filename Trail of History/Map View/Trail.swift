//
//  Trail.swift
//  Trail of History
//
//  Created by Robert Vaessen on 8/22/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import Foundation
import MapKit

final class Trail: MKOverlayRenderer {
    
    class Overlay: NSObject, MKOverlay {
        var coordinate: CLLocationCoordinate2D
        var boundingMapRect: MKMapRect

        init(coordinate: CLLocationCoordinate2D, boundingMapRect: MKMapRect) {
            self.coordinate = coordinate
            self.boundingMapRect = boundingMapRect
            super.init()
        }
    }

    static let instance: Trail = Trail()

    let path: Overlay
    let region: MKCoordinateRegion

    private let pathImage = UIImage(named: "TrailPath")
    private let boundsFile = NSBundle.mainBundle().pathForResource("TrailBounds", ofType: "plist")!

    private init() {
        let properties = NSDictionary(contentsOfFile: boundsFile)!
       
        func makeCoordinate(name: String) -> CLLocationCoordinate2D {
            let point = CGPointFromString(properties[name] as! String)
            return CLLocationCoordinate2DMake(CLLocationDegrees(point.x), CLLocationDegrees(point.y))
        }

        let midCoordinate = makeCoordinate("midCoord")
        let topLeftCoordinate = makeCoordinate("topLeftCoord")
        let topRightCoordinate = makeCoordinate("topRightCoord")
        let bottomLeftCoordinate = makeCoordinate("bottomLeftCoord")

        let topLeftPoint = MKMapPointForCoordinate(topLeftCoordinate);
        let topRightPoint = MKMapPointForCoordinate(topRightCoordinate);
        let bottomLeftPoint = MKMapPointForCoordinate(bottomLeftCoordinate);
        let boundingRect = MKMapRectMake(topLeftPoint.x, topLeftPoint.y, fabs(topLeftPoint.x - topRightPoint.x), fabs(topLeftPoint.y - bottomLeftPoint.y))
        path = Overlay(coordinate: midCoordinate, boundingMapRect: boundingRect)

        let latitudeDelta = fabs(topLeftCoordinate.latitude - bottomLeftCoordinate.latitude)
        let longitudeDelta = fabs(topLeftCoordinate.longitude - topRightCoordinate.longitude)
        let span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta)
        region = MKCoordinateRegionMake(midCoordinate, span)

        super.init(overlay: path)
    }

    override func drawMapRect(mapRect: MKMapRect, zoomScale: MKZoomScale, inContext context: CGContext) {
       
        let rendererRect = rectForMapRect(mapRect)
        
        CGContextScaleCTM(context, 1.0, -1.0)
        CGContextTranslateCTM(context, 0.0, -rendererRect.size.height)
        CGContextDrawImage(context, rendererRect, pathImage?.CGImage)
    }
}
