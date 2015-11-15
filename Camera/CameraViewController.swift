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
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var switchButton: UIButton!
    
    var usingbackCamera: Bool = true
    var captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer?
    var captureDevice: AVCaptureDevice?
    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    var randomVideoFileName: String = ""
    var randomPhotoFileName: String = ""
    
    let stillImageOutput = AVCaptureStillImageOutput()
    let videoOutput = AVCaptureMovieFileOutput()
//    let audioOutput = AVCaptureAudioDataOutput()
    let devices = AVCaptureDevice.devices()
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        
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
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
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
    
    func startRecording() {
        print("Start Recording")
        randomVideoFileName = randomStringWithLength(12) as String
        recordButton.layer.borderColor = UIColor(red: 255/255, green: 0/255, blue: 0/255, alpha: 0.5).CGColor
        recordButton.backgroundColor = UIColor(red: 255/255, green: 0/255, blue: 0/255, alpha: 0.2)
        
        UIView.animateWithDuration(0.6, delay: 0, options: [.Repeat, .Autoreverse, .CurveEaseInOut], animations: { () -> Void in
            
            self.recordButton.transform = CGAffineTransformMakeScale(1.4, 1.4)
            
            }) { (Bool) -> Void in
        }
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
        let outputPath = "\(documentsPath)/\(randomVideoFileName).mov"
        let outputFileUrl = NSURL(fileURLWithPath: outputPath)
        videoOutput.startRecordingToOutputFileURL(outputFileUrl, recordingDelegate: self)
        
//        print("path \(outputFileUrl)")
    }
    
    func stopRecording() {
        print("Stop Recording")
        recordButton.layer.borderColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5).CGColor
        recordButton.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.2)
        
        UIView.animateWithDuration(0.5, delay: 0, options: [], animations: { () -> Void in
            
            self.recordButton.transform = CGAffineTransformMakeScale(1, 1)
            
            }) { (Bool) -> Void in
        }
        
        videoOutput.stopRecording()
        
        let movieFrame: CGRect = self.view.bounds
        let movieView: UIView = UIView(frame: movieFrame)
        movieView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        self.view.addSubview(movieView)
        
        // Two lines below return the documents directory as a file: url
        let paths = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let documentsURL = paths[0] as NSURL
        
        // Line below returns the documents directory as a path without the file:
//        let documentsURL = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
        
        let videoPath = NSURL(string: "\(documentsURL)\(randomVideoFileName).mov")!
//        let videoPath = NSBundle.mainBundle().URLForResource("example_recording", withExtension: "mov")!
        
        print(videoPath)
        
        let playerLayer = AVPlayerLayer()
        playerLayer.frame = view.bounds
        
        let videoAsset = AVAsset(URL: videoPath)
        let playerItem = AVPlayerItem(asset: videoAsset)

        let player = AVPlayer(playerItem: playerItem)
        
        player.actionAtItemEnd = .None
        playerLayer.player = player
        playerLayer.backgroundColor = UIColor.purpleColor().CGColor
        playerLayer.videoGravity = AVLayerVideoGravityResize
        movieView.layer.addSublayer(playerLayer)
        player.play()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerDidReachEndNotificationHandler:", name: "AVPlayerItemDidPlayToEndTimeNotification", object: player.currentItem)
        
        // give it a couple secs before deleting
//        delay(2) {
//            let fileManager = NSFileManager.defaultManager()
//
//            if fileManager.fileExistsAtPath("\(documentsPath)/\(self.randomVideoFileName).mov") {
//                print("it exists to delete")
//                do {
//                    try fileManager.removeItemAtPath("\(documentsPath)/\(self.randomVideoFileName).mov")
//                    listContentsOfDocumentsDirectory()
//                } catch {
//                    
//                }
//            }
//            
//        }
        
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func playerDidReachEndNotificationHandler(notification: NSNotification) {
        let playerItem = notification.object as! AVPlayerItem
        playerItem.seekToTime(kCMTimeZero)
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
                
                self.randomPhotoFileName = randomStringWithLength(12) as String
                
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                
                let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
                let outputPath = "\(documentsPath)/\(self.randomPhotoFileName).jpg"
                
                print("\(outputPath)")
                
                imageData.writeToFile(outputPath, atomically: true)
                
//                UIImageWriteToSavedPhotosAlbum(UIImage(data: imageData)!, nil, nil, nil)
            }
        }
    }
    
    @IBAction func longPressButton(sender: UILongPressGestureRecognizer) {
        
        if sender.state == .Began {
            startRecording()
        }
        if sender.state == .Changed {

        }
        if sender.state == .Ended {
            self.stopRecording()
        }
    }
    
    @IBAction func tapButton(sender: AnyObject) {
        takeStillImage()
    }

}

