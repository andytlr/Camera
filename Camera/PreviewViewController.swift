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
        
        
        let image = UIImage(contentsOfFile: uiImageFriendlyUrl)!
        let imageView = UIImageView(image: image)
        // Conditionally use lines below to mirror preview a selfie.
//        let mirrorImage = UIImage(CGImage: image.CGImage!, scale: 1.0, orientation: .LeftMirrored)
//        let imageView = UIImageView(image: mirrorImage)
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
