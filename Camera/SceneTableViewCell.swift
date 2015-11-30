//
//  SceneTableViewCell.swift
//  Camera
//
//  Created by Cody Evol on 11/19/15.
//  Copyright © 2015 Andy Taylor. All rights reserved.
//

import UIKit
import RealmSwift
import AVFoundation

class SceneTableViewCell: UITableViewCell {

    @IBOutlet weak var sceneNumber: UILabel!
    @IBOutlet weak var sceneDuration: UILabel!
    @IBOutlet weak var clipView: UIView!
    
    var clip: Clip!
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        clipView.backgroundColor = UIColor.whiteColor()

        delay(0.25) {
            print(self.clip)
            
            let filePath = getAbsolutePathForFile(self.clip.filename)
            let URL = NSURL(fileURLWithPath: filePath)
            let videoAsset = AVAsset(URL: URL)
            let playerItem = AVPlayerItem(asset: videoAsset)
            
            self.playerLayer = AVPlayerLayer()
            self.playerLayer!.frame = self.clipView.bounds
            self.player = AVPlayer(playerItem: playerItem)
            self.player!.actionAtItemEnd = .None
            self.playerLayer!.player = self.player
            self.playerLayer!.backgroundColor = UIColor.clearColor().CGColor
            self.playerLayer!.videoGravity = AVLayerVideoGravityResize
            self.clipView.layer.addSublayer(self.playerLayer!)
            self.player!.pause()
            self.player!.muted = true
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerDidReachEndNotificationHandler:", name: "AVPlayerItemDidPlayToEndTimeNotification", object: self.player!.currentItem)
        }
    }
    
    func playerDidReachEndNotificationHandler(notification: NSNotification) {
        let playerItem = notification.object as! AVPlayerItem
        playerItem.seekToTime(kCMTimeZero)
    }
    
    @IBAction func tapDeleteButton(sender: UIButton) {
        deleteSingleClip(clip)
        
        // This is temporary instead of removing the row.
        sender.enabled = false
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
