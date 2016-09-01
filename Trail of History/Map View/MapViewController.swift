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
    private let poiCardCellReuseIdentifier = "POI Card Cell"

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.registerNib(UINib(nibName: "PoiCard", bundle: nil), forCellWithReuseIdentifier: poiCardCellReuseIdentifier)

        navigationItem.titleView = UINib(nibName: "Title", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as? UIView
        navigationItem.rightBarButtonItem?.tintColor = UIColor.tohTerracotaColor()
        
        if let bounds = TrailBounds.instance {
            mapView.region = bounds.region
            
            if let annotations = PointOfInterest.pointsOfInterest {
                mapView.addAnnotations(annotations)
            }
        }
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
        if let count = PointOfInterest.pointsOfInterest?.count { return count }
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let card = collectionView.dequeueReusableCellWithReuseIdentifier(poiCardCellReuseIdentifier, forIndexPath: indexPath) as! PoiCard
        if let title = PointOfInterest.pointsOfInterest?[indexPath.row].title { card.name = title }
        
        return card
    }
}

extension MapViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(CGFloat(280), CGFloat(70))
    }
}

extension MapViewController : MKMapViewDelegate {
}
