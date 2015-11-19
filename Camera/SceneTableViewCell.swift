//
//  SceneTableViewCell.swift
//  Camera
//
//  Created by Cody Evol on 11/19/15.
//  Copyright © 2015 Andy Taylor. All rights reserved.
//

import UIKit

class SceneTableViewCell: UITableViewCell {

    @IBOutlet weak var SceneNumber: UILabel!
    @IBOutlet weak var SceneDuration: UILabel!
    @IBOutlet weak var SceneClip: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
