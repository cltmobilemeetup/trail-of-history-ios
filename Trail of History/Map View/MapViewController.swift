//
//  MapViewController.swift
//  Trail of History
//
//  Created by Robert Vaessen on 8/22/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import UIKit
import MapKit

// This wrapper allows us to pass an Any (struct, enum, function, class) where an AnyObject (class) is required.
class ObjectWrapper<T> {
    let value: T
    init(value: T) {
        self.value = value
    }
}

// The Map View Controller has the concept of a "current" point of interest. The current point of interest is the one whose card (cell)
// occupies the majority of the card collection view (the UICollectionView's width has been configured such that only one cell can be
// entirely visible; other cells will be only partially visible on the right and/or the left) and whose map annotation is highlighted
// and centered. Initially the current point of interest is set to the first (westmost) point of interest. The user can change it in
// two ways:
//      1) By tapping on a different map annotation. The controller responds by highlighting that annotation and centerimg the map on it.
//      2) By scrolling the collection view to a different card.
// When the user performs one of the these actions, the controller will automatically perform the other. Thus the map annotations and the
// cards are always kept in sync with regard to the current point of interest.
//
class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView : UICollectionView!
    
    private let poiCellReuseIdentifier = "PointOfInterestCell"

    private var locationManager : CLLocationManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        PointOfInterest.pointsOfInterest[0].isCurrent = true

        navigationItem.titleView = UIView.fromNib("Title")
        navigationItem.rightBarButtonItem?.tintColor = UIColor.tohTerracotaColor()
         
        let poiCellNib = UINib(nibName: "PointOfInterestCell", bundle: nil)
        collectionView.registerNib(poiCellNib, forCellWithReuseIdentifier: poiCellReuseIdentifier)
        
         mapView.region = TrailRegion.instance.region
         mapView.addAnnotations(PointOfInterest.pointsOfInterest)

         if CLLocationManager.locationServicesEnabled() {
            locationManager = CLLocationManager()
            //locationManager.desiredAccuracy = 1
            //locationManager.distanceFilter = 0.5
            locationManager.delegate = self
        }
        else {
            alertUser("Location Services Needed", body: "Please enable location services so that Trail of History can show you how far you are from the points of interest.")
        }
    }

    override func viewWillAppear(animated: Bool) {
        navigationItem.hidesBackButton = true
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
            
            let item = PointOfInterest.pointsOfInterest.indexOf(getCurrentPoi())!
            var indexOfCurrent = NSIndexPath(forItem: item, inSection: 0)
            
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
            let oldPoi = PointOfInterest.pointsOfInterest[currentCellChanged.oldCurrent.item]
            configurePointOfInterest(oldPoi, isCurrent: false)

            let newPoi = PointOfInterest.pointsOfInterest[currentCellChanged.newCurrent.item]
            configurePointOfInterest(newPoi, isCurrent: true)
        }

        if !collectionView.dragging && !collectionView.decelerating { timer.invalidate() }
    }
}

extension MapViewController : UICollectionViewDataSource {

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return PointOfInterest.pointsOfInterest.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        // The points of interest are sorted by longitude, westmost first. The cell at index 0 will use the data from the westmost (first) poi;
        // the cell at index count - 1 will use the data from the eastmost (last) poi. Thus the horizontal sequencing of the cells from left to
        // right mirrors the logitudinal sequencing of the points of interest from west to east.
        let poi = PointOfInterest.pointsOfInterest[indexPath.item]

        let poiCell = collectionView.dequeueReusableCellWithReuseIdentifier(poiCellReuseIdentifier, forIndexPath: indexPath) as! PointOfInterestCell

        poiCell.nameLabel.text = poi.title
        poiCell.imageView.image = poi.isCurrent ? PointOfInterest.imageForCurrent : PointOfInterest.imageForNotCurrent
        poiCell.distanceLabel.text = formatDistanceTo(pointOfInterest: poi)
        
        poiCell.layer.shadowOpacity = 0.3
        poiCell.layer.masksToBounds = false
        poiCell.layer.shadowOffset = CGSize(width: 4, height: 4)

        poiCell.showDetailViewDelegate = self

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
        
        if let poi = annotation as? PointOfInterest {
            
            let reuseId = "PoiAnnotation"
            let annotationView: MKAnnotationView
            
            if let view = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) {
                annotationView = view
            }
            else {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            }

