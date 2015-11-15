//
//  EditClipViewController.swift
//  Camera
//
//  Created by Ben Ashman on 11/14/15.
//  Copyright © 2015 Andy Taylor. All rights reserved.
//

import UIKit

class EditClipViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var clipView: UIView!
    @IBOutlet weak var textInputTextField: UITextField!
    
    var textFieldOrigin = CGPoint(x: 30, y: 385)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textInputTextField.delegate = self
        
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
    
    func beginTextInput() {
        print("showing text input")
        textInputTextField.frame.origin = textFieldOrigin
        textInputTextField.hidden = false
        textInputTextField.becomeFirstResponder()
    }
    
    func endTextInput() {
        let characterCount = textInputTextField.text?.characters.count
        characterCount != 0 ? commitTextInput() : cancelTextInput()
    }
    
    func commitTextInput() {
        textInputTextField.endEditing(true)
    }
    
    func cancelTextInput() {
        textInputTextField.hidden = true
        textInputTextField.endEditing(true)
    }
    
    @IBAction func toggleTextInput(sender: AnyObject) {
        print(textInputTextField.hidden)
        textInputTextField.hidden ? beginTextInput() : endTextInput()
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}