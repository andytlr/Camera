//
//  Toasts.swift
//  Camera
//
//  Created by Andy Taylor on 11/22/15.
//  Copyright © 2015 Andy Taylor. All rights reserved.
//

import Foundation
import UIKit

func toastWithMessage(message: String, negative: Bool = false, appendTo: UIView, accomodateStatusBar: Bool = false) {
    print(message)
    
    let padding = 15
    let fontSize = 18
    let lineHeight = 1.4
    var statusBarHeight = 10
    
    var toastHeight = ((CGFloat(fontSize) * CGFloat(lineHeight)) + (CGFloat(padding) * 2))
    
    if accomodateStatusBar == true {
        toastHeight += CGFloat(statusBarHeight)
//        statusBarHeight += 10
    }
    
    let toastView = UIView(frame: CGRectMake(0, 0, appendTo.frame.width, toastHeight))
    if negative == false {
        toastView.backgroundColor = UIColor(red: 98/255, green: 217/255, blue: 98/255, alpha: 1)
    } else {
        toastView.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
    }
    appendTo.addSubview(toastView)
    
    let toastMessage = UILabel(frame: CGRectMake(
        CGFloat(padding),
        CGFloat(padding) + CGFloat(statusBarHeight),
        (appendTo.frame.width) - (CGFloat(padding) * 2),
        (CGFloat(fontSize) * CGFloat(lineHeight))
    ))
    toastMessage.font = UIFont.systemFontOfSize(CGFloat(fontSize))
    toastMessage.textColor = UIColor.whiteColor()
    toastMessage.text = message
    toastMessage.textAlignment = NSTextAlignment.Center
    toastView.addSubview(toastMessage)
    
    toastView.transform = CGAffineTransformMakeTranslation(0, toastHeight * -1)
    
    UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 10, options: [], animations: { () -> Void in
        
        toastView.transform = CGAffineTransformTranslate(toastView.transform, 0, toastHeight)
        
        }) { (Bool) -> Void in
            
            delay(2) {
                
                UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 10, options: [], animations: { () -> Void in
                    
                    toastView.transform = CGAffineTransformMakeTranslation(0, toastHeight * -1)
                    
                    }, completion: { (Bool) -> Void in
                        
                        toastView.removeFromSuperview()
                })
            }
    }
}