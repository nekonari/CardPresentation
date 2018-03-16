//
//  CardViewController.swift
//  CardPresentation
//
//  Created by Peter Park on 3/15/18.
//  Copyright © 2018 Peter Park. All rights reserved.
//

import UIKit

class CardViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func tappedCloseButton(_ sender: UIButton) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    override var transitioningDelegate: UIViewControllerTransitioningDelegate? =
}



class CardPresentationController: UIPresentationController {
    
}
