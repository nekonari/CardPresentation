//
//  CardViewController.swift
//  CardPresentation
//
//  Created by Peter Park on 3/15/18.
//  Copyright © 2018 Peter Park. All rights reserved.
//

import UIKit

class CardViewController: UIViewController {
    
    @IBOutlet var scrollView: UIScrollView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        dismissalGestureRecognizer.addTarget(self, action: #selector(handleDismissalGesture(_:)))
        view.addGestureRecognizer(dismissalGestureRecognizer)
        scrollView.isScrollEnabled = false
    }
    
    private let dismissalGestureRecognizer = UITapGestureRecognizer()
    private let interactiveTransitionController = UIPercentDrivenInteractiveTransition()

    @IBAction func tappedCloseButton(_ sender: UIButton) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @objc private func handleDismissalGesture(_ sender: UIGestureRecognizer) {
        guard sender === dismissalGestureRecognizer,
            let recognizer = sender as? UIPanGestureRecognizer
            else { return }
        
        switch recognizer.state {
        case .began:
            presentingViewController?.dismiss(animated: true, completion: nil)
            interactiveTransitionController.pause()
        case .changed:
            let percent = recognizer.translation(in: view.superview).y / (view.superview?.bounds.height ?? UIScreen.main.bounds.height)
            interactiveTransitionController.update(percent)
        default:
            let percent = recognizer.translation(in: view.superview).y / (view.superview?.bounds.height ?? UIScreen.main.bounds.height)
            if percent > 0 {
                interactiveTransitionController.finish()
            } else {
                interactiveTransitionController.cancel()
            }
        }
    }
}

extension CardViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return CardPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return CardPresentationAnimatedController()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return CardDismissalAnimatedController()
    }
    
    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactiveTransitionController
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactiveTransitionController
    }
}

private class CardPresentationAnimatedController: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let presentedView = transitionContext.view(forKey: .to) else { return }
        
        // Move presentedView to the starting position
        presentedView.frame.origin = CGPoint(x: 0, y: transitionContext.containerView.bounds.maxY)
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [.curveEaseInOut], animations: {
            if let vc = transitionContext.viewController(forKey: .to) {
                presentedView.frame = transitionContext.finalFrame(for: vc)
            } else {
                presentedView.frame = transitionContext.containerView.frame
            }
        }, completion: { completed in
            if completed {
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        })
    }
}

private class CardDismissalAnimatedController: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let presentedView = transitionContext.view(forKey: .from) else { return }
        
        if transitionContext.isInteractive {
            UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: [.curveLinear], animations: {
                presentedView.frame.origin.y = transitionContext.containerView.bounds.maxY
            }, completion: { completed in
                if completed {
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                }
            })
        } else {
            UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [.curveEaseInOut], animations: {
                presentedView.frame.origin.y = transitionContext.containerView.bounds.maxY
            }, completion: { completed in
                if completed {
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                }
            })
        }
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
