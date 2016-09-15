//
//  Trail.swift
//  Trail of History
//
//  Created by Dagna Bieda & Robert Vaessen on 8/22/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import Foundation
import MapKit

// A singleton instance of the Trail class dispences all of the information provided by the Trail of History's various data files:
//
//      1)  Trail.instance.region - An MKCoordinateRegion that defines the geospatial boundary of the trail.
//          The region can be used to zoom a map to the trail's location. This information is obtained from
//          the Trail Bounds file.
//
//      2)  Trail.instance.route - An MKOverlay that can be added to a map to display the actual route of the trail.
//              a.  Trail.instance.route.renderer - An MKOverlayRenderer () that can be used by a map to draw the route.
//                  The renderer gets its image from the Trail Route file.
//
//      3)  Trail.instance.pointsOfInterest - A PointOfInterest array containing all of the trail's points of interest. The
//          information comes from the Points Of Interest file. The POIs are sorted by longitude, westmost first.
//          The POIs implement MKAnnotation and so can be added to a map.
//
// In addition the Trail is a CLLocationManagerDelegate. When the Trail is instantiated it creates a Location Manger
// and starts location updates. When the Trail receives those updates it uses them to update the distance between the
// user and each of the points of interest.

class Trail : NSObject {

    static let instance: Trail = Trail()

    let route: Route
    let region: MKCoordinateRegion
    let pointsOfInterest: [PointOfInterest] // Sorted by longitude, westmost first

    private let locationManager : CLLocationManager?

    // The bounds file is a dictionary of coordinates
    private let boundsFileName = "TrailBounds.plist"
    private enum Coordinates: String {
        case midCoord
        case topLeftCoord
        case topRightCoord
        case bottomLeftCoord
    }

    private override init() {
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
        route = Route(midCoordinate: midCoordinate, boundingMapRect: boundingRect)


        let latitudeDelta = fabs(topLeftCoordinate.latitude - bottomLeftCoordinate.latitude)
        let longitudeDelta = fabs(topLeftCoordinate.longitude - topRightCoordinate.longitude)
        let span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta)
        region = MKCoordinateRegionMake(midCoordinate, span)


        pointsOfInterest = PointOfInterest.getPointsOfInterest()

        locationManager = CLLocationManager.locationServicesEnabled() ? CLLocationManager() : nil

        super.init()

        if let manager = locationManager {
            //locationManager.desiredAccuracy = 1
            //locationManager.distanceFilter = 0.5
            manager.delegate = self
            manager.startUpdatingLocation()
        }
        else {
            alertUser("Location Services Needed", body: "Please enable location services so that Trail of History can show you where you are on the trail and what the distances to the points of interest are.")
        }
    }

    private func alertUser(title: String?, body: String?) {
        if let topController = UIApplication.topViewController() {
            let alert = UIAlertController(title: title, message: body, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default, handler: nil))
            topController.presentViewController(alert, animated: false, completion: nil)
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
        
        private init(midCoordinate: CLLocationCoordinate2D, boundingMapRect: MKMapRect) {
            self.coordinate = midCoordinate
            self.boundingMapRect = boundingMapRect
            super.init()
                
            renderer = Renderer(overlay: self)
        }
    }
}

extension Trail {
    class PointOfInterest: NSObject, MKAnnotation {
        
        private static func getPointsOfInterest() -> [PointOfInterest] {
            // The POI file is a dictionary of dictionaries. The keys of the outer dictionary
            // are the POI names. The inner dictionaries contain the POI's data.
            let poiFileName = "PointsOfInterest.plist"
            var pointsOfInterest = [PointOfInterest]()
            let poiFileNameComponents = poiFileName.componentsSeparatedByString(".")
            let poiFilePath = NSBundle.mainBundle().pathForResource(poiFileNameComponents[0], ofType: poiFileNameComponents[1])!
            for (name, data) in NSDictionary(contentsOfFile: poiFilePath)! {
                
                let location = CGPointFromString(data["location"] as! String)
                let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(location.x), longitude: CLLocationDegrees(location.y))
                
                let title = name as! String
                let description = data["description"] as! String
                let poi = PointOfInterest(title: title, coordinate: coordinate, narrative: description)
                pointsOfInterest.append(poi)
            }
            return pointsOfInterest.sort { $0.coordinate.longitude < $1.coordinate.longitude }
        }

        // MKAnnotation implementation
        let title: String?
        let subtitle: String?
        let coordinate: CLLocationCoordinate2D

        let narrative: String
        let location: CLLocation
        private(set) var distance: Double?
        
        private init(title: String, coordinate: CLLocationCoordinate2D, narrative: String) {
            self.title = title
            self.coordinate = coordinate
            self.narrative = narrative
            subtitle = "lat \(coordinate.latitude), long \(coordinate.longitude)"
            location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }
    }
}

extension Trail : CLLocationManagerDelegate {
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        switch status {
        case CLAuthorizationStatus.NotDetermined:
            manager.requestWhenInUseAuthorization();
            
        case CLAuthorizationStatus.AuthorizedWhenInUse:
            manager.startUpdatingLocation()
            
        default:
            alertUser("Location Access Not Authorized", body: "Trail of History will not be able show you the distance to the points of interest. You can change the authorization in Settings")
            break
        }
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let YardsPerMeter = 1.0936
        let userLocation = locations[locations.count - 1]
        for poi in pointsOfInterest {
            poi.distance = userLocation.distanceFromLocation(poi.location) * YardsPerMeter
        }
    }
}
