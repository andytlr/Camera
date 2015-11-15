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
    @IBOutlet var textFieldPanGestureRecognizer: UIPanGestureRecognizer!
    
    var textFieldOrigin = CGPoint(x: 30, y: 385)
    var textFieldOriginalCenter: CGPoint!
    
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
    
    @IBAction func panText(sender: AnyObject) {
        let translation = sender.translationInView(view)
        
        if sender.state == .Began {
            textFieldOriginalCenter = textInputTextField.center
        } else if sender.state == .Changed {
            textInputTextField.center = CGPoint(
                x: textFieldOriginalCenter.x + translation.x,
                y: textFieldOriginalCenter.y + translation.y
            )
        } else if sender.state == .Ended {
        }
    }
    
    
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}