//
//  ViewController.swift
//  CardPresentation
//
//  Created by Peter Park on 3/15/18.
//  Copyright © 2018 Peter Park. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction func tappedPlainTransitionButton(_ sender: UIButton) {
        present(EmptyViewController(), animated: true, completion: nil)
    }
    
    @IBAction func tappedCardTransitionButton(_ sender: UIButton) {
        let embeddedVC = EmptyViewController()
        let cardVC = CardViewController(embedding: embeddedVC)
        present(cardVC, animated: true, completion: nil)
    }
    
    @IBAction func tappedScrollViewButton(_ sender: UIButton) {
        let scrollVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "scrollViewController") as! ScrollViewController
        let cardVC = CardViewController(embedding: scrollVC)
        present(cardVC, animated: true, completion: nil)
    }
    
}

class EmptyViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = #colorLiteral(red: 1, green: 0.8409949541, blue: 0.8371030092, alpha: 1)
        
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Close", for: .normal)
        button.setTitleColor(.blue, for: .normal)
        button.addTarget(self, action: #selector(tappedCloseButton(_:)), for: .touchUpInside)
        
        view.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16.0),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: 16.0)
            ])
    }
    
    @objc private func tappedCloseButton(_ sender: UIButton) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
}

class ScrollViewController: UIViewController, CustomTransitionEnabled {
    @IBOutlet var scrollView: UIScrollView!
    @IBAction private func tappedCloseButton(_ sender: UIButton) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: CustomTransitionEnabled
    var customTransitionScrollView: UIScrollView? {
        return scrollView
    }
    
    var canScroll: Bool {
        return scrollView.contentOffset.y > -150
    }
}
