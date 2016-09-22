//
//  SlideUpTransitionAnimator.swift
//  RssReader
//
//  Created by Simon Ng on 4/5/15.
//  Copyright (c) 2015 AppCoda Limited. All rights reserved.
//

import Foundation

class SlideUpTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate {
    var isPresenting = false
    var duration = 0.5
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return duration
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        
        // Get reference to our fromView, toView and the container view
        let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey)!
        let toView = transitionContext.viewForKey(UITransitionContextToViewKey)!
        
        // Set up the transform we'll use in the animation
        let container = transitionContext.containerView()!
        let offScreenDown = CGAffineTransformMakeTranslation(0, container.frame.height)
        
        let shiftDown = CGAffineTransformMakeTranslation(0, 15)
        let scaleDown = CGAffineTransformScale(shiftDown, 0.95, 0.95)
        
        // Add both views to the container view
        if isPresenting {
            // Change the initial position of the toView
            toView.transform = offScreenDown

            container.addSubview(fromView)
            container.addSubview(toView)
        } else {
            container.addSubview(toView)
            container.addSubview(fromView)
        }
        
        // Perform the animation
        UIView.animateWithDuration(duration, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.8, options: [], animations: {
            
            if self.isPresenting {
                fromView.transform = scaleDown
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