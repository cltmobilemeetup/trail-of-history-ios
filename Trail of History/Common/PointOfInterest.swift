//
//  PointOfInterest.swift
//  Trail of History
//
//  Created by Robert Vaessen on 12/23/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation

class PointOfInterest {

    class DatabaseNotifier {

        static let instance = DatabaseNotifier()

        enum Event {
            case added
            case updated
            case removed
        }
        
        typealias Listener = (PointOfInterest, Event) -> Void
        
        class Token {
            fileprivate init() {}
        }
        
        private class Registrant : Token {
            
            private var listener: Listener?
            private var dispatchQueue: DispatchQueue?
            private var reference: FIRDatabaseReference?
            
            fileprivate init(listener: @escaping Listener, dispatchQueue: DispatchQueue) {
                self.listener = listener
                self.dispatchQueue = dispatchQueue
                self.reference = FIRDatabase.database().reference(withPath: "pointOfInterest")
                
                super.init()
                
                reference!.observe(.childAdded,   with: { self.notify(properties: $0.value as! [String: Any], event: .added) })
                reference!.observe(.childChanged, with: { self.notify(properties: $0.value as! [String: Any], event: .updated) })
                reference!.observe(.childRemoved, with: { self.notify(properties: $0.value as! [String: Any], event: .removed) })
            }
            
            deinit {
                cancel()
            }
            
            fileprivate func cancel() {
                if let ref = reference {
                    ref.removeAllObservers()
                    reference = nil
                    
                    listener = nil
                    dispatchQueue = nil
                }
            }
            
            private func notify(properties: [String: Any], event: Event) {
                if let poi = PointOfInterest(properties: properties) {
                    loadImage(poi: poi, event: event)
                }
                else {
                    print("Invalid POI data: \(properties)")
                }
            }
            
            private func loadImage(poi: PointOfInterest, event: Event) {
                let session = URLSession(configuration: .default)
                let imageDownloadTask = session.dataTask(with: poi.imageUrl) { (data, response, error) in
                    
                    var image: UIImage?
                    var errorText = ""
                    
                    if let error = error {
                        errorText = "Error = \(error)"
                    }
                    else {
                        if let response = response as? HTTPURLResponse {
                            if let data = data {
                                image = UIImage(data: data)
                                if image == nil {
                                    errorText = "UIImage could not be created (image data is corrupt?)"
                                }
                            }
                            else {
                                errorText = "Image data = nil (http response code = \(response.statusCode).)"
                            }
                        }
                        else {
                            errorText = "Http response = nil"
                        }
                    }
                    
                    // If the image could not be obtained then create a "standin" image that will inform the user.
                    if image == nil {
                        image = self.generateImage(from: "\(poi.name)'s image could not be downloaded\n\n[image url: \(poi.imageUrl)]\n[details: \(errorText)]")
                    }
                    
                    poi.image = image!
                    
                    self.dispatchQueue!.async {
                        self.listener!(poi, event)
                    }
                    
                }
                imageDownloadTask.resume()
            }
            
            private func generateImage(from: String) -> UIImage {
                let image = UIImage(named: "blank")!
                
                let imageView = UIImageView(image: image)
                imageView.backgroundColor = UIColor.clear
                imageView.frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
                
                let label = UILabel(frame: imageView.frame)
                label.backgroundColor = UIColor.clear
                label.textAlignment = .center
                label.textColor = UIColor.white
                label.text = from
                
                UIGraphicsBeginImageContextWithOptions(label.bounds.size, false, 0);
                imageView.layer.render(in: UIGraphicsGetCurrentContext()!)
                label.layer.render(in: UIGraphicsGetCurrentContext()!)
                let textImage = UIGraphicsGetImageFromCurrentImageContext()!
                UIGraphicsEndImageContext();
                
                return textImage
            }
        }
        
        private init() {}
        
        func register(listener: @escaping Listener, dispatchQueue: DispatchQueue) -> Token {
            return Registrant(listener: listener, dispatchQueue: dispatchQueue)
        }
        
        func deregister(token: Token) {
            (token as? Registrant)?.cancel()
        }
        
        private func loadFrom(file: String) -> [PointOfInterest]? {
            
            var pointsOfInterest: [PointOfInterest]?
            
            let components = file.components(separatedBy: ".")
            if  components.count == 2,
                let filePath = Bundle.main.path(forResource: components[0], ofType: components[1]),
                let rawData = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
                let jsonData = try? JSONSerialization.jsonObject(with: rawData) {
                
                let container = jsonData as! [String : Dictionary<String, Dictionary<String, Any>>]
                let list = container["pointOfInterest"]!
                if list.count > 0 {
                    
                    for (_, properties) in list {
                        if let poi = PointOfInterest(properties: properties) {
                            if pointsOfInterest == nil { pointsOfInterest = [PointOfInterest]() }
                            pointsOfInterest!.append(poi)
                        }
                        else {
                            print("Invalid POI data: \(properties)")
                        }
                    }
                }
                else {
                    print("The Points of Interest file does not contain any valid data")
                }
            }
            else {
                print("The Points of Interest file cannot be loaded/parsed")
            }
            
            return pointsOfInterest
        }
    }

    private class DistanceToUserUpdater : NSObject, CLLocationManagerDelegate {

        static let instance = DistanceToUserUpdater()

        private class PoiReference {
            weak var poi : PointOfInterest?
            init (poi : PointOfInterest) {
                self.poi = poi
            }
        }

        private var poiReferences = [PoiReference]()
        private let locationManager : CLLocationManager?
        private let YardsPerMeter = 1.0936

        private override init() {
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
            let userLocation = locations[locations.count - 1]
            for ref in poiReferences {
                if let poi = ref.poi {
                    poi.distanceFromUser = userLocation.distance(from: poi.location) * YardsPerMeter
                }
            }
            poiReferences = poiReferences.filter { nil != $0.poi }
        }
 
        func add(_ poi: PointOfInterest) {
            poiReferences.append(PoiReference(poi: poi))
        }
    }

    let id: String
    let name: String
    let description: String
    let coordinate: CLLocationCoordinate2D

    fileprivate(set) var image: UIImage!
    fileprivate let imageUrl: URL

    private let location: CLLocation
    private var distanceFromUser: Double? // Units are yards

    fileprivate init?(properties: Dictionary<String, Any>) {
        if  let id = properties["uid"], let name = properties["name"], let latitude = properties["latitude"],
            let longitude = properties["longitude"], let description = properties["description"], let imageUrl = properties["imageUrl"] {
            
            self.id = id as! String
            self.name = name as! String
            self.description = description as! String
            
            self.coordinate = CLLocationCoordinate2D(latitude: latitude as! Double, longitude: longitude as! Double)
            location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            
            let url = URL(string: imageUrl as! String)
            if url == nil { return nil }
            self.imageUrl = url!

            DistanceToUserUpdater.instance.add(self)
        }
        else {
            return nil
        }
    }

    func distanceToUser() -> String {
        // The Trail class' singleton is using a location manager to update the distances of all of the
        // Points of Interest. The distances will be nil if location services are unavailable or unauthorized.
        if let distance = distanceFromUser {
            return "\(Int(round(distance))) yds"
        }
        return "<unknown>"
    }
}
