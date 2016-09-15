//
//  MapViewController.swift
//  Trail of History
//
//  Created by Dagna Bieda & Robert Vaessen on 8/22/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

// Latitude is 0 degrees at the equater. It increases heading north, becoming +90 degrees
// at the north pole. It decreases heading south, becoming -90 degrees at the south pole.
//
// Longitude is 0 degress at the prime meridian (Greenwich, England). It increases heading
// east, becoming +180 degrees when it reaches the "other side" of the prime meridian.
// It decreases heading west, becoming -180 degrees when it reaches the other side.

import UIKit
import MapKit

// This wrapper allows us to pass an Any (struct, enum, function, class) where an AnyObject (class) is required.
class ObjectWrapper<T> {
    let value: T
    init(value: T) {
        self.value = value
    }
}

// The Map View Controller presents a MKMapView and a UICollectionView. Each of these two views present the Trail of History's
// points of interest. The map view presents a set of annotations. The collection view presents a set of cards. The map view
// controller uses the concept of a "current" point of interest to keep these two views in sync. The current point of interest
// is the one whose card occupies the majority of the card collection view (the UICollectionView's width has been configured
// such that only one cell can be entirely visible; other cells will be partially visible on the left or the right) and
// whose map annotation is highlighted and centered. Initially the current point of interest is set to the first (westmost)
// point of interest. The user can change the current point of interest in one of two ways:
//      1) By tapping on a different map annotation. The controller will highlight that annotation and center the map on it.
//      2) By scrolling the collection view to a different card.
// Whenever the user performs one of the above actions, the controller will automatically perform the other. Thus the annotations
// and the cards are always kept in sync with regard to the current point of interest.

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView : UICollectionView!
    
    private let poiCellReuseIdentifier = "PointOfInterestCell"

    private var currentPoiIndex = 0
    private let imageForCurrent = UIImage(named: "CurrentPoiAnnotation")
    private let imageForNotCurrent = UIImage(named: "PoiAnnotation")


    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = UIView.fromNib("Title")
        navigationItem.titleView?.backgroundColor = UIColor.clearColor() // It was set to an opaque color in the NIB so that the white, text images would be visible in Interface Builder.
        navigationItem.rightBarButtonItem?.tintColor = UIColor.tohTerracotaColor() // I was unable to access the TOH colors in Interface Builder
         
        let poiCellNib = UINib(nibName: "PointOfInterestCell", bundle: nil)
        collectionView.registerNib(poiCellNib, forCellWithReuseIdentifier: poiCellReuseIdentifier)
        
        mapView.showsUserLocation = true
        mapView.region = Trail.instance.region
        mapView.addAnnotations(Trail.instance.pointsOfInterest)
    }

    override func viewWillAppear(animated: Bool) {
        navigationItem.hidesBackButton = true
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier {
        case "Show Options"?:
            let optionsViewController = segue.destinationViewController as! OptionsViewController
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
 
extension MapViewController : UICollectionViewDelegate {
    
    // When the user scrolls the collection view the current cell will change. We will respond to this change as it occurs
    // by updating the images accordingly. We will accomplish this via a timer which will run for the duration of the
    // scrolling and the deceleration (if any).
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {

        // Whichever cell occupies the specified positon (for example, the center of the collection view) will be considered
        // to be the current cell. In order to detect that a new cell has moved into that position we need to remember which
        // cell had previously occupied that position. By using a curried function we are able to store that information
        // in a way that is entirely local.
        func makeCurrentCellChangeDetecter(position: CGPoint) -> () -> (oldCurrent: NSIndexPath, newCurrent: NSIndexPath)? {
            
            var indexOfCurrent = NSIndexPath(forItem: currentPoiIndex, inSection: 0)
            
            // The detecter returns the index of the cell that has newly occupied the position or
            // returns nil if 1) the cell has not changed or 2) no cell is at the position.
            let changeDetecter: () -> (old: NSIndexPath, new: NSIndexPath)? = {
                let newIndex = self.collectionView.indexPathForItemAtPoint(CGPoint(x: position.x + self.collectionView.contentOffset.x, y: position.y + self.collectionView.contentOffset.y))

                if newIndex == nil || newIndex == indexOfCurrent { return nil }
                
                let oldIndex = indexOfCurrent
                indexOfCurrent = newIndex!
                return (oldIndex, newIndex!)
            }
            
            return changeDetecter
        }

        let centerPoint = CGPoint(x: collectionView.frame.width/2, y: collectionView.frame.height/2)
        let detector = makeCurrentCellChangeDetecter(centerPoint)
        let timer = NSTimer(timeInterval: 0.25, target: self, selector: #selector(currentCellChangeDetectionTimer), userInfo: ObjectWrapper(value: detector), repeats: true)
        NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)}
    
    @objc func currentCellChangeDetectionTimer(timer: NSTimer) {
        let changeDetecter = (timer.userInfo as! ObjectWrapper<() -> (oldCurrent: NSIndexPath, newCurrent: NSIndexPath)?>).value
        if let currentCellChanged = changeDetecter() {
            let oldPoi = Trail.instance.pointsOfInterest[currentCellChanged.oldCurrent.item]
            configurePointOfInterest(oldPoi, isCurrent: false)

            let newPoi = Trail.instance.pointsOfInterest[currentCellChanged.newCurrent.item]
            configurePointOfInterest(newPoi, isCurrent: true)
        }

        if !collectionView.dragging && !collectionView.decelerating { timer.invalidate() }
    }
}

extension MapViewController : UICollectionViewDataSource {

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Trail.instance.pointsOfInterest.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        // The points of interest are sorted by longitude, westmost first. The cell at index 0 will use the data from the westmost (first) poi;
        // the cell at index count - 1 will use the data from the eastmost (last) poi. Thus the horizontal sequencing of the cells from left to
        // right mirrors the logitudinal sequencing of the points of interest from west to east.
        let poi = Trail.instance.pointsOfInterest[indexPath.item]

        let poiCell = collectionView.dequeueReusableCellWithReuseIdentifier(poiCellReuseIdentifier, forIndexPath: indexPath) as! PointOfInterestCell

        poiCell.nameLabel.text = poi.title
        poiCell.imageView.image = isCurrent(poi) ? imageForCurrent : imageForNotCurrent
        poiCell.distanceLabel.text = formatDistanceTo(pointOfInterest: poi)
        
        poiCell.layer.shadowOpacity = 0.3
        poiCell.layer.masksToBounds = false
        poiCell.layer.shadowOffset = CGSize(width: 4, height: 4)

        poiCell.collectionView = collectionView

        return poiCell
    }
}

extension MapViewController : UICollectionViewDelegateFlowLayout {

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(CGFloat(280), CGFloat(70))
    }
}

