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
    fileprivate var pointsOfInterest = [PointOfInterest]()
    private var listenerToken: PointOfInterest.Notifier.Token!

    override func viewDidLoad() {
        super.viewDidLoad()

        listenerToken = PointOfInterest.notifier.register(listener: poiListener, dispatchQueue: DispatchQueue.main)

        //printfonts()
    }

    func poiListener(poi: PointOfInterest, event: PointOfInterest.Notifier.Event) {
        
        switch event {
        case .added:
            pointsOfInterest.append(poi)
        case .updated:
            pointsOfInterest = pointsOfInterest.filter { $0.id != poi.id }
            pointsOfInterest.append(poi)
        case .removed:
            pointsOfInterest = pointsOfInterest.filter { $0.id != poi.id }
        }

        pointsOfInterest = pointsOfInterest.sorted { $0.coordinate.longitude < $1.coordinate.longitude }
        
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pointsOfInterest.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        cell.textLabel?.text = pointsOfInterest[indexPath.item].name
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
