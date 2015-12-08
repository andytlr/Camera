//
//  DrawingViewController.swift
//  Camera
//
//  Created by Ben Ashman on 11/22/15.
//  Copyright © 2015 Andy Taylor. All rights reserved.
//

import UIKit
import RKColorSlider

class DrawingViewController: UIViewController {
    
    var editClipViewController: EditClipViewController!
    
    @IBOutlet weak var colorBar: RKColorSlider!
    @IBOutlet weak var clearButton: UIButton!
    
    var lastPoint: CGPoint!
    var strokeWidth: CGFloat!
    var strokeColor = UIColor.whiteColor()
    var strokeOpacity: CGFloat!
    var didSwipe: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        strokeWidth = 4.0
        strokeOpacity = 1.0
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        colorBar.frame.origin.x = UIScreen.mainScreen().bounds.size.width
        showColorBar()
        
        clearButton.alpha = 0
        clearButton.transform = CGAffineTransformMakeScale(0, 0)
        showClearButton()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showColorBar() {
        UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseOut, animations: {
            self.colorBar.frame.origin.x = UIScreen.mainScreen().bounds.size.width - 10
        }, completion: nil)
    }
    
    func showClearButton() {
        UIView.animateWithDuration(0.2, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [], animations: {
                self.clearButton.alpha = 1
                self.clearButton.transform = CGAffineTransformMakeScale(1, 1)
        }, completion: nil)
    }
    
    @IBAction func colorChanged(sender: RKColorSlider) {
        strokeColor = sender.selectedColor
    }
    
    @IBAction func clearDrawing(sender: AnyObject) {
        editClipViewController.drawingImageView.image = nil
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
            
            editClipViewController.temporaryDrawingImageView.image?.drawInRect(CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height))
            
            CGContextMoveToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y)
            CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), currentPoint.x, currentPoint.y)
            CGContextSetLineCap(UIGraphicsGetCurrentContext(), CGLineCap.Round)
            CGContextSetLineWidth(UIGraphicsGetCurrentContext(), strokeWidth)
            CGContextSetStrokeColorWithColor(UIGraphicsGetCurrentContext(), strokeColor.CGColor)
            CGContextSetBlendMode(UIGraphicsGetCurrentContext(), CGBlendMode.Normal)
            
            CGContextStrokePath(UIGraphicsGetCurrentContext())
            editClipViewController.temporaryDrawingImageView.image = UIGraphicsGetImageFromCurrentImageContext()
            editClipViewController.temporaryDrawingImageView.alpha = strokeOpacity
            
            UIGraphicsEndImageContext()
            
            lastPoint = currentPoint
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if !didSwipe {
            UIGraphicsBeginImageContext(self.view.frame.size)
            
            editClipViewController.temporaryDrawingImageView.image?.drawInRect(CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height))
            
            CGContextSetLineCap(UIGraphicsGetCurrentContext(), CGLineCap.Round)
            CGContextSetLineWidth(UIGraphicsGetCurrentContext(), strokeWidth)
            CGContextSetStrokeColorWithColor(UIGraphicsGetCurrentContext(), strokeColor.CGColor)
            CGContextMoveToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y)
            CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y)
            
            CGContextStrokePath(UIGraphicsGetCurrentContext())
            editClipViewController.temporaryDrawingImageView.image = UIGraphicsGetImageFromCurrentImageContext()
            
            UIGraphicsEndImageContext()
        }
        
        UIGraphicsBeginImageContext(editClipViewController.drawingImageView.frame.size)
        editClipViewController.drawingImageView.image?.drawInRect(CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height))
        editClipViewController.temporaryDrawingImageView.image?.drawInRect(CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height))
        editClipViewController.temporaryDrawingImageView.alpha = strokeOpacity
        
        editClipViewController.drawingImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        editClipViewController.temporaryDrawingImageView.image = nil
        
        UIGraphicsEndImageContext()
    }

}
