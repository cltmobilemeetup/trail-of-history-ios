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

    class Notifier {

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
        
        fileprivate init() {}
        
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

    static let notifier = Notifier()
    
    let id: String
    let name: String
    let description: String
    let coordinate: CLLocationCoordinate2D

    fileprivate(set) var image: UIImage!
    fileprivate let imageUrl: URL

    private let location: CLLocation

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
            
        }
        else {
            return nil
        }
    }

    func distance(to location: CLLocation) -> Double {
        let YardsPerMeter = 1.0936
        return location.distance(from: self.location) * YardsPerMeter
    }
}
