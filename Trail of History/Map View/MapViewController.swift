//
//  MapViewController.swift
//  Trail of History
//
//  Created by Robert Vaessen on 8/22/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import UIKit
import MapKit

// The Map View Controller presents a MKMapView and a UICollectionView. Each of these two views present the Trail of History's
// points of interest. The map view presents a set of annotations. The collection view presents a set of cards. The map view
// controller uses the concept of a "current" point of interest to keep these two views in sync. The current point of interest
// is the one whose card occupies the majority of the card collection view (the UICollectionView's width has been configured
// such that only one card can be entirely visible; the other cards will be partially visible on the left or the right) and
// whose map annotation is highlighted and centered. Initially the current point of interest is set to the first (westmost)
// point of interest. The user can change the current point of interest in one of two ways:
//      1) By tapping on a different map annotation. The controller will highlight that annotation and center the map on it.
//      2) By scrolling the collection view to a different card.
// Whenever the user performs one of the above actions, the controller will automatically perform the other. Thus the annotations
// and the cards are always kept in sync, each indicating the same current point of interest.
//
// The Map View Controller also gives the user access to an Options View Controller (via a small drop down arrow to the right
// of the title view). The Options controller allows the user to set various features and to perform various actions.

class MapViewController: UIViewController {
    
    class PoiAnnotation: NSObject, MKAnnotation {
        
        dynamic var title: String?
        dynamic var subtitle: String?
        dynamic var coordinate: CLLocationCoordinate2D

        var poi: PointOfInterest
        

        init(poi: PointOfInterest) {
            title = poi.name
            subtitle = "lat \(poi.coordinate.latitude), long \(poi.coordinate.longitude)"
            coordinate = poi.coordinate

            self.poi = poi
        }

        // TODO: Ensure that MapKit is picking up the changes via KVO
        func update(with poi: PointOfInterest) {
            title = poi.name
            subtitle = "lat \(poi.coordinate.latitude), long \(poi.coordinate.longitude)"
            coordinate = poi.coordinate
            
            self.poi = poi
        }
    }

    @IBOutlet weak var mapView: MKMapView!
    fileprivate var boundary: MKCoordinateRegion!
    fileprivate var currentPoi: PoiAnnotation?
    fileprivate var poiAnnotations = [PoiAnnotation]()

    @IBOutlet weak var collectionView : UICollectionView!
    fileprivate let poiCardReuseIdentifier = "PointOfInterestCard"
    
    private var listenerToken: PointOfInterest.DatabaseNotifier.Token!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = UIView.fromNib("Title")
        navigationItem.titleView?.backgroundColor = UIColor.clear // It was set to an opaque color in the NIB so that the white, text images would be visible in the Interface Builder.
        navigationItem.rightBarButtonItem?.tintColor = UIColor.tohTerracotaColor() // TODO: We should be able to access the TOH custom colors in the Interface Builder
         
        let poiCardNib = UINib(nibName: "PointOfInterestCard", bundle: nil)
        collectionView.register(poiCardNib, forCellWithReuseIdentifier: poiCardReuseIdentifier)
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        
        mapView.showsUserLocation = true
        boundary = mapView.region

