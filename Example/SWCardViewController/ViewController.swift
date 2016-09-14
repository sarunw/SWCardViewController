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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "presentPopup" {
            let cv = segue.destination as! SWCardViewController
            
            let storyboard = self.storyboard!
            let a = storyboard.instantiateViewController(withIdentifier: "A")
            let b = storyboard.instantiateViewController(withIdentifier: "B")
            let aa = storyboard.instantiateViewController(withIdentifier: "A")
            let bb = storyboard.instantiateViewController(withIdentifier: "B")
            cv.view.backgroundColor = UIColor.clear
            cv.modalPresentationStyle = .overCurrentContext
            cv.setViewControllers([a, b, aa, bb], animated: false)
            cv.cardSize = CGSize(width: 260, height: 400)
            cv.delegate = self
        }
    }
    
    // MARK: - SWCardViewControllerDelegate
    func cardViewControllerDidRemoveAllViewControllers(_ viewController: SWCardViewController) {
        self.dismiss(animated: true, completion: nil)
    }
    
}

