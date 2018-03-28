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
//    var canScroll: Bool { get }
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
        guard sender.view === self.viewController?.view else { return }
        
        if let scrollView = (viewController as? CustomTransitionEnabled)?.customTransitionScrollView {
            let percent = max(0.0, sender.translation(in: viewController?.view).y / (viewController?.view?.bounds.height ?? UIScreen.main.bounds.height))
            let yVelocity = sender.velocity(in: viewController?.view).y
            
            print("percent = \(String(format: "%.2f", percent)), yV = \(String(format: "%.2f", yVelocity)), yOffset = \(String(format: "%.2f", scrollView.contentOffset.y))")
            
            switch sender.state {
            case .began:
//                if scrollView.contentOffset.y < 0.01 && yVelocity > 0 {
//                    scrollView.isScrollEnabled = false
//                    isInteractionInProgress = true
//                    pause()
//                } else {
//                    scrollView.isScrollEnabled = true
//                    isInteractionInProgress = false
//                }
                break
            case .changed:
//                switch (scrollView.contentOffset.y < 0.01, isInteractionInProgress, percent) {
//                    case
                    if yVelocity > 0 && !isInteractionInProgress {
                        print("1")
                        scrollView.isScrollEnabled = false
                        isInteractionInProgress = true
                        viewController?.presentingViewController?.dismiss(animated: true, completion: nil)
                        pause()
                    }
//                }
                if !isInteractionInProgress && percent == 0 {
                    print("2")
                    scrollView.isScrollEnabled = true
                    let offset = CGPoint(x: scrollView.contentOffset.x, y: -sender.translation(in: scrollView).y)
                    scrollView.setContentOffset(offset, animated: false)
                    isInteractionInProgress = false
                    cancel()
                }
                
                if isInteractionInProgress {
                    print("3")
                    update(percent)
                }
            case .ended:
                if isInteractionInProgress {
                    print("4")
                    isInteractionInProgress = false
                    scrollView.isScrollEnabled = true
                    if percent > 0.5 {
                        finish()
                    } else {
                        cancel()
                    }
                } else {
                    print("5")
                    cancel()
                }
            default:
                print("6")
                scrollView.isScrollEnabled = true
                isInteractionInProgress = false
                cancel()
            }
        } else {
            let percent = sender.translation(in: viewController?.view).y / (viewController?.view?.bounds.height ?? UIScreen.main.bounds.height)
            switch sender.state {
            case .began:
                isInteractionInProgress = true
                viewController?.presentingViewController?.dismiss(animated: true, completion: nil)
                pause()
            case .changed:
                update(percent)
            default:
                isInteractionInProgress = false
                if percent > 0.5 {
                    finish()
                } else {
                    cancel()
                }
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
