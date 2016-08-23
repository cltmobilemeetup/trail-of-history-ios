//
//  MapViewController.swift
//  Trail of History
//
//  Created by Robert Vaessen on 8/22/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import UIKit

class MapViewController: UIViewController {
    
    @IBOutlet weak var collectionViewWidthConstraint : NSLayoutConstraint!
    @IBOutlet weak var collectionViewHeightConstraint : NSLayoutConstraint!
    
    private let poiCardCellReuseIdentifier = "POI Card Cell"
    private let poiCardNames = ["Robert", "Rachael", "Derek", "Eva", "Eric", "Mabel", "Jessica"]


    override func viewDidLoad() {
        super.viewDidLoad()
        
        for view in self.view.subviews where view is UICollectionView {
            let collectionView = view as! UICollectionView
            let nib = UINib(nibName: "PoiCard", bundle: nil)
            collectionView.registerNib(nib, forCellWithReuseIdentifier: poiCardCellReuseIdentifier)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
        return poiCardNames.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let card = collectionView.dequeueReusableCellWithReuseIdentifier(poiCardCellReuseIdentifier, forIndexPath: indexPath) as! PoiCard
        card.name = poiCardNames[indexPath.row]
        
        return card
    }
}

extension MapViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(CGFloat(200), CGFloat(70))
    }
}
