//
//  PointOfInterest.swift
//  Trail of History
//
//  Created by Robert Vaessen on 12/18/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import CoreLocation
import UIKit
import Firebase

class PointOfInterest {
    private static var pointsOfInterest: [PointOfInterest]!
    private static var loadingCompleted = false
    private static var callbacks = [(PointOfInterest) -> Void]()
    private static let queue = DispatchQueue(label: "Points of Interest")

    static func getAll(callback: @escaping (PointOfInterest) -> Void) {
        queue.async {
            if pointsOfInterest == nil {
                pointsOfInterest = [PointOfInterest]()
                //loadFromFile()
                loadFromFirebase()
            }
            
            // Execute the callback for all points of interest that have already been loaded
            for poi in pointsOfInterest {
                DispatchQueue.main.async {
                    callback(poi)
                }
            }
            // If we are still waiting for some points of interest to arrive
            // then save the callback so that it can be executed when they do.
            if !loadingCompleted {
                callbacks.append(callback)
            }
        }
    }
    
    static private func loadFromFirebase() {
        
        let reference = FIRDatabase.database().reference(withPath: "pointOfInterest")
        reference.observe(.value, with: { parent in
            if parent.childrenCount > 0 {
                for child in parent.children {
                    let value = (child as! FIRDataSnapshot).value
                    let properties = value as! [String: Any]
                    if let poi = PointOfInterest(properties: properties) {
                        loadImage(poi: poi, totalPoiCount: Int(parent.childrenCount))
                    }
                    else {
                        print("Invalid POI data: \(properties)")
                    }
                }
            }
            else {
                loadingCompleted = true
            }
        })
    }
    
    static private func loadFromFile() {
        
        if  let filePath = Bundle.main.path(forResource: "PointsOfInterest", ofType: "json"),
            let rawData = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
            let jsonData = try? JSONSerialization.jsonObject(with: rawData) {
            
            let container = jsonData as! [String : Dictionary<String, Dictionary<String, Any>>]
            let list = container["pointOfInterest"]!
            if list.count > 0 {
                for (_, properties) in list {
                    if let poi = PointOfInterest(properties: properties) {
                        loadImage(poi: poi, totalPoiCount: list.count)
                    }
                    else {
                        print("Invalid POI data: \(properties)")
                    }
                }
            }
            else {
                loadingCompleted = true
            }
        }
        else {
            loadingCompleted = true
        }
    }

    static private func loadImage(poi: PointOfInterest, totalPoiCount: Int) {
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
                image = generateImage(from: "\(poi.name)'s image could not be downloaded\n\n[image url: \(poi.imageUrl)]\n[details: \(errorText)]")
            }

            poi.image = image!

            finishLoading(poi: poi, totalPoiCount: totalPoiCount)
        }
        imageDownloadTask.resume()
    }

    static private func finishLoading(poi: PointOfInterest, totalPoiCount: Int) {
        
        queue.async {
            pointsOfInterest.append(poi)
            loadingCompleted = pointsOfInterest.count == totalPoiCount
            
            for callback in callbacks {
                DispatchQueue.main.async {
                    callback(poi)
                }
            }
            
            if loadingCompleted {
                callbacks.removeAll()
            }
        }
    }

    static func sort() -> [PointOfInterest] {
        return pointsOfInterest.sorted { $0.coordinate.longitude < $1.coordinate.longitude }

    }
    
    private static func generateImage(from: String) -> UIImage
    {
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

    //**************************************************************************************************************
    
    let name: String
    let description: String
    let coordinate: CLLocationCoordinate2D

    private let imageUrl: URL
    private(set) var image: UIImage!

    private init?(properties: Dictionary<String, Any>) {
        if  let name = properties["name"], let latitude = properties["latitude"], let longitude = properties["longitude"], let description = properties["description"], let imageUrl = properties["imageUrl"] {

            self.name = name as! String
            self.description = description as! String

            self.coordinate = CLLocationCoordinate2D(latitude: latitude as! Double, longitude: longitude as! Double)

            let url = URL(string: imageUrl as! String)
            if url == nil { return nil }
            self.imageUrl = url!

        }
        else {
            return nil
        }
    }
}
