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
// and starts location updates. As the Trail receives the updates it uses them to update the distance from the user
// to each of the points of interest.

class Trail : NSObject {

    static let instance: Trail = Trail()

    let route: Route // Usage: MapView.addOverlay(Trail.instance.route)
    let region: MKCoordinateRegion // Usage: MapView.region = Trail.instance.region
    let pointsOfInterest: [PointOfInterest] // Usage: MapView.addAnnotations(Trail.instance.pointsOfInterest). Sorted by longitude, westmost first.

    fileprivate let locationManager : CLLocationManager?

    // The bounds file is a dictionary of coordinates
    fileprivate let boundsFileName = "TrailBounds.plist"
    fileprivate enum Coordinates: String {
        case midCoord
        case topLeftCoord
        case topRightCoord
        case bottomLeftCoord
    }

    fileprivate override init() {
        let boundsFileNameComponents = boundsFileName.components(separatedBy: ".")
        let boundsFilePath = Bundle.main.path(forResource: boundsFileNameComponents[0], ofType: boundsFileNameComponents[1])!
        let properties = NSDictionary(contentsOfFile: boundsFilePath)!
       
        func makeCoordinate(_ name: String) -> CLLocationCoordinate2D {
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

    fileprivate func alertUser(_ title: String?, body: String?) {
        if let topController = UIApplication.topViewController() {
            let alert = UIAlertController(title: title, message: body, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: nil))
            topController.present(alert, animated: false, completion: nil)
        }
    }
}

extension Trail {
    class Route: NSObject, MKOverlay {
        
        class Renderer : MKOverlayRenderer {
            fileprivate static let routeImageFileName = "TrailRoute"
            fileprivate let pathImage = UIImage(named: routeImageFileName)
            
            override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
                
                let rendererRect = rect(for: overlay.boundingMapRect)
                
                context.scaleBy(x: 1.0, y: -1.0)
                context.translateBy(x: 0.0, y: -rendererRect.size.height)
                context.draw((pathImage?.cgImage)!, in: rendererRect)
            }
        }
        
        // MKOverlay implementation
        fileprivate(set) var coordinate: CLLocationCoordinate2D
        fileprivate(set) var boundingMapRect: MKMapRect

        fileprivate(set) var renderer: Renderer!
        
        fileprivate init(midCoordinate: CLLocationCoordinate2D, boundingMapRect: MKMapRect) {
            self.coordinate = midCoordinate
            self.boundingMapRect = boundingMapRect
            super.init()
                
            renderer = Renderer(overlay: self)
        }
    }
}

extension Trail {
    class PointOfInterest: NSObject, MKAnnotation {
        
        fileprivate static func getPointsOfInterest() -> [PointOfInterest] {
            // The POI file is a dictionary of dictionaries. The keys of the outer dictionary
            // are the POI names. The inner dictionaries contain the POI's data.
            let poiFileName = "PointsOfInterest.plist"
            var pointsOfInterest = [PointOfInterest]()
            let poiFileNameComponents = poiFileName.components(separatedBy: ".")
            let poiFilePath = Bundle.main.path(forResource: poiFileNameComponents[0], ofType: poiFileNameComponents[1])!
            for (name, data) in NSDictionary(contentsOfFile: poiFilePath)! {
                let poiData = data as! [String:String]
                
                if let latitude = poiData["latitude"], let longitude = poiData["longitude"], let description = poiData["description"] {
                    let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude)!, longitude: CLLocationDegrees(longitude)!)
                    
                    let title = name as! String
                    let poi = PointOfInterest(title: title, coordinate: coordinate, narrative: description)
                    pointsOfInterest.append(poi)
                }
            }
            return pointsOfInterest.sorted { $0.coordinate.longitude < $1.coordinate.longitude }
        }

        // MKAnnotation implementation
        let title: String?
        let subtitle: String?
        let coordinate: CLLocationCoordinate2D

        let narrative: String
        let location: CLLocation
        fileprivate(set) var distance: Double? // The distance will remain nil if location services are unavailable or unauthorized.

        
        fileprivate init(title: String, coordinate: CLLocationCoordinate2D, narrative: String) {
            self.title = title
            self.coordinate = coordinate
            self.narrative = narrative
            subtitle = "lat \(coordinate.latitude), long \(coordinate.longitude)"
            location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }
    }
}

extension Trail : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        switch status {
        case CLAuthorizationStatus.notDetermined:
            manager.requestWhenInUseAuthorization();
            
        case CLAuthorizationStatus.authorizedWhenInUse:
            manager.startUpdatingLocation()
            
        default:
            alertUser("Location Access Not Authorized", body: "Trail of History will not be able show you the distance to the points of interest. You can change the authorization in Settings")
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let YardsPerMeter = 1.0936
        let userLocation = locations[locations.count - 1]
        for poi in pointsOfInterest {
            poi.distance = userLocation.distance(from: poi.location) * YardsPerMeter
        }
    }
}