extension MapViewController : MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        if let poi = annotation as? Trail.PointOfInterest {
            
            let reuseId = "PoiAnnotation"
            let annotationView: MKAnnotationView
            
            if let view = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) {
                annotationView = view
            }
            else {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            }

            annotationView.canShowCallout = calloutsEnabled
            annotationView.image = isCurrent(poi)  ? imageForCurrent : imageForNotCurrent
            return annotationView
        }

        if let userLocation = annotation as? MKUserLocation {
            userLocation.subtitle = "lat \(String(format: "%.6f", userLocation.coordinate.latitude)), long \(String(format: "%.6f", userLocation.coordinate.longitude))"
        }
        
        return nil
    }

    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if let selectedPoi = view.annotation as? Trail.PointOfInterest {
            // If the user tapped on a point of interest other than the current one then ...
            if !isCurrent(selectedPoi) {

                // Scroll the collection view to the cell (point of interest) that corresponds to the selected annotation (point of interest).
                let selectedPoiIndex = Trail.instance.pointsOfInterest.indexOf(selectedPoi)!
                collectionView.scrollToItemAtIndexPath(NSIndexPath(forRow: selectedPoiIndex, inSection: 0), atScrollPosition: .CenteredHorizontally, animated: true)
                
                // Find the current POI and make it not current.
                configurePointOfInterest(Trail.instance.pointsOfInterest[currentPoiIndex], isCurrent: false)
                
                // Now make the selected POI the current POI
                configurePointOfInterest(selectedPoi, isCurrent: true)
            }
        }
    }

    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        return Trail.instance.route.renderer
    }
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        for poi in Trail.instance.pointsOfInterest {
            let index = NSIndexPath(forItem: Trail.instance.pointsOfInterest.indexOf(poi)!, inSection: 0)
            (collectionView.cellForItemAtIndexPath(index) as? PointOfInterestCell)?.distanceLabel.text = formatDistanceTo(pointOfInterest: poi)
        }
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
            return mapView.overlays.count == 1
        }
        set {
            if newValue {
                mapView.addOverlay(Trail.instance.route)
            }
            else {
                mapView.removeOverlay(Trail.instance.route)
            }
        }
    }
    
    var calloutsEnabled: Bool {
        get {
            // The canShowCallout value is the same for all of the POIs.
            // Find the first one and return its value.
            for poi in Trail.instance.pointsOfInterest {
                if let view = mapView.viewForAnnotation(poi) {
                    return view.canShowCallout
                }
            }
            return false
        }
        set {
            for poi in Trail.instance.pointsOfInterest {
                if let view = mapView.viewForAnnotation(poi) {
                    view.canShowCallout = newValue
                }
            }
        }
    }
    
    func zoomToTrail() {
        mapView.region = Trail.instance.region
    }

    func zoomToUser() {
        let userRect = makeRect(center: mapView.userLocation.coordinate, span: Trail.instance.region.span)
        mapView.region = MKCoordinateRegionForMapRect(userRect)
    }

    func zoomToBoth() {
        mapView.region = Trail.instance.region
        if !mapView.userLocationVisible {
            let trailRect = makeRect(center: Trail.instance.region.center, span: Trail.instance.region.span)
            let userRect = makeRect(center: mapView.userLocation.coordinate, span: Trail.instance.region.span)
            let combinedRect = MKMapRectUnion(trailRect, userRect)
            mapView.region = MKCoordinateRegionForMapRect(combinedRect)
        }
    }
}

