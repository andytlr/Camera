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
import RealmSwift

class PreviewViewController: UIViewController {
    
    @IBOutlet weak var previewView: UIView!
    
    @IBOutlet weak var deleteIcon: UIImageView!
    @IBOutlet weak var keepIcon: UIImageView!
    
    var cameraViewController: CameraViewController!
    
    let blackView = UIView()
    
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    
    var audioVolume = AVAudioSession.sharedInstance().outputVolume
    var timer: NSTimer?
    
    var clip: Clip!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "appWillEnterBackground", name: UIApplicationWillResignActiveNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "appDidEnterForeground", name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        let realm = try! Realm()
        clip = realm.objects(Clip).last!
        
        view.backgroundColor = UIColor.clearColor()
        previewView.backgroundColor = UIColor.clearColor()
        
        deleteIcon.alpha = 0
        keepIcon.alpha = 0
        
        let filePath = getAbsolutePathForFile(clip.filename)
        
        if clip.type == "photo" {
            
            let image = UIImage(contentsOfFile: filePath)!
            let imageView = UIImageView(image: image)
            
            // Conditionally use lines below to mirror preview a selfie.
            
//            let mirrorImage = UIImage(CGImage: image.CGImage!, scale: 1.0, orientation: .LeftMirrored)
//            let imageView = UIImageView(image: mirrorImage)
            
            imageView.frame = self.view.bounds
            previewView.addSubview(imageView)
            
        } else if clip.type == "video" {
            
            let URL = NSURL(fileURLWithPath: filePath)
            let videoAsset = AVAsset(URL: URL)
            let playerItem = AVPlayerItem(asset: videoAsset)
            
            playerLayer = AVPlayerLayer()
            playerLayer!.frame = view.bounds
            player = AVPlayer(playerItem: playerItem)
            player!.actionAtItemEnd = .None
            playerLayer!.player = player
            playerLayer!.backgroundColor = UIColor.clearColor().CGColor
            playerLayer!.videoGravity = AVLayerVideoGravityResize
            previewView.layer.addSublayer(playerLayer!)
            player!.play()
            // Perhaps here if the volume changes I could unmute.
            player!.muted = true
            audioVolume = AVAudioSession.sharedInstance().outputVolume
            
            timer = NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: "setTimeout", userInfo: nil, repeats: true)
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerDidReachEndNotificationHandler:", name: "AVPlayerItemDidPlayToEndTimeNotification", object: player!.currentItem)
        }
    }
    
    func setTimeout(){
        if audioVolume != AVAudioSession.sharedInstance().outputVolume {
            player!.muted = false
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func playerDidReachEndNotificationHandler(notification: NSNotification) {
        let playerItem = notification.object as! AVPlayerItem
        playerItem.seekToTime(kCMTimeZero)
    }
    
    func appWillEnterBackground() {
//        player.pause()
    }
    
    func appDidEnterForeground() {
//        player.play()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func killPreviewAndRestartCamera() {
        
        timer!.invalidate()
        
        if self.clip.type == "video" {
//            self.cameraViewController.startMic()
        }
        delay(0.1) {
            self.playerLayer!.removeFromSuperlayer()
            self.player = nil
            self.playerLayer = nil
            self.previewView.transform = CGAffineTransformMakeDegreeRotation(0)
            self.blackView.removeFromSuperview()
            self.cameraViewController.showIcons()
            self.cameraViewController.recordButton.alpha = 1
            self.cameraViewController.totalTimeLabel.alpha = 1
            self.cameraViewController.progressBar.progress = 0
            self.view.removeFromSuperview()
        }
    }
    
    @IBAction func panPreviewView(sender: UIPanGestureRecognizer) {
        
        let translation = sender.translationInView(view)
        let velocity = sender.velocityInView(view)
        
        if sender.state == .Began {
            view.backgroundColor = UIColor.clearColor()
            previewView.backgroundColor = UIColor.clearColor()
            
            let maskImage = CALayer()
            maskImage.frame = CGRectMake(0, 0, view.frame.width, view.frame.height)
            maskImage.backgroundColor = UIColor.blackColor().CGColor
            maskImage.cornerRadius = 8
            previewView.layer.mask = maskImage
            
            blackView.frame = self.view.bounds
            blackView.alpha = 0.85
            view.insertSubview(blackView, atIndex: 0)
        }
        if sender.state == .Changed {
            
            previewView.frame.origin.x = translation.x
            previewView.frame.origin.y = translation.y
            
            let rotation = convertValue(translation.x, r1Min: 0, r1Max: view.frame.height, r2Min: 0, r2Max: 10)

            previewView.transform = CGAffineTransformMakeDegreeRotation(rotation)
            
            let makeTransparentOnPan = convertValue(abs(translation.x), r1Min: (view.frame.width / 8), r1Max: (view.frame.height / 2), r2Min: 0.6, r2Max: 0)
            
            var makeOpaqueOnPan = convertValue(abs(translation.x), r1Min: keepIcon.frame.width, r1Max: (view.frame.width / 5) * 3, r2Min: 0, r2Max: 0.95)
            
            let moveOnPan = convertValue(abs(translation.x), r1Min: (view.frame.width / 8), r1Max: (view.frame.width / 5) * 3, r2Min: -23, r2Max: view.frame.width / 6)
            
            if makeOpaqueOnPan > 0.95 {
                makeOpaqueOnPan = 0.95
            }
            
            if translation.x > 0 {
                keepIcon.alpha = makeOpaqueOnPan
                deleteIcon.transform = CGAffineTransformMakeTranslation(0, 0)
                keepIcon.transform = CGAffineTransformMakeTranslation(moveOnPan, 0)
            } else {
                deleteIcon.alpha = makeOpaqueOnPan
                keepIcon.transform = CGAffineTransformMakeTranslation(0, 0)
                deleteIcon.transform = CGAffineTransformMakeTranslation(moveOnPan * -1, 0)
            }
            
            if translation.x < 0 {
                keepIcon.alpha = 0
            }
            
            if translation.x > 0 {
                deleteIcon.alpha = 0
            }
            
            blackView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(makeTransparentOnPan)
            
            if translation.x < 0 {
                view.backgroundColor = redColor.colorWithAlphaComponent(makeOpaqueOnPan)
            } else {
                view.backgroundColor = greenColor.colorWithAlphaComponent(makeOpaqueOnPan)
            }
        }
        if sender.state == .Ended {
            
            previewView.layer.mask = nil
            
            let dismissDuration = Double(convertValue(abs(velocity.y), r1Min: 0, r1Max: 150, r2Min: 0.3, r2Max: 0.1))
            
            if velocity.x > 500 && translation.x > 0 || translation.x > (view.frame.width / 3) * 2 {
                
                print("Keep Yo")
                player!.pause()
                keepIcon.alpha = 1
                deleteIcon.alpha = 0
                view.backgroundColor = greenColor.colorWithAlphaComponent(0.95)
                blackView.alpha = 0
                
                UIView.animateWithDuration(dismissDuration, animations: { () -> Void in
                    
                    self.previewView.frame.origin.x = self.view.frame.width * 1.3
                    self.previewView.frame.origin.y += translation.y
                    self.keepIcon.transform = CGAffineTransformTranslate(self.keepIcon.transform, 0, 0)
                    self.keepIcon.frame.origin.x = (self.view.frame.width / 2) - (self.keepIcon.frame.width / 2)
                    
                    }, completion: { (Bool) -> Void in
                        
                        self.killPreviewAndRestartCamera()
                        
                        self.cameraViewController.updateButtonCount()
                })
                
            } else if velocity.x < -500 && translation.x < 0 || translation.x < ((view.frame.width / 3) * 2) * -1 {
                print("Delete Yo")
                player!.pause()
                keepIcon.alpha = 0
                deleteIcon.alpha = 1
                view.backgroundColor = redColor.colorWithAlphaComponent(0.95)
                blackView.alpha = 0
                
                UIView.animateWithDuration(dismissDuration, animations: { () -> Void in
                    
                    self.previewView.frame.origin.x = (self.view.frame.width * 1.3) * -1
                    self.previewView.frame.origin.y += translation.y
                    self.deleteIcon.transform = CGAffineTransformTranslate(self.deleteIcon.transform, 0, 0)
                    self.deleteIcon.frame.origin.x = (self.view.frame.width / 2) - (self.deleteIcon.frame.width / 2)
                    
                    }, completion: { (Bool) -> Void in
                        
                        self.killPreviewAndRestartCamera()
                        
                        // Put both actions on the main thread so they happen subsequently
                        dispatch_async(dispatch_get_main_queue()) {
                            deleteSingleClip(self.clip)
//                            self.cameraViewController.totalTimeLabel.text = totalDurationInSeconds
                            self.cameraViewController.updateButtonCount()
                            updateTotalTime()
                        }
                })
                
            } else {
                UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 5, options: [], animations: { () -> Void in
                    
                    self.previewView.transform = CGAffineTransformMakeDegreeRotation(0)
                    self.previewView.frame.origin.x = 0
                    self.previewView.frame.origin.y = 0
                    
                    }, completion: { (Bool) -> Void in
                        
                        self.blackView.removeFromSuperview()
                })
            }
        }
    }
}
