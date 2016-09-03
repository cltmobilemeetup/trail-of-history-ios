//
//  MapViewController.swift
//  Trail of History
//
//  Created by Robert Vaessen on 8/22/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView : UICollectionView!
    
    private let poiCellReuseIdentifier = "PointOfInterestCell"

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = UIView.fromNib("Title")
        navigationItem.rightBarButtonItem?.tintColor = UIColor.tohTerracotaColor()
        
        mapView.region = TrailBounds.instance.region
        mapView.addAnnotations(PointOfInterest.pointsOfInterest)
        
        let poiCellNib = UINib(nibName: "PointOfInterestCell", bundle: nil)
        collectionView.registerNib(poiCellNib, forCellWithReuseIdentifier: poiCellReuseIdentifier)
    }
    
    override func viewWillAppear(animated: Bool) {
        navigationItem.hidesBackButton = true
    }

}

extension MapViewController : UICollectionViewDelegate {
    /*
     override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
     // handle tap events
     print("You selected card #\(indexPath.item + 1).")
     }
     
     // change background color when user touches card
     override func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
     let card = collectionView.cellForItemAtIndexPath(indexPath)
     card?.backgroundColor = UIColor.redColor()
     }
     
     // change background color back when user releases card
     override func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
     let card = collectionView.cellForItemAtIndexPath(indexPath)
     card?.backgroundColor = UIColor.yellowColor()
     }
     */
}

extension MapViewController : UICollectionViewDataSource {

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return PointOfInterest.pointsOfInterest.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        // The points of interest are sorted by longitude, westmost first. The cell corresponding to the westmost poi will be first
        // and the cell corresponding to the eastmost poi will be last. Thus the horizontal sequencing of the cells from left to
        // right will match the logitudinal sequencing of the points of interest from west to east.
        let poi = PointOfInterest.pointsOfInterest[indexPath.row]
        let poiCell = collectionView.dequeueReusableCellWithReuseIdentifier(poiCellReuseIdentifier, forIndexPath: indexPath) as! PointOfInterestCell
        
        poiCell.nameLabel.text = poi.title
        if let distance = poi.distance { poiCell.distanceLabel.text = "\(distance) yds" }
        else {  poiCell.distanceLabel.text = "<unknown>"}
        
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
        
        if annotation is PointOfInterest {
            let reuseId = "Pin"

            if let annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) {
                annotationView.annotation = annotation
                return annotationView
            }
            else {
                let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                annotationView.canShowCallout = true
                annotationView.image = UIImage(named: "PoiPin")
                return annotationView
            }
        }

        return nil
    }

    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        // Scroll the collection view to the cell (point of interest) that corresponds to the selected annotation (point of interest).
        if let pointOfInterest = view.annotation as? PointOfInterest {
            let position = PointOfInterest.pointsOfInterest.indexOf(pointOfInterest)!
            collectionView.scrollToItemAtIndexPath(NSIndexPath(forRow: position, inSection: 0), atScrollPosition: .CenteredHorizontally, animated: true)
        }
    }
}
