//
//  MapOptionsViewController.swift
//  Trail of History
//
//  Created by Dagna Bieda on 5/19/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import UIKit

enum MapOptionsType: Int {
    case MapOverlay = 0
    case MapPins
}

class MapOptionsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var selectedOptions = [MapOptionsType]()

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("OptionCell")!
        let mapOptionsType = MapOptionsType(rawValue: indexPath.row)
        switch (mapOptionsType!) {
        case .MapOverlay:
            cell.textLabel!.text = "Map Overlay"
        case .MapPins:
            cell.textLabel!.text = "Attraction Pins"
        }

        if selectedOptions.contains(mapOptionsType!) {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.None
        }

        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        let mapOptionsType = MapOptionsType(rawValue: indexPath.row)
        if (cell!.accessoryType == UITableViewCellAccessoryType.Checkmark) {
            cell!.accessoryType = UITableViewCellAccessoryType.None
            // delete object
            selectedOptions = selectedOptions.filter { (currentOption) in currentOption != mapOptionsType}
        } else {
            cell!.accessoryType = UITableViewCellAccessoryType.Checkmark
            selectedOptions += [mapOptionsType!]
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}
