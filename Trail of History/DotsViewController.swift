//
//  DotsViewController.swift
//  Trail of History
//
//  Created by Matt Bryant on 9/9/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import UIKit

class DotsViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var pageController: UIPageControl!
    
    @IBOutlet weak var containerView: UIView!
    
    var detailViewController: DetailViewController? {
        didSet {
            detailViewController?.dotsDelegate = self
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        pageController.addTarget(self, action: "didChangePageControlValue", forControlEvents: .ValueChanged)
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension DotsViewController: DetailViewControllerDelegate {
    
    func detailViewController(detailViewController: DetailViewController, didUpdatePageCount count: Int) {
        pageController.numberOfPages = count
    }
    
    func detailViewController(detailViewController: DetailViewController, didUpdatePageIndex index: Int) {
        pageController.currentPage = index
    }
}