        listenerToken = PointOfInterest.DatabaseNotifier.instance.register(listener: poiListener, dispatchQueue: DispatchQueue.main)
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationItem.hidesBackButton = true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {

        case "Show Options"?:
            let optionsViewController = segue.destination as! OptionsViewController
            // TODO: Calculate the preferred size from the actual content of the Options controller's table.
            optionsViewController.preferredContentSize = CGSize(width: 150, height: 325)
            optionsViewController.delegate = self

            let presentationController = optionsViewController.popoverPresentationController!
            presentationController.barButtonItem = sender as? UIBarButtonItem
            presentationController.delegate = optionsViewController

        default:
            break
        }
    }

    func poiListener(poi: PointOfInterest, event: PointOfInterest.DatabaseNotifier.Event) {

        func updateBoundary() {
            if poiAnnotations.count > 0 {
                var westmost = poiAnnotations[0].poi.coordinate.longitude
                var eastmost = westmost
                var northmost = poiAnnotations[0].poi.coordinate.latitude
                var southmost = northmost
                
                for poi in poiAnnotations {
                    if poi.coordinate.longitude < westmost { westmost = poi.coordinate.longitude }
                    else if poi.coordinate.longitude > eastmost { eastmost = poi.coordinate.longitude }
                    if poi.coordinate.latitude > northmost { northmost = poi.coordinate.latitude }
                    else if poi.coordinate.latitude < southmost { southmost = poi.coordinate.latitude }
                }

                westmost -= 0.005
                eastmost += 0.005
                northmost += 0.005
                southmost -= 0.005

                let latitudeDelta = northmost - southmost
                let longitudeDelta = eastmost - westmost
                let span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta)
                let midPoint = CLLocationCoordinate2DMake(southmost + latitudeDelta/2, westmost + longitudeDelta/2)
                
                boundary = MKCoordinateRegionMake(midPoint, span)
                mapView.region = boundary
            }
        }

        func findCentermost() -> PoiAnnotation? { // East to west centermost
            var centermost: PoiAnnotation?
            var delta = Double.greatestFiniteMagnitude
            for annotation in poiAnnotations {
                let newDelta = fabs(mapView.region.center.longitude - annotation.coordinate.longitude)
                if newDelta < delta {
                    delta = newDelta
                    centermost = annotation
                }
            }
            return centermost
        }

        switch event {

        case .added:
            let annotation = PoiAnnotation(poi: poi)
            poiAnnotations.append(annotation)
            mapView.addAnnotation(annotation)

        case .updated:
            if let index = poiAnnotations.index(where: { $0.poi.id == poi.id }) {
                poiAnnotations[index].update(with: poi)
            }
            else {
                print("An unrecognized POI was updated: \(poi)")
            }

        case .removed:
            if let index = poiAnnotations.index(where: { $0.poi.id == poi.id }) {
                let removed = poiAnnotations.remove(at: index)
                mapView.removeAnnotation(removed)

                if let current = currentPoi, current.poi.id == removed.poi.id {
                    currentPoi = nil
                }
            }
            else {
                print("An unrecognized POI was removed: \(poi)")
            }
        }

        poiAnnotations = poiAnnotations.sorted { $0.poi.coordinate.longitude < $1.poi.coordinate.longitude } // Westmost first

        updateBoundary()

        if let centermost = findCentermost() {
            if let current = currentPoi {
                mapView.view(for: current)?.image = #imageLiteral(resourceName: "PoiAnnotationImage")
            }
            currentPoi = centermost
            mapView.view(for: centermost)?.image = #imageLiteral(resourceName: "CurrentPoiAnnotationImage")
            mapView.setCenter(centermost.coordinate, animated: true)
        }

        collectionView.reloadData()

        if let current = currentPoi, let index = poiAnnotations.index(where: { $0.poi.id == current.poi.id }) {
            collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: true)
        }
    }
}

extension MapViewController : MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if let annotation = annotation as? PoiAnnotation {
            
            let reuseId = "PoiAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
            if annotationView == nil  {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            }
            
            annotationView!.canShowCallout = calloutsEnabled
            annotationView!.image = isCurrent(annotation)  ? #imageLiteral(resourceName: "CurrentPoiAnnotationImage") : #imageLiteral(resourceName: "PoiAnnotationImage")
            return annotationView
        }
        
        if let userLocation = annotation as? MKUserLocation {
            userLocation.subtitle = "lat \(String(format: "%.6f", userLocation.coordinate.latitude)), long \(String(format: "%.6f", userLocation.coordinate.longitude))"
        }
        
        return nil
    }
    
    // Make the selected point of interest the new current POI
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let selected = view.annotation as? PoiAnnotation , !isCurrent(selected) {

            if let current = currentPoi {
                mapView.view(for: current)?.image = #imageLiteral(resourceName: "PoiAnnotationImage")
                if let index = poiAnnotations.index(where: { $0.poi.id == current.poi.id }) {
                    (collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? PointOfInterestCard)?.imageView.image = #imageLiteral(resourceName: "PoiAnnotationImage")
                }
            }
            
            currentPoi = selected
            view.image = #imageLiteral(resourceName: "CurrentPoiAnnotationImage")
            mapView.setCenter(currentPoi!.coordinate, animated: true)
            if let index = poiAnnotations.index(where: { $0.poi.id == selected.poi.id }) {
                let path = IndexPath(item: index, section: 0)
                (collectionView.cellForItem(at: path) as? PointOfInterestCard)?.imageView.image = #imageLiteral(resourceName: "CurrentPoiAnnotationImage")
                collectionView.scrollToItem(at: path, at: .centeredHorizontally, animated: true)
            }
        }
    }
}

