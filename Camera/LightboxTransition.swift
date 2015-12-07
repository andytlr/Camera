//
//  LightboxTransition.swift
//  fbTransitionDemo
//
//  Created by Timothy Lee on 12/1/15.
//  Copyright © 2015 Timothy Lee. All rights reserved.
//

import UIKit

class LightboxTransition: BaseTransition {
    
    override func presentTransition(containerView: UIView, fromViewController: UIViewController, toViewController: UIViewController) {
        
        let toViewController = toViewController as! EditClipViewController
        
        toViewController.view.transform = CGAffineTransformMakeScale(0.6, 0.6)
        toViewController.doneButton.alpha = 0
        toViewController.addDrawingButton.alpha = 0
        
        UIView.animateWithDuration(duration, animations: {
            toViewController.view.transform = CGAffineTransformMakeScale(1, 1)
        }) { (finished: Bool) -> Void in
            toViewController.doneButton.alpha = 1
            toViewController.addDrawingButton.alpha = 1
            self.finish()
        }
    }
    
    override func dismissTransition(containerView: UIView, fromViewController: UIViewController, toViewController: UIViewController) {
        
        fromViewController.view.transform = CGAffineTransformMakeScale(1, 1)
        UIView.animateWithDuration(duration, animations: {
            fromViewController.view.transform = CGAffineTransformMakeScale(0.6, 0.6)
        }) { (finished: Bool) -> Void in
            self.finish()
        }
    }
    
}
