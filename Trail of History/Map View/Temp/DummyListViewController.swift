//
//  DummyListTableViewController.swift
//  Trail of History
//
//  Created by Robert Vaessen on 8/24/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import UIKit

class DummyListViewController: UITableViewController {

    fileprivate let cellReuseIdentifier = "POI Name"
    //fileprivate let poiNames = ["Captain Jack", "William Henry Blake", "Thomas Polk", "Thad Tate", "Jane Wilkes", "Thomas Sprate and King Haigler", "Emily King"]
    fileprivate var poiNames = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        PointOfInterest.getAll { poi in
            self.poiNames.append(poi.name)
            self.tableView.reloadData()
        }
        //printfonts()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return poiNames.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        cell.textLabel?.text = poiNames[(indexPath as NSIndexPath).row]
        return cell
    }

    @IBAction func unwind(_ segue:UIStoryboardSegue) {
    }

    func printfonts() {
        for family: String in UIFont.familyNames {
            print("\(family)")
            for names: String in UIFont.fontNames(forFamilyName: family) {
                print("== \(names)")
            }
        }
    }
}
