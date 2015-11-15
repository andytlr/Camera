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
        
        let cameraRoll = returnContentsOfDocumentsDirectory()
        
        let latestItemInCameraRoll = String(cameraRoll.last!).stringByReplacingOccurrencesOfString("file:///private", withString: "")
        
        print(latestItemInCameraRoll)
        
        let image = UIImage(contentsOfFile: latestItemInCameraRoll)
        let imageView = UIImageView(image: image!)
        imageView.frame = self.view.bounds
        previewView.addSubview(imageView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func tapAcceptButton(sender: UIButton) {
        
    }

    @IBAction func tapDiscardButton(sender: UIButton) {
        view.removeFromSuperview()
        
        // Need to delete the latest file
    }
}
