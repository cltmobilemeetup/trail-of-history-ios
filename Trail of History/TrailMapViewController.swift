//
//  TrailMapViewController.swift
//  Trail of History
//
//  Created by Dagna Bieda on 5/19/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import UIKit
import MapKit

enum MapType: Int {
    case Standard = 0
    case Hybrid
    case Satellite
}

class TrailMapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapTypeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var mapView: MKMapView!

    var trail = Trail(filename: "TrailOfHistoryGeo")
    var selectedOptions = [MapOptionsType]()

    @IBAction func closeOptions(exitSegue: UIStoryboardSegue) {
        let optionsViewController = exitSegue.sourceViewController as! MapOptionsViewController
        selectedOptions = optionsViewController.selectedOptions
        self.loadSelectedOptions()
    }

    @IBAction func mapTypeChanged(sender: AnyObject) {
        switch MapType(rawValue: mapTypeSegmentedControl.selectedSegmentIndex) {
        case .None, .Some(.Standard):
            mapView.mapType = MKMapType.Standard
        case .Some(.Hybrid):
            mapView.mapType = MKMapType.Hybrid
        case .Some(.Satellite):
            mapView.mapType = MKMapType.Satellite
        }
    }

    // MARK: VCLifecycle
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        let latitudeDelta = fabs(trail.overlayTopLeftCoordinate.latitude - trail.overlayBottomRightCoordinate.latitude)
        let longitudeDelta = fabs(trail.overlayTopLeftCoordinate.longitude - trail.overlayBottomRightCoordinate.longitude)
        let span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta)
        let region = MKCoordinateRegionMake(trail.midCoordinate, span)

        mapView.region = region
    }

    // MARK: Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let optionsViewController = segue.destinationViewController as! MapOptionsViewController
        optionsViewController.selectedOptions = selectedOptions
    }

    // MARK: MKMapViewDelegate
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is TrailMapOverlay {
            let trailOfHistoryImage = UIImage(named: "overlay_trail")
            let overlayView = TrailMapOverlayView(overlay: overlay, overlayImage: trailOfHistoryImage!)

            return overlayView
        }

        return MKOverlayRenderer()
    }

    // MARK: Helper functions
    func loadSelectedOptions() {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)

        for option in selectedOptions{
            switch option {
            case .MapOverlay: addOverlay()
            case .MapPins: addAttractionPins()
            default: break
            }
        }
    }

    func addOverlay() {
        let overlay = TrailMapOverlay(trail: trail)
        mapView.addOverlay(overlay)
    }

    func addAttractionPins() {
        let filePath = NSBundle.mainBundle().pathForResource("StatuesInfo", ofType: "plist")

        if let attractions = NSDictionary(contentsOfFile: filePath!)?.allValues {
            for attraction in attractions {
                let (title, description) = (attraction["name"] as! String, attraction["description"] as! String)
                let point = CGPointFromString(attraction["location"] as! String)
                let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(point.x), longitude: CLLocationDegrees(point.y))

                let annotation = StatueAnnotation(coordinate: coordinate, title: title, description: description)
                mapView.addAnnotation(annotation)
            }
        }
    }
}
