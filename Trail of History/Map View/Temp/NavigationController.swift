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


class NavigationControllerDelegate: NSObject, UINavigationControllerDelegate {
    
    func navigationControllerSupportedInterfaceOrientations(navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        return .Portrait
    }
}

class NavigationBar: UINavigationBar {

    override func sizeThatFits(size: CGSize) -> CGSize {
        return super.sizeThatFits(size)
    }
}