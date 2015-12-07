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
    
    var clip: Clip!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        clipView.layer.cornerRadius = 5
        clipView.clipsToBounds = true
        clipView.backgroundColor = UIColor.whiteColor()
        
        sceneDuration.layer.cornerRadius = 15
        sceneDuration.clipsToBounds = true
    }
    
    @IBAction func tapDelete(sender: UIButton) {
        deleteSingleClip(clip)
        
        // This is temporary instead of removing the row.
        sender.enabled = false
    }
}
