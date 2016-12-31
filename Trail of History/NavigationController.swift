//
//  NavigationController.swift
//  Trail of History
//
//  Created by Robert Vaessen on 8/24/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import UIKit

class NavigationController: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationBar.barTintColor = UIColor.tohGreyishBrownTwoColor()
    }
}
