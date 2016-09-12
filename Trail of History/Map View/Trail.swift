//
//  Trail.swift
//  Trail of History
//
//  Created by Dagna Bieda & Robert Vaessen on 8/22/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import Foundation
import MapKit

// A singleton instance of the Trail class provides all of the Trail of History's information:
//
//      1)  An MKCoordinateRegion (Trail.instance.region) that defines the geospatial boundary of the trail.
//          The region can be used to zoom a map to the trail's location. The information is obtained from
//          the Trail Bounds file.
//
//      2)  An MKOverlay (Trail.instance.route) that can be added to a map to display the actual route of the trail.
//              a.  The MkOverlay provides an MKOverlayRenderer (Trail.instance.route.renderer)
//                  that can be used by a map to draw the route. The renderer gets its image from the Trail Route file.
//
//      3)  A PointOfInterest array (Trail.instance.pointsOfInterest) containing all of the point of interest. The
//          information comes from the Points Of Interest file. The POIs are sorted by longitude, westmost first.
//          The POIs implement MKAnnotation and so can be added to a map.

class Trail {

    static let instance: Trail = Trail()

    let route: Route
    let region: MKCoordinateRegion
    let pointsOfInterest: [PointOfInterest] // Sorted by longitude, westmost first

    private let YardsPerMeter = 1.0936

    // The bounds file is a dictionary of coordinates
    private let boundsFileName = "TrailBounds.plist"
    private enum Coordinates: String {
        case midCoord
        case topLeftCoord
        case topRightCoord
        case bottomLeftCoord
    }

    private init() {
        let boundsFileNameComponents = boundsFileName.componentsSeparatedByString(".")
        let boundsFilePath = NSBundle.mainBundle().pathForResource(boundsFileNameComponents[0], ofType: boundsFileNameComponents[1])!
        let properties = NSDictionary(contentsOfFile: boundsFilePath)!
       
        func makeCoordinate(name: String) -> CLLocationCoordinate2D {
            let point = CGPointFromString(properties[name] as! String)
            return CLLocationCoordinate2DMake(CLLocationDegrees(point.x), CLLocationDegrees(point.y))
        }

        let midCoordinate = makeCoordinate(Coordinates.midCoord.rawValue)
        let topLeftCoordinate = makeCoordinate(Coordinates.topLeftCoord.rawValue)
        let topRightCoordinate = makeCoordinate(Coordinates.topRightCoord.rawValue)
        let bottomLeftCoordinate = makeCoordinate(Coordinates.bottomLeftCoord.rawValue)


        let topLeftPoint = MKMapPointForCoordinate(topLeftCoordinate);
        let topRightPoint = MKMapPointForCoordinate(topRightCoordinate);
        let bottomLeftPoint = MKMapPointForCoordinate(bottomLeftCoordinate);
        let boundingRect = MKMapRectMake(topLeftPoint.x, topLeftPoint.y, fabs(topLeftPoint.x - topRightPoint.x), fabs(topLeftPoint.y - bottomLeftPoint.y))
        route = Route(coordinate: midCoordinate, boundingMapRect: boundingRect)


        let latitudeDelta = fabs(topLeftCoordinate.latitude - bottomLeftCoordinate.latitude)
        let longitudeDelta = fabs(topLeftCoordinate.longitude - topRightCoordinate.longitude)
        let span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta)
        region = MKCoordinateRegionMake(midCoordinate, span)

        pointsOfInterest = PointOfInterest.getPointsOfInterest()
    }

    func updateDistancesTo(userLocation location: CLLocation) {
        for poi in pointsOfInterest {
            poi.distance = location.distanceFromLocation(poi.location) * YardsPerMeter
        }
    }
}

extension Trail {
    class Route: NSObject, MKOverlay {
        
        class Renderer : MKOverlayRenderer {
            private static let routeImageFileName = "TrailRoute"
            private let pathImage = UIImage(named: routeImageFileName)
            
            override func drawMapRect(mapRect: MKMapRect, zoomScale: MKZoomScale, inContext context: CGContext) {
                
                let rendererRect = rectForMapRect(overlay.boundingMapRect)
                
                CGContextScaleCTM(context, 1.0, -1.0)
                CGContextTranslateCTM(context, 0.0, -rendererRect.size.height)
                CGContextDrawImage(context, rendererRect, pathImage?.CGImage)
            }
        }

        
        // MKOverlay implementation
        private(set) var coordinate: CLLocationCoordinate2D
        private(set) var boundingMapRect: MKMapRect

        
        private(set) var renderer: Renderer!
        
        init(coordinate: CLLocationCoordinate2D, boundingMapRect: MKMapRect) {
            self.coordinate = coordinate
            self.boundingMapRect = boundingMapRect
            super.init()
                
            renderer = Renderer(overlay: self)
        }
    }
}

extension Trail {
    class PointOfInterest: NSObject, MKAnnotation {

        static let imageForCurrent = UIImage(named: "CurrentPoiAnnotation")
        static let imageForNotCurrent = UIImage(named: "PoiAnnotation")
        
        // The POI file is a dictionary of dictionaries. The keys of the outer dictionary
        // are the POI names. The inner dictionary contains the POI's data.
        private static let poiFileName = "PointsOfInterest.plist"

        private static func getPointsOfInterest() -> [PointOfInterest] {
            var pointsOfInterest = [PointOfInterest]()
            let poiFileNameComponents = poiFileName.componentsSeparatedByString(".")
            let poiFilePath = NSBundle.mainBundle().pathForResource(poiFileNameComponents[0], ofType: poiFileNameComponents[1])!
            for (name, data) in NSDictionary(contentsOfFile: poiFilePath)! {
                
                let location = CGPointFromString(data["location"] as! String)
                let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(location.x), longitude: CLLocationDegrees(location.y))
                
                let title = name as! String
                let information = data["description"] as! String
                let poi = PointOfInterest(title: title, coordinate: coordinate, information: information)
                pointsOfInterest.append(poi)
            }
            return pointsOfInterest.sort { $0.coordinate.longitude < $1.coordinate.longitude }
        }


        // MKAnnotation implementation
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
    }
}