extension MapViewController : UICollectionViewDelegate {
    
    // As the user scrolls a new point of interest card into view, we respond by making that card's POI
    // the current POI. We track the scrolling via a timer which will run for the duration of the scrolling.

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        //NSTimer.scheduledTimerWithTimeInterval(0.25, target: self, selector: #selector(currentPoiDetectionTimer), userInfo: nil, repeats: true)
        let timer = Timer(timeInterval: 0.25, target: self, selector: #selector(currentPoiDetectionTimer), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: RunLoopMode.commonModes)
    }
    
    @objc func currentPoiDetectionTimer(_ timer: Timer) {
        let centerPoint = CGPoint(x: collectionView.frame.width/2, y: collectionView.frame.height/2)
        if let indexOfCenterCell = self.collectionView.indexPathForItem(at: CGPoint(x: centerPoint.x + self.collectionView.contentOffset.x, y: centerPoint.y + self.collectionView.contentOffset.y)) {

            if let current = currentPoi {
                mapView.view(for: current)?.image = #imageLiteral(resourceName: "PoiAnnotationImage")
                if let index = poiAnnotations.index(where: { $0.poi.id == current.poi.id }) {
                    (collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? PointOfInterestCard)?.imageView.image = #imageLiteral(resourceName: "PoiAnnotationImage")
                }
            }
            
            currentPoi = poiAnnotations[indexOfCenterCell.item]
            mapView.view(for: currentPoi!)?.image = #imageLiteral(resourceName: "CurrentPoiAnnotationImage")
            mapView.setCenter(currentPoi!.coordinate, animated: true)
            (collectionView.cellForItem(at: indexOfCenterCell) as? PointOfInterestCard)?.imageView.image = #imageLiteral(resourceName: "CurrentPoiAnnotationImage")
        }

        if !collectionView.isDragging && !collectionView.isDecelerating { timer.invalidate() }
    }
}

// The FlowLayout looks for the UICollectionViewDelegateFlowLayout protocol's adoption on whatever object is set as the collection's delegate (i.e. UICollectionViewDelegate)
extension MapViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let screenSize: CGRect = UIScreen.main.bounds
        return CGSize(width: CGFloat(screenSize.width * 0.8), height: CGFloat(70))
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let screenSize: CGRect = UIScreen.main.bounds
        return CGSize(width: screenSize.width * 0.1, height: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        let screenSize: CGRect = UIScreen.main.bounds
        return CGSize(width: screenSize.width * 0.1, height: 0)
    }
    
    
//    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
//        return CGSize(width: CGFloat(collectionView.bounds.size.width * 0.8), height: CGFloat(collectionView.bounds.size.height * 0.875))
//    }
//    
//    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        return CGSize(width: collectionView.bounds.size.width * 0.1, height: 0)
//    }
//    
//    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
//        return CGSize(width: collectionView.bounds.size.width * 0.1, height: 0)
//    }
}

extension MapViewController : UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return poiAnnotations.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // The points of interest are sorted by longitude, westmost first. The cell at index 0 will use the data from the westmost (first) poi;
        // the cell at index count - 1 will use the data from the eastmost (last) poi. Thus the horizontal sequencing of the cells from left to
        // right mirrors the logitudinal sequencing of the points of interest from west to east.

        let annotation = poiAnnotations[indexPath.item]
        let poi = annotation.poi

        let poiCell = collectionView.dequeueReusableCell(withReuseIdentifier: poiCardReuseIdentifier, for: indexPath) as! PointOfInterestCard
        poiCell.nameLabel.text = poi.name
        poiCell.imageView.image = isCurrent(annotation) ? #imageLiteral(resourceName: "CurrentPoiAnnotationImage") : #imageLiteral(resourceName: "PoiAnnotationImage")
        poiCell.distanceLabel.text = poi.distanceToUser()
        poiCell.layer.shadowOpacity = 0.3
        poiCell.layer.masksToBounds = false
        poiCell.layer.shadowOffset = CGSize(width: 4, height: 4)

        poiCell.poi = poi
        poiCell.collectionView = collectionView
        
        return poiCell
    }
}

