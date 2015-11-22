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
    @IBOutlet weak var deleteLabel: UILabel!
    @IBOutlet weak var keepLabel: UILabel!
    
    var latestFileFileExtension: String!
    
    var cameraViewController: CameraViewController!
    
    let blackView = UIView()
    
    var player = AVPlayer()
    let playerLayer = AVPlayerLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        
        view.backgroundColor = UIColor.clearColor()
        previewView.backgroundColor = UIColor.clearColor()
        
        let cameraRoll = returnContentsOfTemporaryDocumentsDirectory()
        
        deleteLabel.alpha = 0
        keepLabel.alpha = 0
        
        let latestItemInCameraRoll = String(cameraRoll.last!)
        let latestFileName = cameraRoll.last!.lastPathComponent!
        
        let documentsDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
        let filePath = documentsDir.stringByAppendingPathComponent("/tmp/\(latestFileName)")
        
        // Dis string bullshit to get file type
        let latestFileFileExtensionIndex = latestItemInCameraRoll.endIndex.advancedBy(-4)
        latestFileFileExtension = latestItemInCameraRoll[Range(start: latestFileFileExtensionIndex, end: latestItemInCameraRoll.endIndex)]
        
        if latestFileFileExtension == ".jpg" {
            
            let image = UIImage(contentsOfFile: filePath)!
            let imageView = UIImageView(image: image)
            
            // Conditionally use lines below to mirror preview a selfie.
            
//            let mirrorImage = UIImage(CGImage: image.CGImage!, scale: 1.0, orientation: .LeftMirrored)
//            let imageView = UIImageView(image: mirrorImage)
            
            imageView.frame = self.view.bounds
            previewView.addSubview(imageView)
            
        } else if latestFileFileExtension == ".mov" {
            
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func killPreviewAndRestartCamera() {
        if self.cameraViewController.usingSound == true {
            if self.latestFileFileExtension == ".mov" {
                self.cameraViewController.restartMic()
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
            view.insertSubview(blackView, atIndex: 0)
        }
        if sender.state == .Changed {
            
            previewView.frame.origin.x = translation.x
            previewView.frame.origin.y = translation.y
            
            let rotation = convertValue(translation.x, r1Min: 0, r1Max: view.frame.width, r2Min: 0, r2Max: 10)

            previewView.transform = CGAffineTransformMakeDegreeRotation(rotation)
            
            let makeTransparentOnPan = convertValue(abs(translation.y), r1Min: (view.frame.height / 8), r1Max: (view.frame.height / 2), r2Min: 0.85, r2Max: 0)
            
            var makeOpaqueOnPan = convertValue(abs(translation.y), r1Min: (view.frame.height / 8), r1Max: (view.frame.height / 5) * 3, r2Min: 0, r2Max: 0.95)
            
            let moveOnPan = convertValue(abs(translation.y), r1Min: (view.frame.height / 8), r1Max: (view.frame.height / 5) * 3, r2Min: 0, r2Max: 80)
            
            if makeOpaqueOnPan > 0.95 {
                makeOpaqueOnPan = 0.95
            }
            
            if translation.y < 0 {
                keepLabel.alpha = makeOpaqueOnPan
                deleteLabel.alpha = makeTransparentOnPan
                keepLabel.transform = CGAffineTransformMakeTranslation(0, moveOnPan * -1)
            } else {
                deleteLabel.alpha = makeOpaqueOnPan
                keepLabel.alpha = makeTransparentOnPan
                deleteLabel.transform = CGAffineTransformMakeTranslation(0, moveOnPan)
            }
            
            blackView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: makeTransparentOnPan)
            
            if translation.y > 0 {
                view.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: makeOpaqueOnPan)
            } else {
                view.backgroundColor = UIColor(red: 98/255, green: 217/255, blue: 98/255, alpha: makeOpaqueOnPan)
            }
        }
        if sender.state == .Ended {
            
            let dismissDuration = Double(convertValue(abs(velocity.y), r1Min: 0, r1Max: 5000, r2Min: 0.5, r2Max: 0.1))
            
            let moveX = CGFloat(Double(convertValue(velocity.x, r1Min: 0, r1Max: 5000, r2Min: 0, r2Max: view.frame.width * 3 )))
            
            if velocity.y > 2000 || translation.y > (view.frame.height / 2) {
                print("Delete Yo")
                player.pause()
                keepLabel.alpha = 0
                deleteLabel.alpha = 1
                view.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.95)
                blackView.alpha = 0
                
                UIView.animateWithDuration(dismissDuration, animations: { () -> Void in
                    
                    self.previewView.frame.origin.y = self.view.frame.height * 1.3
                    self.previewView.frame.origin.x += moveX
                    self.deleteLabel.transform = CGAffineTransformTranslate(self.deleteLabel.transform, 0, 0)
                    self.deleteLabel.frame.origin.y = (self.view.frame.height / 2) - (self.deleteLabel.frame.height / 2)
                    
                    }, completion: { (Bool) -> Void in
                        
                        let cameraRoll = returnContentsOfTemporaryDocumentsDirectory()
                        let latestFileName = cameraRoll.last!.lastPathComponent!
                        removeItemFromDocumentsDirectory(latestFileName)
                        
                        self.killPreviewAndRestartCamera()
                })
                
            } else if velocity.y < -2000 || translation.y < (view.frame.height / 2) * -1 {
                print("Keep Yo")
                player.pause()
                keepLabel.alpha = 1
                deleteLabel.alpha = 0
                view.backgroundColor = UIColor(red: 98/255, green: 217/255, blue: 98/255, alpha: 0.95)
                blackView.alpha = 0
                
                UIView.animateWithDuration(dismissDuration, animations: { () -> Void in
                    
                    self.previewView.frame.origin.y = (self.view.frame.height * 1.3) * -1
                    self.previewView.frame.origin.x += moveX
                    self.keepLabel.transform = CGAffineTransformTranslate(self.keepLabel.transform, 0, 0)
                    self.keepLabel.frame.origin.y = (self.view.frame.height / 2) - (self.keepLabel.frame.height / 2)
                    
                    }, completion: { (Bool) -> Void in
                        
                        self.killPreviewAndRestartCamera()
                })
                
            } else {
                UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 10, options: [], animations: { () -> Void in
                    
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
