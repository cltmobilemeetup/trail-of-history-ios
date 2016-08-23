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
    
    public var viewController : UIViewController? {
        func findViewController(forResponder responder: UIResponder) -> UIViewController? {
            if let nextResponder = responder.nextResponder() {
                switch nextResponder {
                case is UIViewController:
                    return nextResponder as? UIViewController
                case is UIView:
                    return findViewController(forResponder: nextResponder)
                default:
                    break
                }
            }
            return nil
        }
        
        return findViewController(forResponder: self)
    }
}
