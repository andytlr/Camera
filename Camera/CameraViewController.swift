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
import RealmSwift

class CameraViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    var previewViewController: PreviewViewController!
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var switchButton: UIButton!
    @IBOutlet weak var showListButton: UIButton!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    
    var usingbackCamera: Bool = true
    var usingSound: Bool = true
    
    var timerProgress: CGFloat! {
        didSet {
            if timerProgress >= 1.0 {
                stopRecording()
            }
        }
    }
    let recordingTimeLimit = 15
    
    var captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    var microphone: AVCaptureDevice?
    var micInput: AVCaptureDeviceInput?
    
    var startTime = NSTimeInterval()
    var timer = NSTimer()
    
    let stillImageOutput = AVCaptureStillImageOutput()
    let videoOutput = AVCaptureMovieFileOutput()
    let devices = AVCaptureDevice.devices()
    
    var clipCount: Int! {
        didSet {
            if clipCount == 0 {
                showListButton.enabled = false
                showListButton.alpha = 0.25
                totalTimeLabel.alpha = 0
                totalTimeLabel.text = ""
            } else {
                showListButton.enabled = true
                showListButton.alpha = 1
                totalTimeLabel.text = totalTimeInSeconds    
                totalTimeLabel.alpha = 1
            }
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func hideIcons() {
        switchButton.alpha = 0
        showListButton.alpha = 0
        totalTimeLabel.alpha = 0
    }
    
    func showIcons() {
        switchButton.alpha = 1
        showListButton.alpha = 1
        totalTimeLabel.alpha = 1
    }
    
    func updateTime() {
        
        let currentTime = NSDate.timeIntervalSinceReferenceDate()
        var elapsedTime: NSTimeInterval = currentTime - startTime
        let immutibleElapsedTime: NSTimeInterval = currentTime - startTime
        
        let seconds = UInt8(elapsedTime)
        elapsedTime -= NSTimeInterval(seconds)
        
        let hundredthOfASecond = immutibleElapsedTime * 100
        
        timerProgress = convertValue(CGFloat(hundredthOfASecond), r1Min: 0, r1Max: (CGFloat(recordingTimeLimit) * 100), r2Min: 0, r2Max: 1)
        
        progressBar.progress = Float(timerProgress)
    }
    
    func startMic() {

        if microphone != nil {
            
            let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
            dispatch_async(dispatch_get_global_queue(priority, 0)) {
                
                if AVAudioSession.sharedInstance().category != AVAudioSessionCategoryPlayAndRecord {
                    do {
                        try AVAudioSession.sharedInstance().setActive(false)
                        try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: [.MixWithOthers, .AllowBluetooth, .DefaultToSpeaker])
                        try AVAudioSession.sharedInstance().setActive(true)
                    } catch let error as NSError { print(error) }
                }
                
                self.captureSession.automaticallyConfiguresApplicationAudioSession = false
                
                if AVAudioSession.sharedInstance().category == AVAudioSessionCategoryPlayAndRecord {
                    self.captureSession.addInput(self.micInput!)
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    // update some UI
                }
            }
        }
    }
    
    func updateButtonCount() {
        updateTotalTime()
        
        let realm = try! Realm()
        clipCount = realm.objects(Clip).count
    }
    
    func appWillEnterBackground() {
        cameraView.alpha = 0
    }
    
    func appDidEnterForeground() {
        cameraView.alpha = 1
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        startMic()
        updateButtonCount()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        if microphone != nil {
            do {
                captureSession.removeInput(micInput)
                try AVAudioSession.sharedInstance().setActive(false)
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch let error as NSError { print(error) }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "appWillEnterBackground", name: UIApplicationWillResignActiveNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "appDidEnterForeground", name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "runWhenDeletedAllClips", name: "All Clips Deleted", object: nil)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        previewViewController = storyboard.instantiateViewControllerWithIdentifier("PreviewViewController") as! PreviewViewController
        previewViewController.cameraViewController = self
        
        progressBar.alpha = 0
        progressBar.progress = 0
        
        setupCamera()
        setCameraOrientationButtonLabel()
        updateButtonCount()
        
        if backCamera != nil {
            beginSession(backCamera!)
        }
        
        if microphone != nil {
            do {
                micInput = try AVCaptureDeviceInput(device: microphone)
            } catch { }
        }
        
        if frontCamera == nil {
            switchButton.alpha = 0
        }
    }
    
    func setCameraOrientationButtonLabel() {
        if usingbackCamera == true {
            switchButton.setTitle("🙎", forState: UIControlState.Normal)
        } else {
            switchButton.setTitle("🌴", forState: UIControlState.Normal)
        }
    }
    
    func setupCamera() {
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        
        recordButton.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.2)
        recordButton.layer.cornerRadius = 40;
        recordButton.clipsToBounds = true;
        recordButton.layer.borderWidth = 2;
        recordButton.layer.borderColor = UIColor.whiteColor().colorWithAlphaComponent(0.5).CGColor
        
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
            if usingSound == true {
                if microphone != nil {
                    captureSession.addInput(micInput)
                }
            }
            usingbackCamera = false
            setCameraOrientationButtonLabel()
        } else {
            endSession()
            beginSession(backCamera!)
            if usingSound == true {
                if microphone != nil {
                    captureSession.addInput(micInput)
                }
            }
            usingbackCamera = true
            setCameraOrientationButtonLabel()
        }
    }
    
    @IBAction func tapSwitchButton(sender: AnyObject) {
        switchCameras()
    }
    
    func startRecording() {
        
        print("Start Recording")
        
        // Start timer
        let aSelector: Selector = "updateTime"
        timer = NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: aSelector, userInfo: nil, repeats: true)
        startTime = NSDate.timeIntervalSinceReferenceDate()
        
        progressBar.alpha = 1
        
        hideIcons()
        
        recordButton.layer.borderColor = redColor.colorWithAlphaComponent(0.5).CGColor
        recordButton.backgroundColor = redColor.colorWithAlphaComponent(0.2)
        
        UIView.animateWithDuration(0.6, delay: 0, options: [.Repeat, .Autoreverse, .CurveEaseInOut], animations: { () -> Void in
            
            self.recordButton.transform = CGAffineTransformMakeScale(1.4, 1.4)
            
            }) { (Bool) -> Void in
        }
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
        let outputPath = documentsPath.stringByAppendingPathComponent("/clips/\(currentTimeStamp()).mov")
        let outputFileUrl = NSURL(fileURLWithPath: outputPath)
        videoOutput.startRecordingToOutputFileURL(outputFileUrl, recordingDelegate: self)
    }
    
    func stopRecording() {
        print("Stop Recording")
        
        // Stop Timer
        progressBar.alpha = 0
        timer.invalidate()
        
        recordButton.layer.borderColor = UIColor.whiteColor().colorWithAlphaComponent(0.5).CGColor
        recordButton.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.2)
        
        UIView.animateWithDuration(0.5, delay: 0, options: [], animations: { () -> Void in
            
            self.recordButton.transform = CGAffineTransformMakeScale(1, 1)
            
            }) { (Bool) -> Void in
        }
        
        videoOutput.stopRecording()
        removeMic()
        recordButton.alpha = 0
    }
    
    func takeStillImage() {
        print("Take Photo")
        cameraView.alpha = 0
        hideIcons()
        recordButton.alpha = 0
        delay(0.085) {
            self.cameraView.alpha = 1
        }
        if let videoConnection = stillImageOutput.connectionWithMediaType(AVMediaTypeVideo) {
            stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection) {
                (imageDataSampleBuffer, error) -> Void in
                
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                
                let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
                
                let outputPath = documentsPath.stringByAppendingPathComponent("/clips/\(currentTimeStamp()).jpg")
                let outputPathURL = NSURL(fileURLWithPath: outputPath)
                
                imageData.writeToFile(outputPath, atomically: true)
                
                let clip = Clip()
                clip.filename = outputPathURL.lastPathComponent!
                clip.type = "photo"
                
                let realm = try! Realm()
                try! realm.write {
                    realm.add(clip)
                }

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
                try AVAudioSession.sharedInstance().setActive(false)
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch let error as NSError { print(error) }
        }
    }
    
    func runWhenDeletedAllClips() {
        delay(0.4) { // delay waits for segue to happen before showing toast.
            toastWithMessage("Deleted", appendTo: self.view, style: .Neutral)
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
        }
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
        }
    }
    
    @IBAction func tapButton(sender: AnyObject) {
//        takeStillImage()
        toastWithMessage("Tap and hold to record", appendTo: self.view, timeShownInSeconds: 1, style: .Neutral)
    }
    
    func showVideoPreview() {
        addChildViewController(previewViewController)
        self.view.addSubview(self.previewViewController.view)
        self.previewViewController.didMoveToParentViewController(self)
    }
    
    // MARK: AVCaptureFileOutputRecordingDelegate
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        
        let clip = Clip()
        clip.filename = outputFileURL.lastPathComponent!
        clip.type = "video"
        
        let realm = try! Realm()
        try! realm.write {
            realm.add(clip)
        }
        
        showVideoPreview()
    }
}

