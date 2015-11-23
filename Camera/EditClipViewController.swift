//
//  EditClipViewController.swift
//  Camera
//
//  Created by Ben Ashman on 11/14/15.
//  Copyright © 2015 Andy Taylor. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import RealmSwift

class EditClipViewController: UIViewController, UITextFieldDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var clipView: UIView!
    @IBOutlet weak var overlayView: UIView!
    
//    @IBOutlet weak var drawingView: UIView!
//    @IBOutlet weak var drawingImageView: UIImageView!
//    @IBOutlet weak var temporaryDrawingImageView: UIImageView!
    
    @IBOutlet weak var textInputTextField: UITextField!
    @IBOutlet var textFieldPanGestureRecognizer: UIPanGestureRecognizer!
    @IBOutlet weak var doneButton: UIButton!
    
    var clip: Clip!
    
    var player = AVPlayer()
    var playerLayer = AVPlayerLayer()
    
    var textFieldOrigin = CGPoint(x: 20, y: 401)
    var textFieldNewPositionOrigin = CGPoint(x: 20, y: 401)
    
    var textFieldOriginalCenter: CGPoint!
    var textFieldScaleTransform: CGAffineTransform!
    
    // Drawing shit
    
    var drawingViewController: DrawingViewController!
//
//    var lastPoint: CGPoint!
//    var strokeWidth: CGFloat!
//    var strokeColor = UIColor.whiteColor()
//    var strokeOpacity: CGFloat!
//    var didSwipe: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textInputTextField.delegate = self
        textFieldPanGestureRecognizer.delegate = self
        
        // Register for keyboard events
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillChangeFrameNotification, object: nil)
        
        // Set up UI
        overlayView.backgroundColor = UIColor.clearColor()
        setUpTextInput()
        
        // Set up drawing shit
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        drawingViewController = storyboard.instantiateViewControllerWithIdentifier("DrawingViewController") as! DrawingViewController
        drawingViewController.editClipViewController = self
        
//        drawingView.hidden = true
        
//        strokeWidth = 8.0
//        strokeOpacity = 1.0
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)

        let filePath = getAbsolutePathForFile(clip.filename)
        
        if clip.type == "photo" {
            print("handling photo")
            
            let image = UIImage(contentsOfFile: filePath)
            let imageView = UIImageView(image: image)
            
            imageView.frame = self.view.bounds
            clipView.addSubview(imageView)
            
        } else if clip.type == "video" {
            print("handling video")
            
            // Set up player
            let videoAsset = AVAsset(URL: NSURL(fileURLWithPath: getAbsolutePathForFile(clip.filename)))
            let playerItem = AVPlayerItem(asset: videoAsset)
            
            player = AVPlayer(playerItem: playerItem)
            
            player.actionAtItemEnd = .None
            playerLayer.player = player
            playerLayer.frame = view.bounds
            playerLayer.backgroundColor = UIColor.clearColor().CGColor
            playerLayer.videoGravity = AVLayerVideoGravityResize
            
            clipView.layer.insertSublayer(playerLayer, below: overlayView.layer)
            
            player.play()
            
            // Notify when we reach the end so we can loop
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerDidReachEndNotificationHandler:", name: "AVPlayerItemDidPlayToEndTimeNotification", object: player.currentItem)
        }
    }
    
    func playerDidReachEndNotificationHandler(notification: NSNotification) {
        // Loop video
        let playerItem = notification.object as! AVPlayerItem
        playerItem.seekToTime(kCMTimeZero)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setUpTextInput() {
        textInputTextField.hidden = true
    }
    
    func keyboardWillShow(notification: NSNotification) {
        // TODO: get keyboard frame
    }
    
    func beginTextInput() {
        textInputTextField.hidden = false
        textInputTextField.alpha = 0
        textInputTextField.becomeFirstResponder()
        textInputTextField.frame.origin = CGPoint(x: textFieldOrigin.x, y: textFieldOrigin.y + 250)
        
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 10, options: [], animations: {
            self.textInputTextField.frame.origin = self.textFieldOrigin
            self.textInputTextField.alpha = 1
        }, completion: nil)
    }
    
    func endTextInput() {
        let characterCount = textInputTextField.text?.characters.count
        characterCount != 0 ? commitTextInput() : cancelTextInput()
    }
    
    func commitTextInput() {
        textInputTextField.endEditing(true)
    }
    
    func cancelTextInput() {
        self.textInputTextField.endEditing(true)
        
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 10, options: [], animations: {
            self.textInputTextField.frame.origin = CGPoint(x: self.textFieldOrigin.x, y: self.textFieldOrigin.y + 250)
            self.textInputTextField.alpha = 0
        }, completion: { (finished: Bool) -> Void in
            self.textInputTextField.hidden = true
        })
    }
    
    @IBAction func toggleTextInput(sender: AnyObject) {
        print(textInputTextField.hidden)
        textInputTextField.hidden ? beginTextInput() : endTextInput()
    }
    
    @IBAction func panText(sender: AnyObject) {
        let translation = sender.translationInView(view)
        
        if sender.state == .Began {
            textFieldOriginalCenter = textInputTextField.center
        } else if sender.state == .Changed {
            textInputTextField.center = CGPoint(
                x: textFieldOriginalCenter.x + translation.x,
                y: textFieldOriginalCenter.y + translation.y
            )
        } else if sender.state == .Ended {
            // Save new position
            textFieldNewPositionOrigin = textInputTextField.frame.origin
        }
    }
    
    @IBAction func pinchText(sender: AnyObject) {
        let scale = sender.scale as CGFloat
        
        if sender.state == .Changed {
            textFieldScaleTransform = CGAffineTransformMakeScale(scale, scale)
            textInputTextField.transform = textFieldScaleTransform
        }
    }
    
    @IBAction func rotateText(sender: AnyObject) {
        if sender.state == .Changed {
            textInputTextField.transform = CGAffineTransformRotate(textFieldScaleTransform, sender.rotation)
        }
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func beginEditingText(sender: AnyObject) {
        let characterCount = textInputTextField.text?.characters.count
        
        if characterCount > 0 {
            // Return to original position above keyboard
            UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 10, options: [], animations: {
                    self.textInputTextField.frame.origin = self.textFieldOrigin
            }, completion: nil)
        }
    }
    
    @IBAction func endEditingText(sender: AnyObject) {
        UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 10, options: [], animations: {
            self.textInputTextField.frame.origin = self.textFieldNewPositionOrigin
        }, completion: nil)
    }
    
    @IBAction func doneEditing(sender: AnyObject) {
        dismissViewControllerAnimated(false, completion: nil)
    }
    
    
    // MARK: UIGestureRecognizerDelegate
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // Drawing shit
    
    @IBAction func tappedDrawButton(sender: AnyObject) {
        showDrawingView()
    }
    
    
    func showDrawingView() {
        addChildViewController(drawingViewController)
        self.view.addSubview(drawingViewController.view)
        self.drawingViewController.didMoveToParentViewController(self)
    }
    
