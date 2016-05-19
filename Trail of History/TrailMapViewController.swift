//
//  TrailMapViewController.swift
//  Trail of History
//
//  Created by Dagna Bieda on 5/19/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import UIKit
import MapKit

enum MapType: Int {
    case Standard = 0
    case Hybrid
    case Satellite
}

class TrailMapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapTypeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var mapView: MKMapView!

    //var trail = Trail(filename: "TrailOfHistoryGeo")
    var selectedOptions = [MapOptionsType]()

    // MARK: VCLifecycle
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        // Implement starting with mapView.region that contains the trail
    }

    func loadSelectedOptions() {
        // To be iplemented ...
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let optionsViewController = segue.destinationViewController as! MapOptionsViewController
        optionsViewController.selectedOptions = selectedOptions
    }

    @IBAction func closeOptions(exitSegue: UIStoryboardSegue) {
        let optionsViewController = exitSegue.sourceViewController as! MapOptionsViewController
        selectedOptions = optionsViewController.selectedOptions
        self.loadSelectedOptions()
    }
    
    @IBAction func mapTypeChanged(sender: AnyObject) {
        // To be implemented
    }
}
