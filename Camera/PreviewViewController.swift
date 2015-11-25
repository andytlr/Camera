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
    @IBOutlet weak var deleteLabel: UILabel!
    @IBOutlet weak var keepLabel: UILabel!
    
    var cameraViewController: CameraViewController!
    
    let blackView = UIView()
    
    var player = AVPlayer()
    let playerLayer = AVPlayerLayer()
    
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
        
        deleteLabel.alpha = 0
        keepLabel.alpha = 0
        
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
            
            playerLayer.frame = view.bounds
            
            let URL = NSURL(fileURLWithPath: filePath)
            let videoAsset = AVAsset(URL: URL)
            let playerItem = AVPlayerItem(asset: videoAsset)
            player = AVPlayer(playerItem: playerItem)
            
            player.actionAtItemEnd = .None
            playerLayer.player = player
            playerLayer.backgroundColor = UIColor.clearColor().CGColor
            playerLayer.videoGravity = AVLayerVideoGravityResize
            previewView.layer.addSublayer(playerLayer)
            player.play()
            
//            player.muted = true
            
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
    
    func appWillEnterBackground() {
        player.pause()
    }
    
    func appDidEnterForeground() {
        player.play()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func killPreviewAndRestartCamera() {
        if self.cameraViewController.usingSound == true {
            if self.clip.type == "video" {
                self.cameraViewController.startMic()
            }
        }
        delay(0.2) {
            self.previewView.subviews.forEach({ $0.removeFromSuperview() })
            self.playerLayer.removeFromSuperlayer()
            self.previewView.transform = CGAffineTransformMakeDegreeRotation(0)
            self.blackView.removeFromSuperview()
            self.cameraViewController.showIcons()
            self.cameraViewController.recordButton.alpha = 1
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
            
            blackView.frame = self.view.bounds
            blackView.alpha = 0.85
            view.insertSubview(blackView, atIndex: 0)
        }
        if sender.state == .Changed {
            
            previewView.frame.origin.x = translation.x
            previewView.frame.origin.y = translation.y / 4
            
            let rotation = convertValue(translation.y, r1Min: 0, r1Max: view.frame.height, r2Min: 0, r2Max: 3)

            previewView.transform = CGAffineTransformMakeDegreeRotation(rotation)
            
            let makeTransparentOnPan = convertValue(abs(translation.x), r1Min: (view.frame.width / 8), r1Max: (view.frame.height / 2), r2Min: 0.85, r2Max: 0)
            
            var makeOpaqueOnPan = convertValue(abs(translation.x), r1Min: (view.frame.width / 8), r1Max: (view.frame.width / 5) * 3, r2Min: 0, r2Max: 0.95)
            
            let moveOnPan = convertValue(abs(translation.x), r1Min: (view.frame.width / 8), r1Max: (view.frame.width / 5) * 3, r2Min: 0, r2Max: 80)
            
            if makeOpaqueOnPan > 0.95 {
                makeOpaqueOnPan = 0.95
            }
            
            if translation.x > 0 {
                keepLabel.alpha = makeOpaqueOnPan
                deleteLabel.alpha = makeTransparentOnPan
                deleteLabel.transform = CGAffineTransformMakeTranslation(0, 0)
                keepLabel.transform = CGAffineTransformMakeTranslation(moveOnPan, 0)
            } else {
                deleteLabel.alpha = makeOpaqueOnPan
                keepLabel.alpha = makeTransparentOnPan
                keepLabel.transform = CGAffineTransformMakeTranslation(0, 0)
                deleteLabel.transform = CGAffineTransformMakeTranslation(moveOnPan * -1, 0)
            }
            
            blackView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: makeTransparentOnPan)
            
            if translation.x < 0 {
                view.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: makeOpaqueOnPan)
            } else {
                view.backgroundColor = UIColor(red: 98/255, green: 217/255, blue: 98/255, alpha: makeOpaqueOnPan)
            }
        }
        if sender.state == .Ended {
            
            let dismissDuration = Double(convertValue(abs(velocity.y), r1Min: 0, r1Max: 5000, r2Min: 0.2, r2Max: 0.05))
            
            if velocity.x > 1500 || translation.x > (view.frame.width / 3) * 2 {
                
                print("Keep Yo")
                player.pause()
                keepLabel.alpha = 1
                deleteLabel.alpha = 0
                view.backgroundColor = UIColor(red: 98/255, green: 217/255, blue: 98/255, alpha: 0.95)
                blackView.alpha = 0
                
                UIView.animateWithDuration(dismissDuration, animations: { () -> Void in
                    
                    self.previewView.frame.origin.x = self.view.frame.width * 1.3
                    self.keepLabel.transform = CGAffineTransformTranslate(self.keepLabel.transform, 0, 0)
                    self.keepLabel.frame.origin.x = (self.view.frame.width / 2) - (self.keepLabel.frame.width / 2)
                    
                    }, completion: { (Bool) -> Void in
                        
                        self.killPreviewAndRestartCamera()
                        
                        self.cameraViewController.updateButtonCount()
                })
                
            } else if velocity.x < -1500 || translation.x < ((view.frame.width / 3) * 2) * -1 {
                print("Delete Yo")
                player.pause()
                keepLabel.alpha = 0
                deleteLabel.alpha = 1
                view.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.95)
                blackView.alpha = 0
                
                UIView.animateWithDuration(dismissDuration, animations: { () -> Void in
                    
                    self.previewView.frame.origin.x = (self.view.frame.width * 1.3) * -1
                    self.deleteLabel.transform = CGAffineTransformTranslate(self.deleteLabel.transform, 0, 0)
                    self.deleteLabel.frame.origin.x = (self.view.frame.width / 2) - (self.deleteLabel.frame.width / 2)
                    
                    }, completion: { (Bool) -> Void in
                        
                        self.killPreviewAndRestartCamera()
                        
                        // Delete from documents directory
                        deleteClip(getAbsolutePathForFile(self.clip.filename))
                        
                        // Delete reference from DB
                        let realm = try! Realm()
                        try! realm.write {
                            realm.delete(self.clip)
                        }
                })
                
            } else {
                UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 5, options: [], animations: { () -> Void in
                    
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
