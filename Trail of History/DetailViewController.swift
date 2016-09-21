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
    
    weak var dotsDelegate: DetailViewControllerDelegate?
    
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
        delegate = self
        
//        if let initialViewController = orderedViewControllers.first {
//            setViewControllers([initialViewController], direction: .Forward, animated: true, completion: nil)
//        }
        
        if let initialViewController = orderedViewControllers.first {
            scrollToViewController(initialViewController)
        }
        
        
        dotsDelegate?.detailViewController(self, didUpdatePageCount: orderedViewControllers.count)
        
        
    }
    
    func loadViewController(id: String) -> UIViewController {
        return UIStoryboard(name: "Detail", bundle: nil) . instantiateViewControllerWithIdentifier("\(id)")
    }
    
    // Scroll to the next view controller
    func scrollToNextViewController() {
        if let visibleViewController = viewControllers?.first,
            let nextViewController = pageViewController(self, viewControllerAfterViewController: visibleViewController) {
                scrollToViewController(nextViewController)
            
        }
    }
    
    // Scrolls to the view controller at the given index. Automatically calculates the direction.
    func scrollToViewController(index newIndex: Int) {
        if let firstViewController = viewControllers?.first,
            let currentIndex = orderedViewControllers.indexOf(firstViewController) {
                let direction: UIPageViewControllerNavigationDirection = newIndex >= currentIndex ? .Forward : .Reverse
                let nextViewController = orderedViewControllers[newIndex]
                scrollToViewController(nextViewController, direction: direction)
            
            }
    }
    
    // Scrolls to the given viewController page
    func scrollToViewController(viewController: UIViewController, direction: UIPageViewControllerNavigationDirection = .Forward) {
        setViewControllers([viewController], direction: direction, animated: true, completion: { (finished) -> Void in
            // Notify the tutorialDelegate about the new index
            self.notifyTutorialDelegateOfNewIndex()
        })
    }
    
    // Notifies tutorialDelegate that current page was updated
    func notifyTutorialDelegateOfNewIndex() {
        if let firstViewController = viewControllers?.first,
            let index = orderedViewControllers.indexOf(firstViewController) {
                dotsDelegate?.detailViewController(self, didUpdatePageIndex: index)
            }
    }
    
    
    /*
     func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
     return orderedViewControllers.count
     }
     
     func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
     guard let firstViewController = viewControllers?.first,
     firstViewControllerIndex = orderedViewControllers.indexOf(firstViewController) else {
     return 0
     }
     return firstViewControllerIndex
     }
     */
    
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
        guard let viewControllerIndex = orderedViewControllers.indexOf(viewController) else {
        return nil
        }
        
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return orderedViewControllers.last // return nil to deactivate loop
        }
        
        guard orderedViewControllers.count > previousIndex else {
            return nil
        }
        
        return orderedViewControllers[previousIndex]
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.indexOf(viewController) else {
        return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = orderedViewControllers.count
        
        guard orderedViewControllersCount != nextIndex else {
            return orderedViewControllers.first // return nil to deactivate loop
        }
        
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        
        return orderedViewControllers[nextIndex]
    }
    
 
}

extension DetailViewController: UIPageViewControllerDelegate {
    
    func pageViewController(pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool) {
        
        notifyTutorialDelegateOfNewIndex()
        
//        if let firstViewController = viewControllers?.first {
//            let index = orderedViewControllers.indexOf(firstViewController)
//        }
//
//        dotsDelegate?.detailViewController(self, didUpdatePageIndex: index)
        
    }
}


protocol DetailViewControllerDelegate: class {
    
    /**
        
    Called when the number of pages is updated
 
    - parameter detailViewController: the DetailViewController instance
    - parameter count: total number of pages
    */
    
    func detailViewController(detailPageViewController: DetailViewController,
                                  didUpdatePageCount count: Int)
    
    /**
 
    Called when the current index is updated
    
    - parameter detailViewController: the DetailViewController instance
    - parameter index: the index of the currently visible page
    */
    
    func detailViewController(detailViewController: DetailViewController, didUpdatePageIndex index: Int)
}
 
 
