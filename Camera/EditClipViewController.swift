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

class EditClipViewController: UIViewController, UITextFieldDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var clipView: UIView!
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var textInputTextField: UITextField!
    @IBOutlet var textFieldPanGestureRecognizer: UIPanGestureRecognizer!
    @IBOutlet weak var doneButton: UIButton!
    
    var clipURL: NSURL!
    
    var player = AVPlayer()
    var playerLayer = AVPlayerLayer()
    
    var textFieldOrigin = CGPoint(x: 20, y: 401)
    var textFieldNewPositionOrigin = CGPoint(x: 20, y: 401)
    
    var textFieldOriginalCenter: CGPoint!
    var textFieldScaleTransform: CGAffineTransform!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textInputTextField.delegate = self
        textFieldPanGestureRecognizer.delegate = self
        
        // Register for keyboard events
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillChangeFrameNotification, object: nil)
        
        // Set up UI
        overlayView.backgroundColor = UIColor.clearColor()
        setUpTextInput()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        let exampleVideoURL = NSBundle.mainBundle().URLForResource("example_recording", withExtension: "mov")!
        let examplePhotoURL = NSBundle.mainBundle().pathForResource("example_photo", ofType: ".jpg")!
        
        // Our actual file path once everything's working
        let filePath = String(clipURL)
        
        // Get file extension
        let fileExtensionIndex = filePath.endIndex.advancedBy(-4)
        let fileExtension = filePath[Range(start: fileExtensionIndex, end: filePath.endIndex)]
        
        if fileExtension == ".jpg" || fileExtension == ".png" {
            print("handling photo")
            
            let image = UIImage(contentsOfFile: filePath)
            let imageView = UIImageView(image: image)
            print(image)
            
            imageView.frame = self.view.bounds
            imageView.backgroundColor = UIColor.blueColor()
            clipView.addSubview(imageView)
            
        } else if fileExtension == ".mov" {
            print("handling video")
            
            // Set up player
            let videoAsset = AVAsset(URL: clipURL)
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
}