//    @IBAction func selectedColor(sender: AnyObject) {
//        print("selected color: \(sender.tag)")
//        
//        switch sender.tag {
//        case 0:
//            strokeColor = UIColor.redColor()
//        case 1:
//            strokeColor = UIColor.greenColor()
//        case 2:
//            strokeColor = UIColor.blueColor()
//        default:
//            strokeColor = UIColor.whiteColor()
//        }
//    }
    
//    @IBAction func clearDrawing(sender: AnyObject) {
//        self.drawingImageView.image = nil
//    }
    
//    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        didSwipe = false
//        
//        if let touch = touches.first {
//            print("touches began")
//            lastPoint = touch.locationInView(self.view)
//        }
//        
//        super.touchesBegan(touches, withEvent: event)
//    }
    
//    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        didSwipe = true
//        
//        if let touch = touches.first {
//            print("touches moved")
//            
//            let currentPoint = touch.locationInView(self.view)
//            
//            UIGraphicsBeginImageContext(self.view.frame.size)
//            
//            self.temporaryDrawingImageView.image?.drawInRect(CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height))
//            
//            CGContextMoveToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y)
//            CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), currentPoint.x, currentPoint.y)
//            CGContextSetLineCap(UIGraphicsGetCurrentContext(), CGLineCap.Round)
//            CGContextSetLineWidth(UIGraphicsGetCurrentContext(), strokeWidth)
//            CGContextSetStrokeColorWithColor(UIGraphicsGetCurrentContext(), strokeColor.CGColor)
//            CGContextSetBlendMode(UIGraphicsGetCurrentContext(), CGBlendMode.Normal)
//            
//            CGContextStrokePath(UIGraphicsGetCurrentContext())
//            self.temporaryDrawingImageView.image = UIGraphicsGetImageFromCurrentImageContext()
//            self.temporaryDrawingImageView.alpha = strokeOpacity
//            
//            UIGraphicsEndImageContext()
//            
//            lastPoint = currentPoint
//        }
//    }
    
//    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        if !didSwipe {
//            UIGraphicsBeginImageContext(self.view.frame.size)
//            
//            self.temporaryDrawingImageView.image?.drawInRect(CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height))
//            
//            CGContextSetLineCap(UIGraphicsGetCurrentContext(), CGLineCap.Round)
//            CGContextSetLineWidth(UIGraphicsGetCurrentContext(), strokeWidth)
//            CGContextSetStrokeColorWithColor(UIGraphicsGetCurrentContext(), strokeColor.CGColor)
//            CGContextMoveToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y)
//            CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y)
//            
//            CGContextStrokePath(UIGraphicsGetCurrentContext())
//            self.temporaryDrawingImageView.image = UIGraphicsGetImageFromCurrentImageContext()
//            
//            UIGraphicsEndImageContext()
//        }
//        
//        UIGraphicsBeginImageContext(self.drawingImageView.frame.size)
//        self.drawingImageView.image?.drawInRect(CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height))
//        self.temporaryDrawingImageView.image?.drawInRect(CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height))
//        self.temporaryDrawingImageView.alpha = strokeOpacity
//        
//        self.drawingImageView.image = UIGraphicsGetImageFromCurrentImageContext()
//        self.temporaryDrawingImageView.image = nil
//        
//        UIGraphicsEndImageContext()
//    }
}









