//
//  CardViewController.swift
//  CardPresentation
//
//  Created by Peter Park on 3/15/18.
//  Copyright © 2018 Peter Park. All rights reserved.
//

import UIKit

class CardViewController: UIViewController, CustomTransitionEnabled {
    
    init(embedding viewController: UIViewController) {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = cardPresentationTransition
        
        self.viewController = viewController
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(codeer:) has not been implemented.")
    }
    
    /// Embedded viewController.
    var viewController: UIViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChildViewController(viewController)
        view.addSubview(viewController.view)
        viewController.view.bounds = view.frame
        viewController.didMove(toParentViewController: self)
    }
    
    private lazy var cardPresentationTransition: CardTransitionDelegate = {
        return CardTransitionDelegate(with: self)
    }()
    
    // MARK: CustomTransitionEnabled
    
    var customTransitionScrollView: UIScrollView? {
        return (viewController as? CustomTransitionEnabled)?.customTransitionScrollView
    }
    
//    var canScroll: Bool {
//        return (viewController as? CustomTransitionEnabled)?.canScroll ?? false
//    }
}

class CardTransitionDelegate: CustomTransitionDelegate {
    override func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return CardPresentationController(presentedViewController: presented, presenting: presenting)
    }
}

/// This presentation controller will add animated dimming view as well as animating presenting view to scaled down position with rounded corners.
class CardPresentationController: UIPresentationController {
    private let shorterHeightPerc: CGFloat = 0.9
    
    override var presentedView: UIView? {
        let view = super.presentedView
        view?.clipsToBounds = true
        view?.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view?.layer.cornerRadius = 8.0
        return view
    }
    
    private let dimmingView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        return view
    }()
    
    private lazy var presentingView: UIView? = {
        let view = presentingViewController.view.snapshotView(afterScreenUpdates: false) ?? presentingViewController.view
        view?.clipsToBounds = true
        return view
    }()
    
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let rect = presentedView?.frame else { return .zero }
        
        return CGRect(x: rect.minX, y: rect.height * (1 - shorterHeightPerc), width: rect.width, height: rect.height * shorterHeightPerc)
    }
    
    override func presentationTransitionWillBegin() {
        // Percentage of the new height for the presentedVC
        
        guard let containerView = containerView,
            let presentvedView = presentedView else { return }
        
        // Background dimming view
        containerView.addSubview(dimmingView)
        dimmingView.frame = containerView.bounds
        containerView.addSubview(presentvedView)
        
        if let coordinator = presentingViewController.transitionCoordinator {
            dimmingView.alpha = 0.0
            coordinator.animate(alongsideTransition: { context in
                self.dimmingView.alpha = 0.2
            }, completion: nil)
        }
        
        // Presenting View Snapshot
        if let presentingView = presentingView {
            containerView.insertSubview(presentingView, belowSubview: dimmingView)
            presentingViewController.view?.isHidden = true
            
            let width = presentingView.frame.width - 16 - 16
            let height = width * (presentingView.frame.height / presentingView.frame.width)
            let presentingViewFinalRect = CGRect(x: 16, y: (containerView.bounds.height - height) / 2, width: width, height: height)
            
            if let coordinator = presentingViewController.transitionCoordinator {
                coordinator.animate(alongsideTransition: { context in
                    presentingView.frame = presentingViewFinalRect
                    presentingView.layer.cornerRadius = 8.0
                }, completion: nil)
            }
        }
    }
    
    override func dismissalTransitionWillBegin() {
        // Dimming view
        if let coordinator = presentingViewController.transitionCoordinator {
            coordinator.animate(alongsideTransition: { context in
                self.dimmingView.alpha = 0.0
            }, completion: { context in
                if !context.isCancelled {
                    self.dimmingView.removeFromSuperview()
                }
            })
        }
        
        // Restore presenting view
        if let coordinator = presentingViewController.transitionCoordinator {
            coordinator.animate(alongsideTransition: { context in
                self.presentingView?.frame = self.containerView?.frame ?? .zero
                self.presentingView?.layer.cornerRadius = 0.0
            }, completion: { context in
                if !context.isCancelled {
                    self.presentingViewController.view?.isHidden = false
                    self.presentingView?.removeFromSuperview()
                }
            })
        }
    }
    
    override var shouldRemovePresentersView: Bool {
        return false
    }
    
    override var shouldPresentInFullscreen: Bool {
        return false
    }
}
