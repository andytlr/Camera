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
    let stillImageOutput = AVCaptureStillImageOutput()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
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
            captureSession.addInput(try AVCaptureDeviceInput(device: captureDevice!))
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            self.view.layer.addSublayer(previewLayer!)
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
    
    @IBAction func tapButton(sender: AnyObject) {
        view.alpha = 0
        view.backgroundColor = UIColor.whiteColor()
        delay(0.1) {
            self.view.alpha = 1
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

