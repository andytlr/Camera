//
//  TestVideoViewController.swift
//  Camera
//
//  Created by Cody Evol on 11/26/15.
//  Copyright © 2015 Andy Taylor. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class TestVideoViewController: UIViewController {

    @IBOutlet weak var clipView: UIView!
    
    var player: AVPlayer!
    var playerLayer: AVPlayerLayer?

    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        
        let filePath = NSBundle.mainBundle().pathForResource("example_recording", ofType: "mov")
        let URL = NSURL(fileURLWithPath: filePath!)
        let videoAsset = AVAsset(URL: URL)
        let playerItem = AVPlayerItem(asset: videoAsset)
            
        playerLayer = AVPlayerLayer()
        playerLayer!.frame = clipView.bounds
        player = AVPlayer(playerItem: playerItem)
        player!.actionAtItemEnd = .None
        playerLayer!.player = player
        playerLayer!.backgroundColor = UIColor.clearColor().CGColor
        playerLayer!.videoGravity = AVLayerVideoGravityResize
        clipView.layer.addSublayer(playerLayer!)
        player!.play()
            
        }
}