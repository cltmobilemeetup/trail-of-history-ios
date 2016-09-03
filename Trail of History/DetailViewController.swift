//
//  DetailViewController.swift
//  Trail of History
//
//  Created by Matt Bryant on 9/3/16.
//  Copyright © 2016 CLT Mobile. All rights reserved.
//

import UIKit

class DetailViewController: UIPageViewController {
    
    // MARK: Properties
    
    private(set) lazy var orderedViewControllers: [UIViewController] = {
        return [self.loadViewController("alpha"),
                self.loadViewController("beta"),
                self.loadViewController("gamma"),
                self.loadViewController("delta")
                ]
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self
        
        if let firstViewController = orderedViewControllers.first {
            setViewControllers([firstViewController], direction: .Forward, animated: true, completion: nil)
        }
        
        
        
        
    }
    
    func loadViewController(id: String) -> UIViewController {
        return UIStoryboard(name: "Detail", bundle: nil) . instantiateViewControllerWithIdentifier("\(id)")
    }
    
    /*
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}


// MARK: Datasource
extension DetailViewController: UIPageViewControllerDataSource {
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        return nil
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        return nil
    }
}
