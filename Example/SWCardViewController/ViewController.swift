//
//  ViewController.swift
//  SWCardViewController
//
//  Created by Sarun Wongpatcharapakorn on 08/05/2016.
//  Copyright (c) 2016 Sarun Wongpatcharapakorn. All rights reserved.
//

import UIKit
import SWCardViewController

class ViewController: UIViewController, SWCardViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "presentPopup" {
            let cv = segue.destinationViewController as! SWCardViewController
            
            let storyboard = self.storyboard!
            let a = storyboard.instantiateViewControllerWithIdentifier("A")
            let b = storyboard.instantiateViewControllerWithIdentifier("B")
            let aa = storyboard.instantiateViewControllerWithIdentifier("A")
            let bb = storyboard.instantiateViewControllerWithIdentifier("B")
            cv.view.backgroundColor = UIColor.clearColor()
            cv.modalPresentationStyle = .OverCurrentContext
            cv.setViewControllers([a, b, aa, bb], animated: false)
            cv.cardSize = CGSize(width: 260, height: 400)
            cv.delegate = self
        }
    }
    
    // MARK: - SWCardViewControllerDelegate
    func cardViewControllerDidRemoveAllViewControllers(viewController: SWCardViewController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}

