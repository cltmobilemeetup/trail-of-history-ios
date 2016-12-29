//
//  PointOfInterestCell.swift
//  Trail of History
//
//  Created by Robert Vaessen on 9/3/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import UIKit

class PointOfInterestCard: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    weak var collectionView: UICollectionView!
    var poi: PointOfInterest!

    fileprivate lazy var detailView: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        label.autoresizingMask = [.flexibleTopMargin, .flexibleRightMargin, .flexibleBottomMargin, .flexibleLeftMargin]
        label.numberOfLines = 0 // As many as needed
        label.lineBreakMode = .byWordWrapping
        label.backgroundColor = UIColor.white
        label.isUserInteractionEnabled = true
        label.layer.cornerRadius = 5
        label.layer.borderColor = UIColor.gray.cgColor
        label.layer.borderWidth = 1
        label.addGestureRecognizer(UITapGestureRecognizer(target:self, action: #selector(dismissDetailView(_:))))
        return label
    }()

    @IBAction func presentDetailView(_ sender: UIButton) {
        if detailView.superview == nil {
            detailView.text = poi.description

            let parentView = collectionView.superview!
            parentView.addSubview(detailView)
            detailView.bounds = parentView.bounds.insetBy(dx: 50, dy: 100)
            detailView.sizeToFit()
            detailView.center = CGPoint(x: parentView.bounds.width/2, y: parentView.bounds.height/2)
            
            collectionView.isScrollEnabled = false
        }
        else {
            dismissDetailView()
        }
    }
    
    func dismissDetailView(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            dismissDetailView()
        }
    }

    fileprivate func dismissDetailView() {
        detailView.removeFromSuperview()
        collectionView.isScrollEnabled = true
    }
}
