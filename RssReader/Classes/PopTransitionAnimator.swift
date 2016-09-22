//
//  PopTransitionAnimator.swift
//  RssReader
//
//  Created by Simon Ng on 4/6/15.
//  Copyright (c) 2015 AppCoda Limited. All rights reserved.
//

import UIKit

class PopTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate {
    var isPresenting = false
    var duration = 0.3
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return duration
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        // Get reference to our fromView, toView and the container view
//        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)
        let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey)!
        let toView = transitionContext.viewForKey(UITransitionContextToViewKey)!
        
        // Adapt for orientation changes
        toView.frame = fromView.bounds
        
        // Set up the transform we'll use in the animation
        let container = transitionContext.containerView()!
        let minimize = CGAffineTransformMakeScale(0, 0)
        let offScreenDown = CGAffineTransformMakeTranslation(0, container.frame.height)
        
        let shiftDown = CGAffineTransformMakeTranslation(0, 15)
        let scaleDown = CGAffineTransformScale(shiftDown, 0.95, 0.95)
        
        // Change the initial size of the toView
        if isPresenting {
            toView.layer.anchorPoint = CGPoint(x:0, y:0)
            toView.layer.position = CGPoint(x:0, y:0)
            toView.transform = minimize
        } else {
            toView.transform = scaleDown
        }
        
        // Add both views to the container view
        if isPresenting {
            container.addSubview(fromView)
            container.addSubview(toView)
        } else {
            container.addSubview(toView)
            container.addSubview(fromView)
        }
        
        // Perform the animation
        UIView.animateWithDuration(duration, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: .CurveEaseInOut, animations: {
            
            if self.isPresenting {
                fromView.alpha = 0.5
                toView.transform = CGAffineTransformIdentity
            } else {
                fromView.transform = offScreenDown
                toView.alpha = 1.0
                toView.transform = CGAffineTransformIdentity
            }
            
            }, completion: { finished in
                
                transitionContext.completeTransition(true)
                
        })
        
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isPresenting = false
        return self
    }
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isPresenting = true
        return self
    }
    
}

