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
    var trailPathIsVisible: Bool { get set }
    var userLocationIsTracked: Bool { get set }
}

class OptionsViewController: UITableViewController {

    enum CellIdentifier: String {
        case Standard
        case Satellite
        case Hybrid
        
        case TrailPath
        case TrackUser
        
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

    weak var delegate: OptionsViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        CellIdentifier.Standard.getCell(tableView)?.accessoryType = .Checkmark
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        func processMapTypeSelection(cell: UITableViewCell, identifier: CellIdentifier) {
            // Ensure that the cell is a map type cell and that the user has not tapped the one that was previously selected (no need to process it again)
            guard let mapType = identifier.mapType where cell.accessoryType == .None else { return }
            
            // Check the selected cell and uncheck the others.
            cell.accessoryType = .Checkmark
            for id in [CellIdentifier.Standard, CellIdentifier.Satellite, CellIdentifier.Hybrid] where id != identifier {
                id.getCell(tableView)?.accessoryType = .None
            }

            delegate?.mapType = mapType
        }


        let cell = tableView.cellForRowAtIndexPath(indexPath)!
        let identifier = CellIdentifier(rawValue: cell.reuseIdentifier!)!

        switch identifier {
            case .Standard: fallthrough
            case .Satellite: fallthrough
            case .Hybrid:
                processMapTypeSelection(cell, identifier: identifier)

            case .TrailPath:
                cell.accessoryType = cell.accessoryType == .None ? .Checkmark : .None
                delegate?.trailPathIsVisible = cell.accessoryType == .Checkmark
 
            case .TrackUser:
                cell.accessoryType = cell.accessoryType == .None ? .Checkmark : .None
                delegate?.userLocationIsTracked = cell.accessoryType == .Checkmark
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
