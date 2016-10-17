//
//  MapViewController.swift
//  Trail of History
//
//  Created by Dagna Bieda & Robert Vaessen on 8/22/16.
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
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView : UICollectionView!
    
    fileprivate let poiCellReuseIdentifier = "PointOfInterestCell"

    fileprivate var currentPoiIndex = 0
    fileprivate let imageForCurrent = UIImage(named: "CurrentPoiAnnotation")
    fileprivate let imageForNotCurrent = UIImage(named: "PoiAnnotation")


    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = UIView.fromNib("Title")
        navigationItem.titleView?.backgroundColor = UIColor.clear // It was set to an opaque color in the NIB so that the white, text images would be visible in the Interface Builder.
        navigationItem.rightBarButtonItem?.tintColor = UIColor.tohTerracotaColor() // TODO: We should be able to access the TOH custom colors in the Interface Builder
         
        let poiCellNib = UINib(nibName: "PointOfInterestCell", bundle: nil)
        collectionView.register(poiCellNib, forCellWithReuseIdentifier: poiCellReuseIdentifier)
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        
        mapView.showsUserLocation = true
        mapView.region = Trail.instance.region
        mapView.addAnnotations(Trail.instance.pointsOfInterest)
        
        setCurrentTo(Trail.instance.pointsOfInterest[currentPoiIndex], suppressCardScrolling: true)
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
}

extension MapViewController : MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if let poi = annotation as? Trail.PointOfInterest {
            
            let reuseId = "PoiAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
            if annotationView == nil  {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            }
            
            annotationView?.canShowCallout = calloutsEnabled
            annotationView?.image = isCurrent(poi)  ? imageForCurrent : imageForNotCurrent
            return annotationView
        }
        
        if let userLocation = annotation as? MKUserLocation {
            userLocation.subtitle = "lat \(String(format: "%.6f", userLocation.coordinate.latitude)), long \(String(format: "%.6f", userLocation.coordinate.longitude))"
        }
        
        return nil
    }
    
    // Make the selected point of interest the new current POI
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let poi = view.annotation as? Trail.PointOfInterest , !isCurrent(poi) {
            changeCurrentTo(poi, suppressCardScrolling: false)
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return Trail.instance.route.renderer
    }
    
    // As the user's location changes, update the distances of the POI collection's visible cards.
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        for index in collectionView.indexPathsForVisibleItems {
            let cell = collectionView.cellForItem(at: index) as! PointOfInterestCell
            let poi = Trail.instance.pointsOfInterest[(index as NSIndexPath).item]
            cell.distanceLabel.text = distanceTo(pointOfInterest: poi)
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
        let indexOfCenterCell = self.collectionView.indexPathForItem(at: CGPoint(x: centerPoint.x + self.collectionView.contentOffset.x, y: centerPoint.y + self.collectionView.contentOffset.y))
        if indexOfCenterCell != nil && indexOfCenterCell?.row != currentPoiIndex {
            changeCurrentTo(Trail.instance.pointsOfInterest[(indexOfCenterCell! as NSIndexPath).item], suppressCardScrolling: true)
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
        return Trail.instance.pointsOfInterest.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // The points of interest are sorted by longitude, westmost first. The cell at index 0 will use the data from the westmost (first) poi;
        // the cell at index count - 1 will use the data from the eastmost (last) poi. Thus the horizontal sequencing of the cells from left to
        // right mirrors the logitudinal sequencing of the points of interest from west to east.
        let poi = Trail.instance.pointsOfInterest[(indexPath as NSIndexPath).item]

        let poiCell = collectionView.dequeueReusableCell(withReuseIdentifier: poiCellReuseIdentifier, for: indexPath) as! PointOfInterestCell
        poiCell.nameLabel.text = poi.title
        poiCell.imageView.image = isCurrent(poi) ? imageForCurrent : imageForNotCurrent
        poiCell.distanceLabel.text = distanceTo(pointOfInterest: poi)
        poiCell.layer.shadowOpacity = 0.3
        poiCell.layer.masksToBounds = false
        poiCell.layer.shadowOffset = CGSize(width: 4, height: 4)
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
    
    // The Trail's Points of Interest (which are MKAnnotations) set their subtitle to display their coordinates.
    // We might not want callouts in the final version and/or we might want to display something different. For
    // now it is useful as a validation tool when we are testing by physically walking the Trail.
    var calloutsEnabled: Bool {
        get {
            // The canShowCallout value is the same for all of the POIs.
            // Find the first one and return its value.
            for poi in Trail.instance.pointsOfInterest {
                if let view = mapView.view(for: poi) {
                    return view.canShowCallout
                }
            }
            return false
        }
        set {
            for poi in Trail.instance.pointsOfInterest {
                if let view = mapView.view(for: poi) {
                    view.canShowCallout = newValue
                }
            }
        }
    }
    
    func zoomToTrail() {
        mapView.region = Trail.instance.region
        mapView.setCenter(Trail.instance.pointsOfInterest[currentPoiIndex].coordinate, animated: true)
    }

    func zoomToUser() {
        let userRect = makeRect(center: mapView.userLocation.coordinate, span: Trail.instance.region.span)
        mapView.region = MKCoordinateRegionForMapRect(userRect)
    }

    func zoomToBoth() {
        mapView.region = Trail.instance.region
        if !mapView.isUserLocationVisible {
            let trailRect = makeRect(center: Trail.instance.region.center, span: Trail.instance.region.span)
            let userRect = makeRect(center: mapView.userLocation.coordinate, span: Trail.instance.region.span)
            let combinedRect = MKMapRectUnion(trailRect, userRect)
            mapView.region = MKCoordinateRegionForMapRect(combinedRect)
        }
    }
}

extension MapViewController { // Utility Methods

    fileprivate func isCurrent(_ poi: Trail.PointOfInterest) -> Bool{
        return currentPoiIndex == Trail.instance.pointsOfInterest.index(of: poi)!
    }

    fileprivate func changeCurrentTo(_ newCurrent: Trail.PointOfInterest, suppressCardScrolling: Bool) {
        // Unset the old
        let currentPoi = Trail.instance.pointsOfInterest[currentPoiIndex]
        mapView.view(for: currentPoi)?.image = imageForNotCurrent
        (collectionView.cellForItem(at: IndexPath(item: currentPoiIndex, section: 0)) as? PointOfInterestCell)?.imageView.image = imageForNotCurrent

        // Set the new
        setCurrentTo(newCurrent, suppressCardScrolling: suppressCardScrolling)
    }
    
    fileprivate func setCurrentTo(_ poi: Trail.PointOfInterest, suppressCardScrolling: Bool) {
        currentPoiIndex = Trail.instance.pointsOfInterest.index(of: poi)!

        mapView.view(for: poi)?.image = imageForCurrent
        (collectionView.cellForItem(at: IndexPath(item: currentPoiIndex, section: 0)) as? PointOfInterestCell)?.imageView.image = imageForCurrent

        mapView.setCenter(poi.coordinate, animated: true)

        if !suppressCardScrolling {
            collectionView.scrollToItem(at: IndexPath(item: currentPoiIndex, section: 0), at: .centeredHorizontally, animated: true)
        }
    }
    
    fileprivate func distanceTo(pointOfInterest poi: Trail.PointOfInterest) -> String {
        // The Trail class' singleton is using a location manager to update the distances of all of the
        // Points of Interest. The distances will be nil if location services are unavailable or unauthorized.
        if let distance = poi.distance { return "\(Int(round(distance))) yds" }
        else { return "<unknown>" }
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
 
