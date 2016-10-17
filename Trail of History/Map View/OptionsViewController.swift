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
                case CellIdentifier.Standard: return MKMapType.standard
                case CellIdentifier.Satellite: return MKMapType.satellite
                case CellIdentifier.Hybrid: return MKMapType.hybrid
                default: return nil
                }
            }
        }
        
        func getCell(_ table: UITableView) -> UITableViewCell? {
            for section in 0 ..< table.numberOfSections {
                for row in 0 ..< table.numberOfRows(inSection: section) {
                    let cell = table.cellForRow(at: IndexPath(row: row, section: section))!
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
        case .standard:
            CellIdentifier.Standard.getCell(tableView)?.accessoryType = .checkmark
        case .satellite:
            CellIdentifier.Satellite.getCell(tableView)?.accessoryType = .checkmark
        case .hybrid:
            CellIdentifier.Hybrid.getCell(tableView)?.accessoryType = .checkmark
        default:
            break
        }

        CellIdentifier.TrailRoute.getCell(tableView)?.accessoryType = delegate.trailRouteVisible ? .checkmark : .none
        CellIdentifier.Callouts.getCell(tableView)?.accessoryType = delegate.calloutsEnabled ? .checkmark : .none
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let cell = tableView.cellForRow(at: indexPath)!
        let identifier = CellIdentifier(rawValue: cell.reuseIdentifier!)!

        switch identifier {
        // Map Types
        case .Standard: fallthrough
        case .Satellite: fallthrough
        case .Hybrid:
            if cell.accessoryType == .none { // If the user taps the one that is already checked then there is nothing that needs to be done
                // Check the selected cell and uncheck the others.
                cell.accessoryType = .checkmark
                for id in [CellIdentifier.Standard, CellIdentifier.Satellite, CellIdentifier.Hybrid] where id != identifier {
                    id.getCell(tableView)?.accessoryType = .none
                }
                delegate.mapType = identifier.mapType!
            }

        // Map Features
        case .TrailRoute:
            cell.accessoryType = cell.accessoryType == .none ? .checkmark : .none
            delegate.trailRouteVisible = cell.accessoryType == .checkmark
        case .Callouts:
            cell.accessoryType = cell.accessoryType == .none ? .checkmark : .none
            delegate.calloutsEnabled = cell.accessoryType == .checkmark

        // Map Actions
        case .ZoomToTrail:
            delegate.zoomToTrail()
        case .ZoomToUser:
            delegate.zoomToUser()
        case .ZoomToBoth:
            delegate.zoomToBoth()
        }
        
        cell.isSelected = false // Don't leave it highlighted
    }

    @IBAction func dismiss(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension OptionsViewController: UIPopoverPresentationControllerDelegate {

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
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
