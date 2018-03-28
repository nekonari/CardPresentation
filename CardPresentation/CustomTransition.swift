//
//  CustomTransition.swift
//  CardPresentation
//
//  Created by Peter Park on 3/27/18.
//  Copyright © 2018 Peter Park. All rights reserved.
//

import UIKit

protocol CustomTransitionEnabled {
    /// Return an instance of UIScrollView to have CustomInteractiveTransitioning take it into account when initiating interactive dismissal.
    var customTransitionScrollView: UIScrollView? { get }
    var canScroll: Bool { get }
}

/// Provide custom transition delegate. You can override this class to provide your own objects for customizing different parts of view controller transitions.
class CustomTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    init(with viewController: UIViewController, interactiveTransition: CustomInteractiveTransitioning? = nil) {
        self.viewController = viewController
        super.init()
        
        if let interactiveTransition = interactiveTransition {
            interactiveTransitionController = interactiveTransition
        }
    }
    
    private(set) weak var viewController: UIViewController!
    private(set) lazy var interactiveTransitionController: CustomInteractiveTransitioning = {
        return CustomPercentDrivenInteractiveTransition(with: viewController)
    }()
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return nil
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return CustomPresentationTransitionAnimator()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return CustomDismissalTransitionAnimator()
    }
    
    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactiveTransitionController.isInteractionInProgress ? interactiveTransitionController : nil
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactiveTransitionController.isInteractionInProgress ? interactiveTransitionController : nil
    }
}

protocol CustomInteractiveTransitioning: UIViewControllerInteractiveTransitioning {
    /// Return true if user is trying to transition interactively.
    var isInteractionInProgress: Bool { get }
}

class CustomPercentDrivenInteractiveTransition: UIPercentDrivenInteractiveTransition, CustomInteractiveTransitioning, UIGestureRecognizerDelegate {
    var isInteractionInProgress: Bool = false
    
    init(with viewController: UIViewController) {
        super.init()
        
        self.viewController = viewController
        
        let dismissalGestureRecognizer = UIPanGestureRecognizer()
        dismissalGestureRecognizer.delegate = self
        dismissalGestureRecognizer.addTarget(self, action: #selector(handleDismissalGesture(_:)))
        viewController.view?.addGestureRecognizer(dismissalGestureRecognizer)
    }
    
    private weak var viewController: UIViewController?
    
    @objc private func handleDismissalGesture(_ sender: UIPanGestureRecognizer) {
        print((self.viewController as? CustomTransitionEnabled)?.customTransitionScrollView?.contentOffset.y)
        print((self.viewController as? CustomTransitionEnabled)?.canScroll)
        guard sender.view === self.viewController?.view, !((self.viewController as? CustomTransitionEnabled)?.canScroll ?? false) else { return }
        
        switch sender.state {
        case .began:
            isInteractionInProgress = true
            viewController?.presentingViewController?.dismiss(animated: true, completion: nil)
            pause()
        case .changed:
            let percent = sender.translation(in: viewController?.view).y / (viewController?.view?.bounds.height ?? UIScreen.main.bounds.height)
            let cleanPercent = (percent * 10000.0).rounded(.up) / 10000.0
            update(cleanPercent)
        default:
            isInteractionInProgress = false
            let percent = sender.translation(in: viewController?.view).y / (viewController?.view?.bounds.height ?? UIScreen.main.bounds.height)
            if percent > 0.5 {
                finish()
            } else {
//                (viewController as? CustomTransitionEnabled)?.customTransitionScrollView?.isScrollEnabled = true
                cancel()
            }
        }
    }
    
    // MARK: UIGestureRecognizerDelegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Setup interactive dismissal to work with scroll view
        guard let vc = viewController as? CustomTransitionEnabled,
            let scrollView = vc.customTransitionScrollView
            else { return false }
        
        return otherGestureRecognizer.view === scrollView
    }
}

private class CustomPresentationTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
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

private class CustomDismissalTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
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