extension MapViewController : OptionsViewControllerDelegate {
    var mapType: MKMapType {
        get {
            return mapView.mapType
        }
        set {
            mapView.mapType = newValue
        }
    }

/*
    var trailRouteVisible: Bool {
        get {
            // We only have 1 possible overlay (currently)
            return mapView.overlays.count == 1
        }
        set {
            if newValue {
                mapView.add(Trail.instance.route)
            }
            else {
                mapView.remove(Trail.instance.route)
            }
        }
    }
*/
    
    // The POI Annotations set their subtitle to display their coordinates.
    // We might not want callouts in the final version and/or we might want to display something different. For
    // now it is useful as a validation tool when we are testing by physically walking the Trail.
    var calloutsEnabled: Bool {
        get {
            // The canShowCallout value is the same for all of the POIs.
            // Find the first one and return its value.
            if poiAnnotations.count > 0, let view = mapView.view(for: poiAnnotations[0]) {
                return view.canShowCallout
            }
            return false
        }
        set {
            for annotation in poiAnnotations {
                mapView.view(for: annotation)?.canShowCallout = newValue
            }
        }
    }
    
    func zoomToTrail() {
        mapView.region = boundary
        if let current = currentPoi {
            mapView.setCenter(current.coordinate, animated: true)
        }
    }

    func zoomToUser() {
        let userRect = makeRect(center: mapView.userLocation.coordinate, span: boundary.span)
        mapView.region = MKCoordinateRegionForMapRect(userRect)
    }

    func zoomToBoth() {
        mapView.region = boundary
        if !mapView.isUserLocationVisible {
            let trailRect = makeRect(center: boundary.center, span: boundary.span)
            let userRect = makeRect(center: mapView.userLocation.coordinate, span: boundary.span)
            let combinedRect = MKMapRectUnion(trailRect, userRect)
            mapView.region = MKCoordinateRegionForMapRect(combinedRect)
        }
    }
}

extension MapViewController { // Utility Methods

    fileprivate func isCurrent(_ annotation: PoiAnnotation) -> Bool {
        return currentPoi?.poi.id == annotation.poi.id
    }

    // TODO: I am fairly certain that makeRect() will fail if the user and the Trail of History
    // are on different sides of the equator and/or the prime meridian. Does this really matter?
    //
    // Latitude is 0 degrees at the equater. It increases heading north, becoming +90 degrees
    // at the north pole. It decreases heading south, becoming -90 degrees at the south pole.
    //
    // Longitude is 0 degress at the prime meridian (Greenwich, England). It increases heading
    // east, becoming +180 degrees when it reaches the "other side" of the prime meridian.
    // It decreases heading west, becoming -180 degrees when it reaches the other side.
    //
    // For Points and Rects: x increases to the right, y increases down
    
    fileprivate func makeRect(center: CLLocationCoordinate2D, span: MKCoordinateSpan) -> MKMapRect {
        let northWestCornerCoordinate = CLLocationCoordinate2D(latitude: center.latitude + span.latitudeDelta/2, longitude: center.longitude - span.longitudeDelta/2)
        let southEastCornetCoordinate = CLLocationCoordinate2D(latitude: center.latitude - span.latitudeDelta/2, longitude: center.longitude + span.longitudeDelta/2)
        let upperLeftCornerPoint = MKMapPointForCoordinate(northWestCornerCoordinate)
        let lowerRightCornerPoint = MKMapPointForCoordinate(southEastCornetCoordinate)
        return MKMapRectMake(upperLeftCornerPoint.x, upperLeftCornerPoint.y, lowerRightCornerPoint.x - upperLeftCornerPoint.x, lowerRightCornerPoint.y - upperLeftCornerPoint.y)
    }
}
 
