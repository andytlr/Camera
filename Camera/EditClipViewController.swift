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
    
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    
    var textFieldOriginalCenter: CGPoint!
    var textFieldScaleTransform: CGAffineTransform!
    
    var screenSize: CGRect = UIScreen.mainScreen().bounds
    
    var textFieldOrigin = CGPoint(x: 20, y: 20)
    var textFieldNewPositionOrigin = CGPoint(x: 20, y: 20)
    
    var blurView: UIVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
    
    var drawingViewController: DrawingViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textInputTextField.delegate = self
        textFieldPanGestureRecognizer.delegate = self
        
        // Register for keyboard events
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "appWillEnterBackground", name: UIApplicationWillResignActiveNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "appDidEnterForeground", name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        // Set up UI
        overlayView.backgroundColor = UIColor.clearColor()
        setUpTextInput()
        
        // Set up drawing shit
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        drawingViewController = storyboard.instantiateViewControllerWithIdentifier("DrawingViewController") as! DrawingViewController
        drawingViewController.editClipViewController = self
    }
    
    // For some unknown reason, pausing when the video goes into background and starting it again when it comes into the foreground is causing multiple instances of the audio to continue playing. If you're muted this is inaudible but the app will crash when you go back to the camera. For the moment I've commented out the .pause() and .play().
    
    func appWillEnterBackground() {
//        player.pause()
    }
    
    func appDidEnterForeground() {
//        player.play()
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
            
            player!.actionAtItemEnd = .None
            playerLayer = AVPlayerLayer()
            playerLayer!.player = player
            playerLayer!.frame = view.bounds
            playerLayer!.backgroundColor = UIColor.clearColor().CGColor
            playerLayer!.videoGravity = AVLayerVideoGravityResize
            
            clipView.layer.insertSublayer(playerLayer!, below: overlayView.layer)
            
            player!.play()
            
            // Notify when we reach the end so we can loop
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerDidReachEndNotificationHandler:", name: "AVPlayerItemDidPlayToEndTimeNotification", object: player!.currentItem)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        
        player!.pause()
        playerLayer!.removeFromSuperlayer()
        player = nil
        playerLayer = nil
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
        let playerItem = notification.object as! AVPlayerItem
        playerItem.seekToTime(kCMTimeZero)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setUpTextInput() {
        textInputTextField.hidden = true
        
        // Set default position
        let textFieldHeight = self.textInputTextField.frame.size.height
        let textFieldPadding = CGFloat(40)
        let textFieldStartY = screenSize.height - (textFieldHeight + textFieldPadding)
        textInputTextField.frame.origin = CGPoint(x: textInputTextField.frame.origin.x, y: textFieldStartY)
        
        // Customize placeholder
        let placeholderColor = UIColor.whiteColor()
        textInputTextField.attributedPlaceholder = NSAttributedString(string: "Type something…",
            attributes: [NSForegroundColorAttributeName: placeholderColor.colorWithAlphaComponent(0.3)])
    }
    
    // MARK: Blur
    
    func blurClip() {
        self.blurView.frame = self.clipView.frame
        self.view.insertSubview(self.blurView, aboveSubview: self.drawingView)
    }
    
    func focusClip() {
        self.blurView.removeFromSuperview()
    }
    
    // MARK: Keyboard Events
    
    func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let keyboardSize = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        
            // Get UIKeyboard animation values
            let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! Double
            let options = UIViewAnimationOptions(rawValue: UInt((userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).integerValue << 16))
            
            // Layout math
            let keyboardTop = screenSize.height - keyboardSize.size.height
            let textFieldHeight = self.textInputTextField.frame.size.height
            let textFieldPadding = CGFloat(20)
            let textFieldEndY = keyboardTop - (textFieldHeight + textFieldPadding)
            
            UIView.animateWithDuration(duration, delay: 0, options: options, animations: {
                self.textInputTextField.frame.origin = CGPoint(x: self.textFieldOrigin.x, y: textFieldEndY)
                self.textInputTextField.alpha = 1
            }, completion: nil)
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            // Get UIKeyboard animation values
            let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! Double
            let options = UIViewAnimationOptions(rawValue: UInt((userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).integerValue << 16))
            
            // Layout math
            let textFieldHeight = self.textInputTextField.frame.size.height
            let textFieldPadding = CGFloat(40)
            let textFieldEndY = screenSize.height - (textFieldHeight + textFieldPadding)
            
            UIView.animateWithDuration(duration, delay: 0, options: options, animations: {
                self.textInputTextField.frame.origin = CGPoint(x: self.textFieldOrigin.x, y: textFieldEndY)
                self.textInputTextField.alpha = 1
            }, completion: nil)
        }
    }
    
    // MARK: Begin/End Text Input
    
    func beginTextInput() {
        blurClip()
        textInputTextField.hidden = false
        textInputTextField.alpha = 0
        textInputTextField.becomeFirstResponder()
    }
    
    func endTextInput() {
        focusClip()
        
        let characterCount = textInputTextField.text?.characters.count
        characterCount != 0 ? commitTextInput() : cancelTextInput()
    }
    
    func commitTextInput() {
        print("commit text input")
        textInputTextField.endEditing(true)
    }
    
    func cancelTextInput() {
        self.textInputTextField.endEditing(true)
        
        // Layout math
        let textFieldHeight = self.textInputTextField.frame.size.height
        let textFieldPadding = CGFloat(40)
        let textFieldEndY = screenSize.height - (textFieldHeight + textFieldPadding)
        
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 10, options: [], animations: {
            self.textInputTextField.frame.origin = CGPoint(x: self.textFieldOrigin.x, y: textFieldEndY)
            self.textInputTextField.alpha = 0
        }, completion: { (finished: Bool) -> Void in
            self.textInputTextField.hidden = true
        })
    }
    
    @IBAction func toggleTextInput(sender: AnyObject) {
        print(textInputTextField.hidden)
        textInputTextField.hidden ? beginTextInput() : endTextInput()
    }
    
    // MARK: Manipulate Text Layer
    
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
//        let scale = sender.scale as CGFloat
//        
//        if sender.state == .Changed {
//            textFieldScaleTransform = CGAffineTransformMakeScale(scale, scale)
//            textInputTextField.transform = textFieldScaleTransform
//        }
    }
    
    @IBAction func rotateText(sender: AnyObject) {
//        if sender.state == .Changed {
//            textInputTextField.transform = CGAffineTransformRotate(textFieldScaleTransform, sender.rotation)
//        }
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        textField.endEditing(true)
        
        let characterCount = textInputTextField.text?.characters.count
        if characterCount == 0 {
            textInputTextField.hidden = true
        }
        
        return true
    }
    
    @IBAction func beginEditingText(sender: AnyObject) {
        blurClip()
        self.textFieldNewPositionOrigin = textInputTextField.frame.origin
    }
    
    @IBAction func endEditingText(sender: AnyObject) {
        focusClip()
    }
    
    @IBAction func doneEditing(sender: AnyObject) {
        let realm = try! Realm()
        
        try! realm.write {
            // Create new text layer
            if self.textInputTextField.text != "" {
                let textLayer = TextLayer()
                textLayer.text = self.textInputTextField.text
                textLayer.frame = NSStringFromCGRect(self.textInputTextField.frame)
                
                self.clip.textLayer = textLayer
            }
            
            // Clear existing text layer
            if self.clip.textLayer != nil && self.textInputTextField.text == "" {
                self.clip.textLayer = nil
            }
            
            // Create and update drawing layer
            if self.drawingImageView.image != nil {
                let overlayData = UIImagePNGRepresentation(self.drawingImageView.image!)
                self.clip.overlay = overlayData
            }
        }
        
        player!.pause()
        dismissViewControllerAnimated(false, completion: nil)
    }
    
    // MARK: UIGestureRecognizerDelegate
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // MARK: Shake
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if motion == .MotionShake {
            if self.textInputTextField.text != "" || self.drawingImageView.image != nil {
                let alert = UIAlertController(title: "Shake it off?", message: "Clear all text and drawings?", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Clear", style: .Default, handler: { action in
                    if action.style == .Default {
                        self.textInputTextField.text = ""
                        self.textInputTextField.endEditing(true)
                        self.textInputTextField.hidden = true
                        self.drawingImageView.image = nil
                    }
                }))
                
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: Drawing
    
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
