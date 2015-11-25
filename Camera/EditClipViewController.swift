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
    @IBOutlet weak var textView: UIView!
    @IBOutlet weak var overlayView: UIView!
    
    @IBOutlet weak var drawingView: UIView!
    @IBOutlet weak var temporaryDrawingImageView: UIImageView!
    @IBOutlet weak var drawingImageView: UIImageView!
    
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
    
    var drawingViewController: DrawingViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textInputTextField.delegate = self
        textFieldPanGestureRecognizer.delegate = self
        
        // Register for keyboard events
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillChangeFrameNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "appWillEnterBackground", name: UIApplicationWillResignActiveNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "appDidEnterForeground", name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        // Set up UI
        overlayView.backgroundColor = UIColor.clearColor()
        setUpTextInput()
        
        // Set up drawing shit
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        drawingViewController = storyboard.instantiateViewControllerWithIdentifier("DrawingViewController") as! DrawingViewController
        drawingViewController.editClipViewController = self
        
        print(clip)
    }
    
    func appWillEnterBackground() {
        player.pause()
    }
    
    func appDidEnterForeground() {
        player.play()
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
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)

        // Show overlay if we have one
        if clip.overlay != nil {
            drawingImageView.image = UIImage(data: clip.overlay!)
        }
        
        // Show text overlay if we have one
        if clip.textLayer != nil {
            textInputTextField.text = clip.textLayer?.text
            textInputTextField.frame = CGRectFromString((clip.textLayer?.frame)!)
            textInputTextField.hidden = false
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
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
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
        let realm = try! Realm()
        
        try! realm.write {
            if self.textInputTextField.text != "" {
                let textLayer = TextLayer()
                textLayer.text = self.textInputTextField.text
                textLayer.frame = NSStringFromCGRect(self.textInputTextField.frame)
                
                self.clip.textLayer = textLayer
            }
            
            if self.drawingImageView.image != nil {
                let overlayData = UIImagePNGRepresentation(self.drawingImageView.image!)
                self.clip.overlay = overlayData
            }
        }
        
        player.pause()
        dismissViewControllerAnimated(false, completion: nil)
    }
    
    // MARK: UIGestureRecognizerDelegate
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // Drawing shit
    
    @IBAction func tappedDrawButton(sender: AnyObject) {
        if drawingViewController.view.superview == self.view {
            hideDrawingView()
        } else {
            showDrawingView()
        }
    }
    
    func showDrawingView() {
        addChildViewController(drawingViewController)
        view.insertSubview(drawingViewController.view, belowSubview: overlayView)
        drawingViewController.didMoveToParentViewController(self)
    }
    
    func hideDrawingView() {
        UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseIn, animations: {
            self.drawingViewController.colorBar.frame.origin.x = UIScreen.mainScreen().bounds.size.width
            self.drawingViewController.clearButton.alpha = 0
            self.drawingViewController.clearButton.transform = CGAffineTransformMakeScale(0, 0)
            }, completion: { Bool -> Void in
                self.drawingViewController.view.removeFromSuperview()
            }
        )
    }
}









