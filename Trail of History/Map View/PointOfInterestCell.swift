//
//  PointOfInterestCell.swift
//  Trail of History
//
//  Created by Robert Vaessen on 9/3/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import UIKit

protocol ShowDetailViewDelegate: class {
    func showDetailViewFor(cell: PointOfInterestCell)
}

class PointOfInterestCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    weak var showDetailViewDelegate: ShowDetailViewDelegate?

    @IBAction func detailDisclosure(sender: UIButton) {
        showDetailViewDelegate?.showDetailViewFor(self)
    }
}