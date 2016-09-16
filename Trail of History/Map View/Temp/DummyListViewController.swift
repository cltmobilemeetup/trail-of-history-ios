//
//  DummyListTableViewController.swift
//  Trail of History
//
//  Created by Robert Vaessen on 8/24/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import UIKit

class DummyListViewController: UITableViewController {

    private let cellReuseIdentifier = "POI Name"
    private let poiNames = ["Captain Jack", "William Henry Blake", "Thomas Polk", "Thad Tate", "Jane Wilkes", "Thomas Sprate and King Haigler", "Emily King"]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //printfonts()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return poiNames.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellReuseIdentifier, forIndexPath: indexPath)
        cell.textLabel?.text = poiNames[indexPath.row]
        return cell
    }

    @IBAction func unwind(segue:UIStoryboardSegue) {
    }

    func printfonts() {
        for family: String in UIFont.familyNames() {
            print("\(family)")
            for names: String in UIFont.fontNamesForFamilyName(family) {
                print("== \(names)")
            }
        }
    }
}
