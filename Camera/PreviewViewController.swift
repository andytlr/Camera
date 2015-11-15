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
    
    @IBAction func tapAcceptButton(sender: UIButton) {
        view.removeFromSuperview()
    }

    @IBAction func tapDiscardButton(sender: UIButton) {
        view.removeFromSuperview()
        
        // Need to delete the latest file here
    }
}
