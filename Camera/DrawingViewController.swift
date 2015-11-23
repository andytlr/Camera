//
//  DrawingViewController.swift
//  Camera
//
//  Created by Ben Ashman on 11/22/15.
//  Copyright © 2015 Andy Taylor. All rights reserved.
//

import UIKit

class DrawingViewController: UIViewController {
    
    var editClipViewController: EditClipViewController!
    
    @IBOutlet weak var temporaryDrawingImageView: UIImageView!
    @IBOutlet weak var drawingImageView: UIImageView!
    
    var lastPoint: CGPoint!
    var strokeWidth: CGFloat!
    var strokeColor = UIColor.whiteColor()
    var strokeOpacity: CGFloat!
    var didSwipe: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        strokeWidth = 8.0
        strokeOpacity = 1.0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func selectedColor(sender: AnyObject) {
        switch sender.tag {
        case 0:
            strokeColor = UIColor.redColor()
        case 1:
            strokeColor = UIColor.greenColor()
        case 2:
            strokeColor = UIColor.blueColor()
        default:
            strokeColor = UIColor.whiteColor()
        }
    }
    
    @IBAction func clearDrawing(sender: AnyObject) {
        self.drawingImageView.image = nil
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        didSwipe = false
        
        if let touch = touches.first {
            print("touches began")
            lastPoint = touch.locationInView(self.view)
        }
        
        super.touchesBegan(touches, withEvent: event)
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        didSwipe = true
        
        if let touch = touches.first {
            print("touches moved")
            
            let currentPoint = touch.locationInView(self.view)
            
            UIGraphicsBeginImageContext(self.view.frame.size)
            
            self.temporaryDrawingImageView.image?.drawInRect(CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height))
            
            CGContextMoveToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y)
            CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), currentPoint.x, currentPoint.y)
            CGContextSetLineCap(UIGraphicsGetCurrentContext(), CGLineCap.Round)
            CGContextSetLineWidth(UIGraphicsGetCurrentContext(), strokeWidth)
            CGContextSetStrokeColorWithColor(UIGraphicsGetCurrentContext(), strokeColor.CGColor)
            CGContextSetBlendMode(UIGraphicsGetCurrentContext(), CGBlendMode.Normal)
            
            CGContextStrokePath(UIGraphicsGetCurrentContext())
            self.temporaryDrawingImageView.image = UIGraphicsGetImageFromCurrentImageContext()
            self.temporaryDrawingImageView.alpha = strokeOpacity
            
            UIGraphicsEndImageContext()
            
            lastPoint = currentPoint
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if !didSwipe {
            UIGraphicsBeginImageContext(self.view.frame.size)
            
            self.temporaryDrawingImageView.image?.drawInRect(CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height))
            
            CGContextSetLineCap(UIGraphicsGetCurrentContext(), CGLineCap.Round)
            CGContextSetLineWidth(UIGraphicsGetCurrentContext(), strokeWidth)
            CGContextSetStrokeColorWithColor(UIGraphicsGetCurrentContext(), strokeColor.CGColor)
            CGContextMoveToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y)
            CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y)
            
            CGContextStrokePath(UIGraphicsGetCurrentContext())
            self.temporaryDrawingImageView.image = UIGraphicsGetImageFromCurrentImageContext()
            
            UIGraphicsEndImageContext()
        }
        
        UIGraphicsBeginImageContext(self.drawingImageView.frame.size)
        self.drawingImageView.image?.drawInRect(CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height))
        self.temporaryDrawingImageView.image?.drawInRect(CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height))
        self.temporaryDrawingImageView.alpha = strokeOpacity
        
        self.drawingImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        self.temporaryDrawingImageView.image = nil
        
        UIGraphicsEndImageContext()
    }

}
