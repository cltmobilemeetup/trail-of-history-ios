//
//  DetailViewController.swift
//  Trail of History
//
//  Created by Robert Vaessen on 12/30/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import UIKit

class DetailView {

    static let instance = DetailView()

    private var label: UILabel
    private let modalViewController: UIViewController
    
    private init() {
        label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        label.autoresizingMask = [.flexibleTopMargin, .flexibleRightMargin, .flexibleBottomMargin, .flexibleLeftMargin]
        label.numberOfLines = 0 // As many as needed
        label.lineBreakMode = .byWordWrapping
        label.backgroundColor = UIColor.white
        label.isUserInteractionEnabled = true
        label.layer.cornerRadius = 5
        label.layer.borderColor = UIColor.gray.cgColor
        label.layer.borderWidth = 1

        modalViewController = UIViewController()
        modalViewController.view = UIView()
        modalViewController.view.addSubview(label)
        modalViewController.view.backgroundColor = UIColor.clear
        modalViewController.modalPresentationStyle = .overCurrentContext

        label.addGestureRecognizer(UITapGestureRecognizer(target:self, action: #selector(dismiss(_:))))
    }

    func present(poi: PointOfInterest) {

        label.text = poi.description
        
        // Make the label fit the text by expanding the height, not the width
        let size = label.sizeThatFits(CGSize(width: label.frame.width, height: CGFloat.greatestFiniteMagnitude))
        var frame = label.frame;
        frame.size.height = size.height;
        label.frame = frame;
        
        let window = UIApplication.shared.delegate!.window!!
        let presentingViewController = window.visibleViewController!
        presentingViewController.present(modalViewController, animated: true, completion: nil)
    }
    
    @objc private func dismiss(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            modalViewController.dismiss(animated: false, completion: nil)
        }
    }
}