            annotationView.canShowCallout = false
            annotationView.image = poi.isCurrent ? PointOfInterest.imageForCurrent : PointOfInterest.imageForNotCurrent
            return annotationView
        }

        return nil
    }

    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if let selectedPoi = view.annotation as? PointOfInterest {
            // If the user tapped on a point of interest other than the current one then ...
            if !selectedPoi.isCurrent {

                // Scroll the collection view to the cell (point of interest) that corresponds to the selected annotation (point of interest).
                let selectedPoiIndex = PointOfInterest.pointsOfInterest.indexOf(selectedPoi)!
                collectionView.scrollToItemAtIndexPath(NSIndexPath(forRow: selectedPoiIndex, inSection: 0), atScrollPosition: .CenteredHorizontally, animated: true)
                
                // Find the current POI and make it not current.
                configurePointOfInterest(getCurrentPoi(), isCurrent: false)
                
                // Now make the selected POI the current POI
                configurePointOfInterest(selectedPoi, isCurrent: true)
            }
        }
    }
}

extension MapViewController : CLLocationManagerDelegate {

    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        switch status {
        case CLAuthorizationStatus.NotDetermined:
            locationManager.requestWhenInUseAuthorization();
            
        case CLAuthorizationStatus.AuthorizedWhenInUse:
            locationManager.startUpdatingLocation()
            
        default:
            break
        }
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        PointOfInterest.updateDistancesTo(userLocation: locations[locations.count - 1])
        for poi in PointOfInterest.pointsOfInterest {
            let path = NSIndexPath(forItem: PointOfInterest.pointsOfInterest.indexOf(poi)!, inSection: 0)
            (collectionView.cellForItemAtIndexPath(path) as? PointOfInterestCell)?.distanceLabel.text = formatDistanceTo(pointOfInterest: poi)
        }
    }
}

extension MapViewController : ShowDetailViewDelegate {

    class GestureRecognizer: UITapGestureRecognizer {
        private var detailView: UILabel
        
        init(target: AnyObject?, action: Selector, detail: UILabel) {
            detailView = detail
            super.init(target: target, action: action)
        }
    }

    func showDetailViewFor(cell: PointOfInterestCell) {
        let detailView = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        detailView.autoresizingMask = [.FlexibleTopMargin, .FlexibleRightMargin, .FlexibleBottomMargin, .FlexibleLeftMargin]
        detailView.numberOfLines = 0 // As many as needed
        detailView.lineBreakMode = .ByWordWrapping
        detailView.backgroundColor = UIColor.whiteColor()
        detailView.userInteractionEnabled = true
        detailView.layer.cornerRadius = 5
        detailView.layer.borderColor = UIColor.grayColor().CGColor
        detailView.layer.borderWidth = 1
        detailView.addGestureRecognizer(GestureRecognizer(target:self, action: #selector(removeDetailView), detail: detailView))
        
        let poi = PointOfInterest.pointsOfInterest[collectionView.indexPathForCell(cell)!.item]
        detailView.text = poi.information
        view.addSubview(detailView)
        detailView.bounds = CGRectInset(view!.bounds, 50, 100)
        detailView.sizeToFit()
        detailView.center = CGPoint(x: view.bounds.width/2, y: view.bounds.height/2)
        
        collectionView.scrollEnabled = false
    }
    
    func removeDetailView(sender: UITapGestureRecognizer) {
        if sender.state == .Ended {
            (sender as! GestureRecognizer).detailView.removeFromSuperview()
            collectionView.scrollEnabled = true
        }
    }
}

extension MapViewController { // Utility Methods

    /* For the given Point of Interest, set the image used by its collection view cell and its map annotation.
     * The current point of interest uses a unique image; all of the others use the same image.
     * If isCurrent is true then take the additional step of centering the map on the annotation
     */
    private func configurePointOfInterest(poi: PointOfInterest, isCurrent: Bool) {
        poi.isCurrent = isCurrent
        
        let image = isCurrent ? PointOfInterest.imageForCurrent : PointOfInterest.imageForNotCurrent
        
        mapView.viewForAnnotation(poi)?.image = image
        
        let path = NSIndexPath(forItem: PointOfInterest.pointsOfInterest.indexOf(poi)!, inSection: 0)
        (collectionView.cellForItemAtIndexPath(path) as? PointOfInterestCell)?.imageView.image = image
        
        if isCurrent { mapView.setCenterCoordinate(poi.coordinate, animated: true) }
    }
    
    private func getCurrentPoi() -> PointOfInterest {
        for poi in PointOfInterest.pointsOfInterest {
            if poi.isCurrent {
                return poi
            }
        }
        
        fatalError("There is not a current Point of Interest???") // This should never happen
    }
    
    private func alertUser(title: String?, body: String?) {
        let alert = UIAlertController(title: title, message: body, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: false, completion: nil)
    }
    
    private func formatDistanceTo(pointOfInterest poi: PointOfInterest) -> String {
        if let distance = poi.distance { return "\(Int(round(distance))) yds" }
        else { return "<unknown>" }
    }
}
 