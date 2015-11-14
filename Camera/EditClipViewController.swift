//
//  EditClipViewController.swift
//  Camera
//
//  Created by Ben Ashman on 11/14/15.
//  Copyright © 2015 Andy Taylor. All rights reserved.
//

import UIKit

class EditClipViewController: UIViewController {

    @IBOutlet weak var clipView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("Edit clip view controller did load")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func showTextInput(sender: AnyObject) {
        print("showing text input")
    }
}
