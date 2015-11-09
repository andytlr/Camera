//
//  ViewController.swift
//  Camera
//
//  Created by Andy Taylor on 11/7/15.
//  Copyright © 2015 Andy Taylor. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var switchButton: UIButton!
    
    var usingbackCamera: Bool = true
    var captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer?
    var captureDevice: AVCaptureDevice?
    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    
    
    let stillImageOutput = AVCaptureStillImageOutput()
    let audioOutput = AVCaptureAudioDataOutput()
    let videoOutput = AVCaptureVideoDataOutput()
    let devices = AVCaptureDevice.devices()
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setButtonLabel()
        
//        let backCamera = devices[0] as? AVCaptureDevice
//        let frontCamera = devices[1] as? AVCaptureDevice
//        let microphone = devices[2] as? AVCaptureDevice
//        print(backCamera)
//        print(frontCamera)
//        print(microphone)
        
        if backCamera != nil {
            beginSession(backCamera!)
        }
        
        if frontCamera == nil {
            switchButton.alpha = 0
        }
    }
    
    func setButtonLabel() {
        if usingbackCamera == true {
            switchButton.setTitle("Selfie", forState: UIControlState.Normal)
        } else {
            switchButton.setTitle("Backie", forState: UIControlState.Normal)
        }
    }
    
    func setupCamera() {
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        
        recordButton.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.2)
        recordButton.layer.cornerRadius = 40;
        recordButton.clipsToBounds = true;
        recordButton.layer.borderWidth = 2;
        recordButton.layer.borderColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5).CGColor
        
        // Loop through all the capture devices on this phone
        for device in devices {
            // Make sure this particular device supports video
            if device.hasMediaType(AVMediaTypeVideo) {
                // Finally check the position and confirm we've got the back camera
                if device.position == AVCaptureDevicePosition.Back {
                    backCamera = device as? AVCaptureDevice
                }
                if device.position == AVCaptureDevicePosition.Front {
                    frontCamera = device as? AVCaptureDevice
                }
            }
            if device.hasMediaType(AVMediaTypeAudio) {
                print(device)
            }
        }
    }
    
    func endSession() {
        previewLayer?.removeFromSuperlayer()
        captureSession.stopRunning()
        captureSession = AVCaptureSession()
    }
    
    func beginSession(device: AVCaptureDevice) {
        
        do {
            captureSession.addInput(try AVCaptureDeviceInput(device: device))
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            self.cameraView.layer.addSublayer(previewLayer!)
            previewLayer?.frame = self.view.layer.frame
            captureSession.startRunning()
            
            stillImageOutput.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
            if captureSession.canAddOutput(stillImageOutput) {
                captureSession.addOutput(stillImageOutput)
            }
            
        } catch let err as NSError {
            print(err)
        }
        
    }
    
    @IBAction func tapSwitchButton(sender: AnyObject) {
        if usingbackCamera == true {
            endSession()
            beginSession(frontCamera!)
            usingbackCamera = false
            setButtonLabel()
        } else {
            endSession()
            beginSession(backCamera!)
            usingbackCamera = true
            setButtonLabel()
        }
    }
    
    @IBAction func tapButton(sender: AnyObject) {
        cameraView.alpha = 0
        delay(0.085) {
            self.cameraView.alpha = 1
        }
        if let videoConnection = stillImageOutput.connectionWithMediaType(AVMediaTypeVideo) {
            stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection) {
                (imageDataSampleBuffer, error) -> Void in
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                UIImageWriteToSavedPhotosAlbum(UIImage(data: imageData)!, nil, nil, nil)
            }
        }
    }

}

