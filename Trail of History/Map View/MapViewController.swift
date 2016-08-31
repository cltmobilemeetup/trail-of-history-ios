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
    
    private let trailBoundsFileName = "TrailBounds"
    private var trailBounds: TrailBounds?
    private let poiDataFileName = "PoiData"
    private var poiAnnotations: [PoiAnnotation]?
    @IBOutlet weak var mapView: MKMapView!

    @IBOutlet weak var collectionView : UICollectionView!
    private let poiCardCellReuseIdentifier = "POI Card Cell"

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.registerNib(UINib(nibName: "PoiCard", bundle: nil), forCellWithReuseIdentifier: poiCardCellReuseIdentifier)

        navigationItem.titleView = UINib(nibName: "Title", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as? UIView
        navigationItem.rightBarButtonItem?.tintColor = UIColor.tohTerracotaColor()
        
        setupMap()
    }
    
    override func viewWillAppear(animated: Bool) {
        navigationItem.hidesBackButton = true
    }

    private func setupMap() {
        guard let bounds = TrailBounds(filename: trailBoundsFileName)
        else {
            print("Cannot create the trail bounds from \(trailBoundsFileName)")
            return
        }
        trailBounds = bounds
        mapView.region = trailBounds!.region

        guard let annotations = PoiAnnotation.makeAnnotations(poiDataFileName)
        else {
            print("Cannot create the POI annotations from \(poiDataFileName)")
            return
        }
        mapView.addAnnotations(annotations)
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
        return DummyData.poiNames.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let card = collectionView.dequeueReusableCellWithReuseIdentifier(poiCardCellReuseIdentifier, forIndexPath: indexPath) as! PoiCard
        card.name = DummyData.poiNames[indexPath.row]
        
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
