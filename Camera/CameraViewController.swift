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
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var soundButton: UIButton!
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
                doneButton.alpha = 0
                doneButton.setTitle("", forState: UIControlState.Normal)
            } else {
                doneButton.setTitle("\(clipCount)", forState: UIControlState.Normal)
                doneButton.alpha = 1
            }
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func hideIcons() {
        switchButton.alpha = 0
        doneButton.alpha = 0
        soundButton.alpha = 0
    }
    
    func showIcons() {
        switchButton.alpha = 1
        doneButton.alpha = 1
        soundButton.alpha = 1
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
                
                do {
                    try AVAudioSession.sharedInstance().setActive(false)
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: [.MixWithOthers, .AllowBluetooth, .DefaultToSpeaker])
                    try AVAudioSession.sharedInstance().setActive(true)
                } catch let error as NSError { print(error) }
                
                self.captureSession.automaticallyConfiguresApplicationAudioSession = false
                self.captureSession.addInput(self.micInput!)
                
                dispatch_async(dispatch_get_main_queue()) {
                    // update some UI
                }
            }
        }
    }
    
    func updateButtonCount() {
        let realm = try! Realm()
        clipCount = realm.objects(Clip).count
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
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
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
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
        setSoundButtonLabel()
        
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
    
    func setSoundButtonLabel() {
        if usingSound == true {
            soundButton.setTitle("🎤", forState: UIControlState.Normal)
        } else {
            soundButton.setTitle("🎤🚫", forState: UIControlState.Normal)
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
        
        recordButton.layer.borderColor = UIColor(red: 255/255, green: 0/255, blue: 0/255, alpha: 0.5).CGColor
        recordButton.backgroundColor = UIColor(red: 255/255, green: 0/255, blue: 0/255, alpha: 0.2)
        
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
        
        recordButton.layer.borderColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5).CGColor
        recordButton.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.2)
        
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
        delay(0.3) { // delay waits for segue to happen before showing toast.
            toastWithMessage("Trashed em!", appendTo: self.view, destructive: true)
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
        }
    }
    
    @IBAction func tapButton(sender: AnyObject) {
        takeStillImage()
    }
    
    @IBAction func done(sender: AnyObject) {
        
    }
    
    @IBAction func tapSoundButton(sender: AnyObject) {
        if usingSound == true {
            usingSound = false
            removeMic()
            setSoundButtonLabel()
        } else {
            usingSound = true
            startMic()
            setSoundButtonLabel()
        }
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

