//
//  ListViewViewController.swift
//  Camera
//
//  Created by Cody Evol on 11/13/15.
//  Copyright © 2015 Andy Taylor. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import RealmSwift

class ListViewViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var clipCollection: UICollectionView!

    var screenEdgeRecognizer: UIScreenEdgePanGestureRecognizer!

    var clips: Results<Clip>!
    var clipCount: Int = 0
    
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    
    var thumbnail: UIImage!
    
    var loadingIndicator: UIActivityIndicatorView!
    var blurView: UIVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        view.backgroundColor = darkGreyColor
        clipCollection.backgroundColor = UIColor.clearColor()
        
        screenEdgeRecognizer = UIScreenEdgePanGestureRecognizer(target: self,
            action: "panLeftEdge:")
        screenEdgeRecognizer.edges = .Left
        view.addGestureRecognizer(screenEdgeRecognizer)
        
        blurView.frame = self.view.bounds
        loadingIndicator = UIActivityIndicatorView(frame: CGRectMake(50, 10, 37, 37)) as UIActivityIndicatorView
        loadingIndicator.center = self.view.center
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.White
        
        clipCollection.dataSource = self
        clipCollection.delegate = self
        
        updateTableView()
        
        let item = collectionView(clipCollection, numberOfItemsInSection: 0) - 1
        let lastItemIndex = NSIndexPath(forItem: item, inSection: 0)
        clipCollection.scrollToItemAtIndexPath(lastItemIndex, atScrollPosition: UICollectionViewScrollPosition.Left, animated: true)
        clipCollection.decelerationRate = UIScrollViewDecelerationRateFast
    }
    
    func updateTableView() {
        let realm = try! Realm()
        clips = realm.objects(Clip).sorted("filename", ascending: true)
        
        clipCollection.reloadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        updateTableView()
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return clips.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionViewCell", forIndexPath: indexPath) as! CollectionViewCell
        
        let clip = clips[indexPath.row]
        
        //        print("clip: \(clip)")
        
        let clipAsset = AVURLAsset(URL: NSURL(fileURLWithPath: getAbsolutePathForFile(clip.filename)))
        
        let clipDuration = clipAsset.duration
        let clipDurationInSeconds = roundToOneDecimalPlace(CMTimeGetSeconds(clipDuration))
        let clipDurationSuffix: String!
        if clipDurationInSeconds == 1 {
            clipDurationSuffix = "Second"
        } else {
            clipDurationSuffix = "Seconds"
        }
        
        cell.clip = clip
        cell.sceneDuration.text = String("\(clipDurationInSeconds) \(clipDurationSuffix)")
        cell.contentView.backgroundColor = darkGreyColor

        let filePath = getAbsolutePathForFile(clip.filename)
        let URL = NSURL(fileURLWithPath: filePath)
        let videoAsset = AVAsset(URL: URL)
        let playerItem = AVPlayerItem(asset: videoAsset)

        playerLayer = AVPlayerLayer()
        playerLayer!.frame = cell.clipView.bounds
        player = AVPlayer(playerItem: playerItem)
        player!.actionAtItemEnd = .None
        playerLayer!.player = player
        playerLayer!.backgroundColor = UIColor.clearColor().CGColor
        playerLayer!.videoGravity = AVLayerVideoGravityResize
        cell.clipView.layer.addSublayer(self.playerLayer!)
        player!.pause()
//        player!.play()
        player!.muted = true
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerDidReachEndNotificationHandler:", name: "AVPlayerItemDidPlayToEndTimeNotification", object: player!.currentItem)
        
        return cell
    }
    
    func playerDidReachEndNotificationHandler(notification: NSNotification) {
        let playerItem = notification.object as! AVPlayerItem
        playerItem.seekToTime(kCMTimeZero)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "EditClip" {
            let editViewController = segue.destinationViewController as! EditClipViewController
            let selectedClipIndex = self.clipCollection.indexPathForCell(sender as! UICollectionViewCell)?.row
            
            let selectedClip = clips[selectedClipIndex!]
            editViewController.clip = selectedClip
        }
    }
    
    func backToCamera() {
        self.navigationController?.popViewControllerAnimated(true)
    }

    @IBAction func backToCamera(sender: AnyObject) {
        backToCamera()
    }
    
    func panLeftEdge(sender: UIScreenEdgePanGestureRecognizer) {
        if sender.state == .Began {
            backToCamera()
        }
    }
    
    @IBAction func tapExport(sender: AnyObject) {
        
        savingToCameraRollBackgroundTask = UIApplication.sharedApplication().beginBackgroundTaskWithName("Exporting To Camera Roll") { () -> Void in
            print("Background Task Expired")
        }
        exportVideo()
        
        loadingIndicator.startAnimating()
        view.addSubview(blurView)
        view.addSubview(loadingIndicator)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "runWhenFinishedSavingToCameraRoll", name: "Finished Saving To Camera Roll", object: nil)
    }
    
    func runWhenFinishedSavingToCameraRoll() {
        loadingIndicator.stopAnimating()
        blurView.removeFromSuperview()
        loadingIndicator.removeFromSuperview()
        
        toastWithMessage("Saved!", appendTo: self.view, accomodateStatusBar: true)
    }
    
    @IBAction func tapDeleteButton(sender: AnyObject) {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in }
        alertController.addAction(cancelAction)
        
        let destroyAction = UIAlertAction(title: "Delete All", style: .Destructive) { (action) in
            
            dispatch_async(dispatch_get_main_queue()) {
                deleteAllClips()
                NSNotificationCenter.defaultCenter().postNotificationName("All Clips Deleted", object: nil)
            }
            
            self.updateTableView()
            self.navigationController!.popViewControllerAnimated(true)
        }
        
        alertController.addAction(destroyAction)
        self.presentViewController(alertController, animated: true) { }
    }
}
