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

    @IBOutlet weak var sceneDuration: UILabel!
    @IBOutlet weak var clipView: UIView!
    
    var clip: Clip!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        clipView.backgroundColor = UIColor.whiteColor()
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
