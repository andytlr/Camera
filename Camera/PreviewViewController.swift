//
//  PreviewViewController.swift
//  Camera
//
//  Created by Andy Taylor on 11/14/15.
//  Copyright © 2015 Andy Taylor. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class PreviewViewController: UIViewController {

    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var discardButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    
    let blackView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        
        let cameraRoll = returnContentsOfDocumentsDirectory()
        
        let latestItemInCameraRoll = String(cameraRoll.last!)
        
        let uiImageFriendlyUrl = latestItemInCameraRoll.stringByReplacingOccurrencesOfString("file:///private", withString: "")
        
        let avPlayerLayerFriendlyString = latestItemInCameraRoll.stringByReplacingOccurrencesOfString("/private", withString: "")
        
        let avPlayerLayerFriendlyUrl = NSURL(string: avPlayerLayerFriendlyString)
        
        let bundleVideoUrl = NSBundle.mainBundle().URLForResource("example_recording", withExtension: "mov")
        
        let latestFileFileExtensionIndex = latestItemInCameraRoll.endIndex.advancedBy(-4)
        
        let latestFileFileExtension = latestItemInCameraRoll[Range(start: latestFileFileExtensionIndex, end: latestItemInCameraRoll.endIndex)]
        
        if latestFileFileExtension == ".jpg" {
            
            let image = UIImage(contentsOfFile: uiImageFriendlyUrl)!
            let imageView = UIImageView(image: image)
            
            // Conditionally use lines below to mirror preview a selfie.
            
//            let mirrorImage = UIImage(CGImage: image.CGImage!, scale: 1.0, orientation: .LeftMirrored)
//            let imageView = UIImageView(image: mirrorImage)
            
            imageView.frame = self.view.bounds
            previewView.addSubview(imageView)
            
        } else if latestFileFileExtension == ".mov" {
            
            let playerLayer = AVPlayerLayer()
            playerLayer.frame = view.bounds
            
//            let videoAsset = AVAsset(URL: avPlayerLayerFriendlyUrl!)
            let videoAsset = AVAsset(URL: bundleVideoUrl!)
            
            // These follow the same patter WTF
            print("avPlayerLayerURL: \(avPlayerLayerFriendlyUrl!)")
            print("bundleVideoURL: \(bundleVideoUrl!)")
            
            let playerItem = AVPlayerItem(asset: videoAsset)
            
            let player = AVPlayer(playerItem: playerItem)
            
            player.actionAtItemEnd = .None
            playerLayer.player = player
            playerLayer.backgroundColor = UIColor.purpleColor().CGColor
            playerLayer.videoGravity = AVLayerVideoGravityResize
            previewView.layer.addSublayer(playerLayer)
            player.play()
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerDidReachEndNotificationHandler:", name: "AVPlayerItemDidPlayToEndTimeNotification", object: player.currentItem)
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func playerDidReachEndNotificationHandler(notification: NSNotification) {
        let playerItem = notification.object as! AVPlayerItem
        playerItem.seekToTime(kCMTimeZero)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func panPreviewView(sender: UIPanGestureRecognizer) {
        
        let translation = sender.translationInView(view)
//        let velocity = sender.velocityInView(view)
        
        if sender.state == .Began {
            view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
            discardButton.alpha = 0
            acceptButton.alpha = 0
            
            blackView.frame = self.view.bounds
            view.insertSubview(blackView, atIndex: 0)
        }
        if sender.state == .Changed {
            print("translation x \(abs(translation.x))")
            print("translation y \(abs(translation.y))")
            
            previewView.frame.origin.x = translation.x
            previewView.frame.origin.y = translation.y
            
            let makeTransparentOnPan = convertValue(abs(translation.y), r1Min: 0, r1Max: view.frame.height, r2Min: 1, r2Max: 0)
            
            let makeOpaqueOnPan = convertValue(abs(translation.y), r1Min: 0, r1Max: view.frame.height, r2Min: 0.7, r2Max: 1)
            
            blackView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: makeTransparentOnPan)
            
            if translation.y > 0 {
                view.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: makeOpaqueOnPan)
            } else {
                view.backgroundColor = UIColor(red: 98/255, green: 217/255, blue: 98/255, alpha: makeOpaqueOnPan)
            }
        }
        if sender.state == .Ended {
            
            if abs(translation.y) > (view.frame.height / 2) {
                print("Accept Yo")
            } else {
                UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 10, options: [], animations: { () -> Void in
                    
                    self.previewView.frame.origin.x = 0
                    self.previewView.frame.origin.y = 0
                    
                    }, completion: { (Bool) -> Void in
                        
                        self.blackView.removeFromSuperview()
                        self.discardButton.alpha = 1
                        self.acceptButton.alpha = 1
                })
            }
        }
    }
    
    @IBAction func tapAcceptButton(sender: UIButton) {
        view.removeFromSuperview()
    }

    @IBAction func tapDiscardButton(sender: UIButton) {
        view.removeFromSuperview()
        
        // Need to delete the latest file here
    }
}