extension MapViewController { // Utility Methods

    private func isCurrent(poi: Trail.PointOfInterest) -> Bool{
        return currentPoiIndex == Trail.instance.pointsOfInterest.indexOf(poi)!
    }

    /* For the given Point of Interest, set the image used by its collection view cell and its map annotation.
     * The current point of interest uses a unique image; all of the others use the same image.
     * If isCurrent is true then take the additional step of centering the map on the annotation
     */
    private func configurePointOfInterest(poi: Trail.PointOfInterest, isCurrent: Bool) {
        let poiIndex = Trail.instance.pointsOfInterest.indexOf(poi)!

        if isCurrent { currentPoiIndex = poiIndex }
        
        let image = isCurrent ? imageForCurrent : imageForNotCurrent
        
        mapView.viewForAnnotation(poi)?.image = image
        
        let path = NSIndexPath(forItem: poiIndex, inSection: 0)
        (collectionView.cellForItemAtIndexPath(path) as? PointOfInterestCell)?.imageView.image = image
        
        if isCurrent { mapView.setCenterCoordinate(poi.coordinate, animated: true) }
    }
    
    private func formatDistanceTo(pointOfInterest poi: Trail.PointOfInterest) -> String {
        if let distance = poi.distance { return "\(Int(round(distance))) yds" }
        else { return "<unknown>" }
    }

    // Note: I am fairly certain that makeRect() will fail if the user is on a different side of the
    // equator and/or the prime meridian than is the Trail of History. AFAIK this does not matter to us.
    private func makeRect(center center: CLLocationCoordinate2D, span: MKCoordinateSpan) -> MKMapRect {
        let northWestCornerCoordinate = CLLocationCoordinate2D(latitude: center.latitude + span.latitudeDelta/2, longitude: center.longitude - span.longitudeDelta/2)
        let southEastCornetCoordinate = CLLocationCoordinate2D(latitude: center.latitude - span.latitudeDelta/2, longitude: center.longitude + span.longitudeDelta/2)
        let upperLeftCornerPoint = MKMapPointForCoordinate(northWestCornerCoordinate) // x increases to the right, y increases down
        let lowerRightCornerPoint = MKMapPointForCoordinate(southEastCornetCoordinate)
        return MKMapRectMake(upperLeftCornerPoint.x, upperLeftCornerPoint.y, lowerRightCornerPoint.x - upperLeftCornerPoint.x, lowerRightCornerPoint.y - upperLeftCornerPoint.y)
    }
}
 