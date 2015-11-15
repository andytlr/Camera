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
        
        // Register for keyboard events
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillChangeFrameNotification, object: nil)
        
        // Set up UI
        setUpTextInput()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setUpTextInput() {
        textInputTextField.hidden = true
    }
    
    func keyboardWillShow(notification: NSNotification) {
        // TODO: get keyboard frame
    }
    
    func showTextInput() {
        print("showing text input")
        textInputTextField.frame.origin = CGPoint(x: 30, y: 345)
        textInputTextField.hidden = false
        textInputTextField.becomeFirstResponder()
    }
    
    func hideTextInput() {
        let text = textInputTextField.text!
        let characterCount = textInputTextField.text?.characters.count
        
        print("hiding text field")
        textInputTextField.hidden = true
        textInputTextField.endEditing(true)
        
        if characterCount == 0 {
            // No text entered
        } else {
            textInputTextField.text = ""
            commitText(text)
        }
    }
    
    func commitText(text: String) {
        print("commiting text: \(text)")
        
        let newTextField: UITextField = UITextField(frame: CGRect(x: 0, y: 0, width: 375, height: 100))
        newTextField.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
        newTextField.text = text
        
        self.view.addSubview(newTextField)
    }
    
    @IBAction func toggleTextInput(sender: AnyObject) {
        print(textInputTextField.hidden)
        textInputTextField.hidden ? showTextInput() : hideTextInput()
    }
}



