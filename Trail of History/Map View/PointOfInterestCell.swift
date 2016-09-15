//
//  PointOfInterestCell.swift
//  Trail of History
//
//  Created by Robert Vaessen on 9/3/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import UIKit

class PointOfInterestCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    weak var collectionView: UICollectionView!

    private lazy var detailView: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        label.autoresizingMask = [.FlexibleTopMargin, .FlexibleRightMargin, .FlexibleBottomMargin, .FlexibleLeftMargin]
        label.numberOfLines = 0 // As many as needed
        label.lineBreakMode = .ByWordWrapping
        label.backgroundColor = UIColor.whiteColor()
        label.userInteractionEnabled = true
        label.layer.cornerRadius = 5
        label.layer.borderColor = UIColor.grayColor().CGColor
        label.layer.borderWidth = 1
        label.addGestureRecognizer(UITapGestureRecognizer(target:self, action: #selector(dismissDetailView(_:))))
        return label
    }()

    @IBAction func presentDetailView(sender: UIButton) {
        if detailView.superview == nil {
            let index = collectionView.indexPathForCell(self)!.item
            let poi = Trail.instance.pointsOfInterest[index]
            detailView.text = poi.narrative
            
            let parentView = collectionView.superview!
            parentView.addSubview(detailView)
            detailView.bounds = CGRectInset(parentView.bounds, 50, 100)
            detailView.sizeToFit()
            detailView.center = CGPoint(x: parentView.bounds.width/2, y: parentView.bounds.height/2)
            
            collectionView.scrollEnabled = false
        }
        else {
            dismissDetailView()
        }
    }
    
    func dismissDetailView(sender: UITapGestureRecognizer) {
        if sender.state == .Ended {
            dismissDetailView()
        }
    }

    private func dismissDetailView() {
        detailView.removeFromSuperview()
        collectionView.scrollEnabled = true
    }
}