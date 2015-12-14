//
//  CollectionViewCell.swift
//  Camera
//
//  Created by Andy Taylor on 11/30/15.
//  Copyright © 2015 Andy Taylor. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class CollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var clipView: UIView!
    @IBOutlet weak var sceneDuration: UILabel!
    
    var playerLayer: AVPlayerLayer!
    
    var clip: Clip!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        clipView.layer.cornerRadius = 5
        clipView.clipsToBounds = true
        clipView.backgroundColor = darkGreyColor
        
        sceneDuration.layer.cornerRadius = 15
        sceneDuration.clipsToBounds = true
        
        playerLayer = AVPlayerLayer()
        playerLayer!.frame = clipView.bounds
        playerLayer!.backgroundColor = UIColor.clearColor().CGColor
        playerLayer!.videoGravity = AVLayerVideoGravityResize
        clipView.layer.addSublayer(self.playerLayer!)
    }
}
