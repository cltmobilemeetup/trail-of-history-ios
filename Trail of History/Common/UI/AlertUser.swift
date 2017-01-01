//
//  AlertUser.swift
//  Trail of History
//
//  Created by Robert Vaessen on 12/28/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import UIKit

func alertUser(title: String?, body: String?) {
    if let topController = UIApplication.topViewController() {
        let alert = UIAlertController(title: title, message: body, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: nil))
        topController.present(alert, animated: false, completion: nil)
    }
}
