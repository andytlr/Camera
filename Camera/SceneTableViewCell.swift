//
//  SceneTableViewCell.swift
//  Camera
//
//  Created by Cody Evol on 11/19/15.
//  Copyright © 2015 Andy Taylor. All rights reserved.
//

import UIKit
import RealmSwift

class SceneTableViewCell: UITableViewCell {

    @IBOutlet weak var SceneNumber: UILabel!
    @IBOutlet weak var SceneDuration: UILabel!
    @IBOutlet weak var clipView: UIView!
    
    var clip: Clip!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
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
