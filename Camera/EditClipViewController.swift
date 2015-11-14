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
    @IBOutlet weak var textInputTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Edit clip view controller did load")
        
        setUpTextInput()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setUpTextInput() {
        textInputTextField.hidden = true
    }
    
    func showTextInput() {
        print("showing text input")
        textInputTextField.hidden = false
        textInputTextField.becomeFirstResponder()
    }
    
    func hideTextInput() {
        let characterCount = textInputTextField.text?.characters.count
        
        print("hiding text field")
        textInputTextField.hidden = true
        textInputTextField.endEditing(true)
        
        if characterCount == 0 {
            // dismiss
        } else {
            // add text to view
        }
    }
    
    @IBAction func toggleTextInput(sender: AnyObject) {
        print(textInputTextField.hidden)
        textInputTextField.hidden ? showTextInput() : hideTextInput()
    }
}
