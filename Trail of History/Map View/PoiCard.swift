//
//  PoiCard.swift
//  Trail of History
//
//  Created by Robert Vaessen on 8/19/16.
//  Copyright © 2016 Robert Vaessen. All rights reserved.
//

import UIKit

class PoiCard: UICollectionViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    
    var name : String {
        get { return nameLabel.text ?? "<Unknown POI>" }
        set { nameLabel.text = newValue }
    }
}
