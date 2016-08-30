//
//  UIViewExtensions.swift
//  Trail of History
//
//  Created by Robert Vaessen on 8/23/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import UIKit

public extension UIView {
    @IBInspectable public var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable public var borderColor: UIColor? {
        get {
            if let color = layer.borderColor {
                return UIColor(CGColor: color)
            }
            return nil
        }
        set {
            layer.borderColor = newValue?.CGColor
        }
    }
    
    @IBInspectable public var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
}
