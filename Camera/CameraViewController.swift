//
//  ViewController.swift
//  Camera
//
//  Created by Andy Taylor on 11/7/15.
//  Copyright © 2015 Andy Taylor. All rights reserved.
//

//import Foundation
import UIKit
import AVKit
import AVFoundation

class CameraViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    var previewViewController: PreviewViewController!
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var switchButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    
    var usingbackCamera: Bool = true
    var captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    var microphone: AVCaptureDevice?
    var micInput: AVCaptureDeviceInput?
    
    let stillImageOutput = AVCaptureStillImageOutput()
    let videoOutput = AVCaptureMovieFileOutput()
    let devices = AVCaptureDevice.devices()
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func restartMicAfterDismissingPreview() {

//        print("Mic input \(micInput!)")
        if microphone != nil {
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: [.MixWithOthers, .AllowBluetooth, .DefaultToSpeaker])
                try AVAudioSession.sharedInstance().setActive(true)
            } catch let error as NSError { print(error) }
            
            captureSession.automaticallyConfiguresApplicationAudioSession = false
            captureSession.addInput(micInput!)
        }

//        print("Inputs \(captureSession.inputs)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        previewViewController = storyboard.instantiateViewControllerWithIdentifier("PreviewViewController") as! PreviewViewController
        previewViewController.cameraViewController = self
        
        setupCamera()
        setButtonLabel()
        
        if backCamera != nil {
            beginSession(backCamera!)
        }
        
        if microphone != nil {
            do {
                micInput = try AVCaptureDeviceInput(device: microphone)
                captureSession.addInput(micInput)
                captureSession.usesApplicationAudioSession = true
            } catch { }
        }
        
        if frontCamera == nil {
            switchButton.alpha = 0
            doneButton.alpha = 0
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
                microphone = device as? AVCaptureDevice
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
            captureSession.automaticallyConfiguresApplicationAudioSession = false
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            self.cameraView.layer.addSublayer(previewLayer!)
            previewLayer?.frame = self.view.layer.frame
            captureSession.startRunning()
            
            stillImageOutput.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
            if captureSession.canAddOutput(stillImageOutput) {
                captureSession.addOutput(stillImageOutput)
            }
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
            
        } catch let err as NSError { print(err) }
    }
    
    func switchCameras() {
        if usingbackCamera == true {
            endSession()
            beginSession(frontCamera!)
            if microphone != nil {
                captureSession.addInput(micInput)
            }
            usingbackCamera = false
            setButtonLabel()
        } else {
            endSession()
            beginSession(backCamera!)
            if microphone != nil {
                captureSession.addInput(micInput)
            }
            usingbackCamera = true
            setButtonLabel()
        }
    }
    
    @IBAction func tapSwitchButton(sender: AnyObject) {
        switchCameras()
    }
    
    func startRecording() {
        
        print("Start Recording")
        switchButton.alpha = 0
        doneButton.alpha = 0
        
        recordButton.layer.borderColor = UIColor(red: 255/255, green: 0/255, blue: 0/255, alpha: 0.5).CGColor
        recordButton.backgroundColor = UIColor(red: 255/255, green: 0/255, blue: 0/255, alpha: 0.2)
        
        UIView.animateWithDuration(0.6, delay: 0, options: [.Repeat, .Autoreverse, .CurveEaseInOut], animations: { () -> Void in
            
            self.recordButton.transform = CGAffineTransformMakeScale(1.4, 1.4)
            
            }) { (Bool) -> Void in
        }
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
        let outputPath = "\(documentsPath)/\(currentTimeStamp()).mov"
        let outputFileUrl = NSURL(fileURLWithPath: outputPath)
        videoOutput.startRecordingToOutputFileURL(outputFileUrl, recordingDelegate: self)
    }
    
    func stopRecording() {
        print("Stop Recording")
        switchButton.alpha = 1
        doneButton.alpha = 1
        recordButton.layer.borderColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5).CGColor
        recordButton.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.2)
        
        UIView.animateWithDuration(0.5, delay: 0, options: [], animations: { () -> Void in
            
            self.recordButton.transform = CGAffineTransformMakeScale(1, 1)
            
            }) { (Bool) -> Void in
        }
        
        videoOutput.stopRecording()
    }
    
    func takeStillImage() {
        print("Take Photo")
        cameraView.alpha = 0
        delay(0.085) {
            self.cameraView.alpha = 1
        }
        if let videoConnection = stillImageOutput.connectionWithMediaType(AVMediaTypeVideo) {
            stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection) {
                (imageDataSampleBuffer, error) -> Void in
                
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                
                let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
                
                let outputPath = "\(documentsPath)/\(currentTimeStamp()).jpg"
                
                imageData.writeToFile(outputPath, atomically: true)

                self.addChildViewController(self.previewViewController)
                self.view.addSubview(self.previewViewController.view)
                self.previewViewController.didMoveToParentViewController(self)
            }
        }
    }
    
    func removeMic() {
        if microphone != nil {
            do {
                captureSession.removeInput(micInput)
                print("is it here? \(captureSession.inputs)")
                
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch let error as NSError { print(error) }
        }
    }
    
    @IBAction func longPressWholeView(sender: UILongPressGestureRecognizer) {
        if sender.state == .Began {
            startRecording()
        }
        if sender.state == .Changed {
            
        }
        if sender.state == .Ended {
            stopRecording()
            removeMic()
        }
    }
    
    @IBAction func tapWholeView(sender: UITapGestureRecognizer) {
        
        takeStillImage()
    }
    
    @IBAction func swipeRight(sender: UISwipeGestureRecognizer) {
        switchCameras()
    }
    
    @IBAction func longPressButton(sender: UILongPressGestureRecognizer) {
        
        if sender.state == .Began {
            startRecording()
        }
        if sender.state == .Changed {

        }
        if sender.state == .Ended {
            stopRecording()
            removeMic()
        }
    }
    
    @IBAction func tapButton(sender: AnyObject) {
        takeStillImage()
    }
    @IBAction func done(sender: AnyObject) {
        
        
        
    }
    
    // MARK: AVCaptureFileOutputRecordingDelegate
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        
        addChildViewController(previewViewController)
        self.view.addSubview(self.previewViewController.view)
        self.previewViewController.didMoveToParentViewController(self)
    }

}

