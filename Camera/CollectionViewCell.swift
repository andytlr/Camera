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
        
//        clipView.backgroundColor = UIColor.whiteColor()
    }
    
    @IBAction func tapDelete(sender: UIButton) {
        deleteSingleClip(clip)
        
        // This is temporary instead of removing the row.
        sender.enabled = false
    }
}
