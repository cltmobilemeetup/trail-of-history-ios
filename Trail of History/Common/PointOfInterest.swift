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
        
        final class Token {
            var token: Any!
            init(token: Any) { self.token = token }
        }
        
        private class Registrant {
            
            private var listener: Listener
            private var dispatchQueue: DispatchQueue
            private var reference: FIRDatabaseReference
            
            fileprivate init(listener: @escaping Listener, dispatchQueue: DispatchQueue) {
                self.listener = listener
                self.dispatchQueue = dispatchQueue
                self.reference = FIRDatabase.database().reference(withPath: "pointOfInterest")

                reference.observe(.childAdded,   with: { self.notify(properties: $0.value as! [String: Any], event: .added) })
                reference.observe(.childChanged, with: { self.notify(properties: $0.value as! [String: Any], event: .updated) })
                reference.observe(.childRemoved, with: { self.notify(properties: $0.value as! [String: Any], event: .removed) })
            }
            
            deinit {
                cancel()
            }
            
            fileprivate func cancel() {
                reference.removeAllObservers()
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
                            if response.statusCode == 200 {
                                if let data = data {
                                    image = UIImage(data: data)
                                    if image == nil {
                                        errorText = "image data is corrupt"
                                    }
                                }
                                else {
                                    errorText = "image data is nil"
                                }
                            }
                            else {
                                errorText = "http response code = \(response.statusCode)"
                            }
                        }
                        else {
                            errorText = "http response is nil"
                        }
                    }
                    
                    // If the image could not be obtained then create a "standin" image that will inform the user.
                    if image == nil {
                        image = self.generateImage(from: "Image Error: \(errorText)")
                    }
                    
                    poi.image = image!
                    
                    self.dispatchQueue.async {
                        self.listener(poi, event)
                    }
                    
                }
                imageDownloadTask.resume()
            }
            
            private func generateImage(from: String) -> UIImage {
                let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 25))
                label.backgroundColor = UIColor.clear
                label.textAlignment = .center
                label.textColor = UIColor.red
                label.font = UIFont.systemFont(ofSize: 4)
                label.numberOfLines = 0
                label.text = from
                
                UIGraphicsBeginImageContextWithOptions(label.bounds.size, false, 0);
                label.layer.render(in: UIGraphicsGetCurrentContext()!)
                let textImage = UIGraphicsGetImageFromCurrentImageContext()!
                UIGraphicsEndImageContext();
                
                return textImage
            }
        }

        private enum ConnectionState {
            case initialCall
            case neverConnected
            case connected
            case disconnected
        }

        private let connectedRef: FIRDatabaseReference
        private var connectionState: ConnectionState = .initialCall
        private let alertTitle = "Trail of History Database"
        private let magicPath = ".info/connected"

        private init() {
            // At startup time the connection observer will be called twice. The first time with a value of false.
            // The second time with a value of true(false) according to whether everything [Device is connected to the
            // network, Firebase server is up] is(is not) up and running. Thereafter the observer will be called
            // once whenever the connection state changes.
    
            connectedRef = FIRDatabase.database().reference(withPath: magicPath)
            connectedRef.observe(.value, with: {
                var isConnected = false
                if let connected = $0.value as? Bool, connected { isConnected = true }

                switch self.connectionState {

                case .initialCall:
                    assert(!isConnected, "Our assumption that the observer's initial call will be with a value of false has been violated!")
                    self.connectionState = .neverConnected

                case .neverConnected:
                    if isConnected {
                        self.connectionState = .connected
                    } else {
                        self.connectionState = .disconnected
                        alertUser(title: self.alertTitle, body: "We could not connect to the database. Please ensure that your device is connected to the internet.")
                    }

                case .connected:
                    assert(!isConnected, "We are already connected. Why are we being called again with a value of true?")
                    if !isConnected {
                        self.connectionState = .disconnected
                        alertUser(title: self.alertTitle, body: "The connection to the database has been lost. The app will continue to work with the Points of Interest that have already been downloaded. You will not receive updates (which, anyway, are rare).")
                    }

                case .disconnected:
                    assert(isConnected, "We are already disconnected. Why are we being called again with a value of false?")
                    if isConnected {
                        self.connectionState = .connected
                        alertUser(title: self.alertTitle, body: "The connection to the database has been established.")
                    }
                }
            })

//            let timer = Timer(timeInterval: 5, target: self, selector: #selector(databaseConnectionTimer), userInfo: nil, repeats: false)
//            RunLoop.main.add(timer, forMode: RunLoopMode.commonModes)
        }
        
        @objc func databaseConnectionTimer(_ timer: Timer) {
            if self.connectionState == .neverConnected {
                alertUser(title: alertTitle, body: "We have been unable to establish a connection to the database. Please ensure that your device is connected to the internet.")
                self.connectionState = .disconnected // Doing this causes the connection established alert to be presented if/when the connection happens (see the connectedRef observer)
            }
        }

        func register(listener: @escaping Listener, dispatchQueue: DispatchQueue) -> Token {
            return Token(token: Registrant(listener: listener, dispatchQueue: dispatchQueue))
        }
        
        func deregister(token: Token) {
            if let registrant = token.token as? Registrant {
                registrant.cancel()
                token.token = nil
            }
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
                alertUser(title: "Location Services Needed", body: "Please enable location services so that Trail of History can show you where you are on the trail and what the distances to the points of interest are.")
            }
        }

        func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            
            switch status {
            case CLAuthorizationStatus.notDetermined:
                manager.requestWhenInUseAuthorization();
                
            case CLAuthorizationStatus.authorizedWhenInUse:
                manager.startUpdatingLocation()
                
            default:
                alertUser(title: "Location Access Not Authorized", body: "Trail of History will not be able show you the distance to the points of interest. You can change the authorization in Settings")
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
