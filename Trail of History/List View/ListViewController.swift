//
//  ListViewController.swift
//  Trail of History
//
//  Created by Mark Flowers on 3/14/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import UIKit

class ListViewController: UICollectionViewController {

    private let identifierPOICell = String(POICollectionViewCell)
    private lazy var collectionViewWidth: CGFloat = {
        return self.collectionView!.bounds.width
    }()

    private let poiCellHeight = CGFloat(100.0)
	
    override func viewDidLoad() {
        super.viewDidLoad()
				collectionView?.registerNib(UINib(nibName: identifierPOICell, bundle: nil), forCellWithReuseIdentifier: identifierPOICell)
				collectionView?.backgroundColor = UIColor.tohGreyishBrownColor()
    }
	
}

// MARK: UICollectionViewDataSource

extension ListViewController {
	
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier("POICollectionViewCell", forIndexPath: indexPath) as! POICollectionViewCell
		return cell
	}
	
	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return 10
	}
	
	func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		return 1
	}
	
	func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {
		return CGSize(width: collectionViewWidth, height: poiCellHeight)
	}
	
	func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
		return UIEdgeInsetsZero
	}
	
	func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
		return 0.0
	}
	
}

// MARK: UICollectionViewDelegate

extension ListViewController {
	
	override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

    
    // MARK: UICollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "POICollectionViewCell", for: indexPath)
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
}

