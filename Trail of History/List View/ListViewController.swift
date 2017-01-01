//
//  DummyListTableViewController.swift
//  Trail of History
//
//  Created by Robert Vaessen on 8/24/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import UIKit

class ListViewController: UICollectionViewController {

    fileprivate let poiCellReuseIdentifier = "PointOfInterestCell"
    fileprivate var pointsOfInterest = [PointOfInterest]()
    private var listenerToken: PointOfInterest.DatabaseNotifier.Token!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = UIView.fromNib("Title")
        navigationItem.titleView?.backgroundColor = UIColor.clear // It was set to an opaque color in the NIB so that the white, text images would be visible in the Interface Builder.
        navigationItem.rightBarButtonItem?.tintColor = UIColor.tohTerracotaColor() // TODO: We should be able to access the TOH custom colors in the Interface Builder

        let poiCellNib: UINib? = UINib(nibName: "PointOfInterestCell", bundle: nil)
        collectionView?.register(poiCellNib, forCellWithReuseIdentifier: poiCellReuseIdentifier)

        listenerToken = PointOfInterest.DatabaseNotifier.instance.register(listener: poiListener, dispatchQueue: DispatchQueue.main)
    }

    func poiListener(poi: PointOfInterest, event: PointOfInterest.DatabaseNotifier.Event) {
        
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
        
        collectionView?.reloadData()
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pointsOfInterest.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let poi = pointsOfInterest[indexPath.item]

        let poiCell = collectionView.dequeueReusableCell(withReuseIdentifier: poiCellReuseIdentifier, for: indexPath) as! PointOfInterestCell

        let imageView = UIImageView(image: poi.image)
        imageView.contentMode = .scaleToFill // or .scaleAspectFit, or .scaleAspectFill
        poiCell.backgroundView = imageView
        poiCell.nameLabel.text = poi.name
        poiCell.distanceLabel.text = poi.distanceToUser()
        
        return poiCell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Selected \(indexPath.item)")
        DetailView.instance.present(poi: pointsOfInterest[indexPath.item])
        collectionView.deselectItem(at: indexPath, animated: false)
    }

    @IBAction func unwind(_ segue:UIStoryboardSegue) {
    }

}

extension ListViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: CGFloat(UIScreen.main.bounds.width), height: CGFloat(120))
    }
}
