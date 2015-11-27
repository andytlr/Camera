//
//  Toasts.swift
//  Camera
//
//  Created by Andy Taylor on 11/22/15.
//  Copyright © 2015 Andy Taylor. All rights reserved.
//

import Foundation
import UIKit

func toastWithMessage(message: String, appendTo: UIView, timeShownInSeconds: Double = 1.5, destructive: Bool = false, accomodateStatusBar: Bool = false) {
    print(message)
    
    // Setup
    let padding: CGFloat = 15
    let fontSize: CGFloat = 18
    let lineHeight: CGFloat = 1.4
    var statusBarHeight: CGFloat = 0
    
    // Layout
    if accomodateStatusBar == true {
        statusBarHeight = 10
    }
    let toastHeight = ((fontSize * lineHeight) + (padding * 2))
    let toastView = UIView(frame: CGRectMake(0, 0, appendTo.frame.width, toastHeight + statusBarHeight))
    if destructive == false {
        toastView.backgroundColor = greenColor
    } else {
        toastView.backgroundColor = redColor
    }
    let toastMessage = UILabel(frame: CGRectMake(padding, padding + statusBarHeight, appendTo.frame.width - (padding * 2), fontSize * lineHeight))
    toastMessage.font = UIFont.systemFontOfSize(fontSize)
    toastMessage.textColor = UIColor.whiteColor()
    toastMessage.text = message
    toastMessage.textAlignment = NSTextAlignment.Center

    // Add Views
    appendTo.addSubview(toastView)
    toastView.addSubview(toastMessage)
    
    // Move Toast Out of View
    toastView.transform = CGAffineTransformMakeTranslation(0, toastHeight * -1)
    
    UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 10, options: [], animations: { () -> Void in
        
        // Slide it Down
        toastView.transform = CGAffineTransformTranslate(toastView.transform, 0, toastHeight)
        
        }) { (Bool) -> Void in
            
            // After a Delay
            delayForTimeInSeconds(timeShownInSeconds) {
                
                UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 10, options: [], animations: { () -> Void in
                    
                    // Slide it back up
                    toastView.transform = CGAffineTransformMakeTranslation(0, toastHeight * -1)
                    
                    }, completion: { (Bool) -> Void in
                        
                        // Kill it
                        toastView.removeFromSuperview()
                })
            }
    }
}

// Delay funtion needed
func delayForTimeInSeconds(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}