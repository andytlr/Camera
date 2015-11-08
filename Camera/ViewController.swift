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
    
    let captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer?
    var captureDevice: AVCaptureDevice?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        captureSession.sessionPreset = AVCaptureSessionPresetLow
        let devices = AVCaptureDevice.devices()
        
        print(devices)
        
        // Loop through all the capture devices on this phone
        for device in devices {
            // Make sure this particular device supports video
            if (device.hasMediaType(AVMediaTypeVideo)) {
                // Finally check the position and confirm we've got the back camera
                if(device.position == AVCaptureDevicePosition.Back) {
                    captureDevice = device as? AVCaptureDevice
                }
            }
        }
        
        if captureDevice != nil {
            beginSession()
        }
        
    }
    
    func beginSession() {
        
        do {
//            configureDevice()
            captureSession.addInput(try AVCaptureDeviceInput(device: captureDevice!))
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            self.view.layer.addSublayer(previewLayer!)
            previewLayer?.frame = self.view.layer.frame
            captureSession.startRunning()
            
        } catch let err as NSError {
            print(err)
        }
        
    }
    
//    func configureDevice() {
//        if let device = captureDevice {
//            do {
//                try device.lockForConfiguration()
//            } catch {
//                return
//            }
//            
//            device.focusMode = .Locked
//            device.unlockForConfiguration()
//        }
//    }

}

