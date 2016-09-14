//
//  OptionsViewController.swift
//  Trail of History
//
//  Created by Robert Vaessen on 9/9/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import UIKit
import MapKit

protocol OptionsViewControllerDelegate: class {
    var mapType: MKMapType { get set }
    var trailRouteVisible: Bool { get set }
    var calloutsEnabled: Bool { get set }
    func zoomToTrail()
    func zoomToUser()
    func zoomToBoth()
}

class OptionsViewController: UITableViewController {

    enum CellIdentifier: String {
        case Standard
        case Satellite
        case Hybrid
        
        case TrailRoute
        case Callouts
        
        case ZoomToTrail
        case ZoomToUser
        case ZoomToBoth

        var mapType: MKMapType? {
            get {
                switch(self) {
                case CellIdentifier.Standard: return MKMapType.Standard
                case CellIdentifier.Satellite: return MKMapType.Satellite
                case CellIdentifier.Hybrid: return MKMapType.Hybrid
                default: return nil
                }
            }
        }
        
        func getCell(table: UITableView) -> UITableViewCell? {
            for section in 0 ..< table.numberOfSections {
                for row in 0 ..< table.numberOfRowsInSection(section) {
                    let cell = table.cellForRowAtIndexPath(NSIndexPath(forRow: row, inSection: section))!
                    if self == CellIdentifier(rawValue: cell.reuseIdentifier!) { return cell }
                }
            }
            return nil
        }
    }

    weak var delegate: OptionsViewControllerDelegate!

    override func viewDidLoad() {
        super.viewDidLoad()

        switch delegate.mapType {
        case .Standard:
            CellIdentifier.Standard.getCell(tableView)?.accessoryType = .Checkmark
        case .Satellite:
            CellIdentifier.Satellite.getCell(tableView)?.accessoryType = .Checkmark
        case .Hybrid:
            CellIdentifier.Hybrid.getCell(tableView)?.accessoryType = .Checkmark
        default:
            break
        }

        CellIdentifier.TrailRoute.getCell(tableView)?.accessoryType = delegate.trailRouteVisible ? .Checkmark : .None
        CellIdentifier.Callouts.getCell(tableView)?.accessoryType = delegate.calloutsEnabled ? .Checkmark : .None
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        let cell = tableView.cellForRowAtIndexPath(indexPath)!
        let identifier = CellIdentifier(rawValue: cell.reuseIdentifier!)!

        switch identifier {
        // Map Types
        case .Standard: fallthrough
        case .Satellite: fallthrough
        case .Hybrid:
            if cell.accessoryType == .None { // If the user taps the one that is already checked then there is nothing that needs to be done
                // Check the selected cell and uncheck the others.
                cell.accessoryType = .Checkmark
                for id in [CellIdentifier.Standard, CellIdentifier.Satellite, CellIdentifier.Hybrid] where id != identifier {
                    id.getCell(tableView)?.accessoryType = .None
                }
                delegate.mapType = identifier.mapType!
            }

        // Map Features
        case .TrailRoute:
            cell.accessoryType = cell.accessoryType == .None ? .Checkmark : .None
            delegate.trailRouteVisible = cell.accessoryType == .Checkmark
        case .Callouts:
            cell.accessoryType = cell.accessoryType == .None ? .Checkmark : .None
            delegate.calloutsEnabled = cell.accessoryType == .Checkmark

        // Map Actions
        case .ZoomToTrail:
            delegate.zoomToTrail()
        case .ZoomToUser:
            delegate.zoomToUser()
        case .ZoomToBoth:
            delegate.zoomToBoth()
        }
        
        cell.selected = false // Don't leave it highlighted
    }

    @IBAction func dismiss(sender: UIButton) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

extension OptionsViewController: UIPopoverPresentationControllerDelegate {

    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None
    }
/*
    func presentationController(controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        let navigationController = UINavigationController(rootViewController: controller.presentedViewController)
        let doneButton = UIBarButtonItem(title: "Done", style: .Done, target: self, action: #selector(dismiss))
        navigationController.topViewController!.navigationItem.rightBarButtonItem = doneButton
        return navigationController
    }
    
    func dismiss() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
*/
}
