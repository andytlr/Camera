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
        
        print("Image shown in view: \(latestItemInCameraRoll)")
        
        let fileExtensionIndex = latestItemInCameraRoll.endIndex.advancedBy(-4)
        let fileExtension = latestItemInCameraRoll[Range(start: fileExtensionIndex, end: latestItemInCameraRoll.endIndex)]
        
        if fileExtension == ".jpg" {
            
            let image = UIImage(contentsOfFile: uiImageFriendlyUrl)!
            let imageView = UIImageView(image: image)
            // Conditionally use lines below to mirror preview a selfie.
            //        let mirrorImage = UIImage(CGImage: image.CGImage!, scale: 1.0, orientation: .LeftMirrored)
            //        let imageView = UIImageView(image: mirrorImage)
            imageView.frame = self.view.bounds
            previewView.addSubview(imageView)
            
        } else if fileExtension == ".mov" {
            
            // This should be the most recently recorded file...
            //        let videoPath = NSURL(string: "\(documentsURL)\(currentTimeStamp()).mov")!
            
            // This is the example recording added to the app bundle.
            let videoPath = NSBundle.mainBundle().URLForResource("example_recording", withExtension: "mov")!
            
            print(videoPath)
            
            let playerLayer = AVPlayerLayer()
            playerLayer.frame = view.bounds
            
            let videoAsset = AVAsset(URL: videoPath)
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
        
    }

    @IBAction func tapDiscardButton(sender: UIButton) {
        view.removeFromSuperview()
        
        // Need to delete the latest file here
    }
}
