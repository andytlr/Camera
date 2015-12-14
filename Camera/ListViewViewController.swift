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

class ListViewViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet var mainView: UIView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var clipCollection: UICollectionView!
    @IBOutlet weak var bgImageView: UIImageView!
    
    var screenEdgeRecognizer: UIScreenEdgePanGestureRecognizer!
    var deleteGesture: UIPanGestureRecognizer!
    
    var lightboxTransition: LightboxTransition!

    var clips: Results<Clip>!
    var clipCount: Int = 0
    
    var currentlyVisibleClip: Int = 0
    var currentIndexPath: Int = 0
    
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    
    var players: [AVPlayer?] = []
    var playerLayers: [AVPlayerLayer?] = []
    
    var thumbnail: UIImage!
    
    var loadingIndicator: UIActivityIndicatorView!
    var blurView: UIVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
    
    var clipOriginalY: CGFloat!
    
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
        
        let deleteAction = Selector("deleteCell:")
        deleteGesture = UIPanGestureRecognizer(target: self, action: deleteAction)
        
        screenEdgeRecognizer.delegate = self
        deleteGesture.delegate = self
        
        lightboxTransition = LightboxTransition()
        
        blurView.frame = self.view.bounds
        loadingIndicator = UIActivityIndicatorView(frame: CGRectMake(50, 10, 37, 37)) as UIActivityIndicatorView
        loadingIndicator.center = self.view.center
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.White
        
        clipCollection.dataSource = self
        clipCollection.delegate = self
        
        updateTableView()
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        var insets = self.clipCollection.contentInset
        let value = (self.view.frame.size.width - (self.clipCollection.collectionViewLayout as! UICollectionViewFlowLayout).itemSize.width) * 0.5
        insets.left = value
        insets.right = value
        self.clipCollection.contentInset = insets
        self.clipCollection.decelerationRate = UIScrollViewDecelerationRateFast
    }
    
    func updateTableView() {
        let realm = try! Realm()
        clips = realm.objects(Clip).sorted("filename", ascending: true)
        
        let lastClip = clips.last!
        
//        print(lastClip)
        
        let lastClipAssett = AVURLAsset(URL: NSURL(fileURLWithPath: getAbsolutePathForFile(lastClip.filename)))
        
        let imageGenerator = AVAssetImageGenerator(asset: lastClipAssett)
        imageGenerator.appliesPreferredTrackTransform = true
        
        do {
            let cgImage = try imageGenerator.copyCGImageAtTime(CMTimeMake (0,1), actualTime: nil)

            let firstClipImage = UIImage(CGImage: cgImage)
            bgImageView.image = firstClipImage
            
            self.backgroundView.insertSubview(self.blurView, aboveSubview: self.bgImageView)
            
        } catch let error as NSError {
            print(error)
        }
        
        clipCollection.reloadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        dispatch_async(dispatch_get_main_queue()) {
            self.updateTableView()
            
            let item = self.collectionView(self.clipCollection, numberOfItemsInSection: 0) - 1
            let lastItemIndex = NSIndexPath(forItem: item, inSection: 0)
            self.clipCollection.scrollToItemAtIndexPath(lastItemIndex, atScrollPosition: UICollectionViewScrollPosition.CenteredHorizontally, animated: false)
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return clips.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionViewCell", forIndexPath: indexPath) as! CollectionViewCell
        cell.layer.shouldRasterize = true
        cell.layer.rasterizationScale = UIScreen.mainScreen().scale
        
        let clip = clips[indexPath.row]
        
        // print("clip: \(clip)")
        
        let clipAsset = AVURLAsset(URL: NSURL(fileURLWithPath: getAbsolutePathForFile(clip.filename)))
        
        cell.clip = clip
        cell.contentView.backgroundColor = UIColor.clearColor()
        
        let clipDuration = clipAsset.duration
        let clipDurationInSeconds = roundToOneDecimalPlace(CMTimeGetSeconds(clipDuration))
        cell.sceneDuration.text = String("\(clipDurationInSeconds)s")
        
        let filePath = getAbsolutePathForFile(clip.filename)
        let URL = NSURL(fileURLWithPath: filePath)
        let videoAsset = AVAsset(URL: URL)
        let playerItem = AVPlayerItem(asset: videoAsset)
        
        player = AVPlayer(playerItem: playerItem)
        player!.actionAtItemEnd = .None
        cell.playerLayer.player = player
        
        currentIndexPath = indexPath.row
        
        print("index path row \(currentIndexPath)")
        print("currently visible \(currentlyVisibleClip)")
        
//        if currentIndexPath == currentlyVisibleClip {
//            player!.play()
//        }
        
        player!.play()
        
        player!.muted = true
        players.append(player)
        playerLayers.append(playerLayer)

        cell.addGestureRecognizer(deleteGesture)
//        deleteGesture.enabled = false
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerDidReachEndNotificationHandler:", name: "AVPlayerItemDidPlayToEndTimeNotification", object: player!.currentItem)
        
        return cell
    }
    
    func deleteCell(sender: UIPanGestureRecognizer) {
        let translation = sender.translationInView(view)
        let velocity = sender.velocityInView(view)
        let clipView = sender.view
        
        if sender.state == .Began {
            clipOriginalY = clipView!.frame.origin.y
        }
        
        if sender.state == .Changed {
            
            clipView!.frame.origin.y = clipOriginalY + translation.y
            
            print(translation.y)
            
            if translation.y > 0 {
                clipView!.frame.origin.y = clipOriginalY + (translation.y / 7)
            }
        }
        
        if sender.state == .Ended {
            
            print(velocity.y)
            
//            if velocity.y < -350 || translation.y < -350 {
            if translation.y < -350 {
                
                UIView.animateWithDuration(0.6, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 10, options: [], animations: { () -> Void in
                    
                    clipView!.frame.origin.y = 0 - self.view.frame.height
                    
                    }, completion: { (Bool) -> Void in
                        
                        print("deleting cell")
                        let cell = sender.view as! UICollectionViewCell
                        let index = self.clipCollection.indexPathForCell(cell)!.item
                        deleteSingleClipAtIndex(index)
                        self.clipCollection.reloadData()
                })
                
                print("deleting clip")
                
            } else {
                
                UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 10, options: [], animations: { () -> Void in
                    
                    print("cancel deletion")
                    clipView?.frame.origin.y = self.clipOriginalY
                    
                    }, completion: { (Bool) -> Void in
                })
            }
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
//        let visibleRect: CGRect = CGRect(origin: self.clipCollection.contentOffset, size: self.clipCollection.bounds.size)
//        let visiblePoint: CGPoint = CGPointMake(CGRectGetMidX(visibleRect), CGRectGetMidY(visibleRect))
//        let visibleIndexPath = self.clipCollection.indexPathForItemAtPoint(visiblePoint)
        
        
//        print("derp \(visibleIndexPath!.row)")
//        self.currentlyVisibleClip = visibleIndexPath!.row
        
        let cellWidth: CGFloat = 225
        let cellPadding: CGFloat = 20
        currentlyVisibleClip = Int(self.clipCollection.contentOffset.x / (cellWidth + cellPadding))
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
      
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
            
            editViewController.modalPresentationStyle = UIModalPresentationStyle.Custom
            editViewController.transitioningDelegate = lightboxTransition
            
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
        exportVideo()
        
        loadingIndicator.startAnimating()
        view.addSubview(blurView)
        view.addSubview(loadingIndicator)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "runWhenFinishedSavingToCameraRoll", name: "Finished Saving To Camera Roll", object: nil)
    }
    
    func runWhenFinishedSavingToCameraRoll() {
        loadingIndicator.stopAnimating()
//        blurView.removeFromSuperview()
        self.bgImageView.insertSubview(self.blurView, aboveSubview: self.bgImageView)
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
            
            self.backToCamera()
        }
        
        alertController.addAction(destroyAction)
        self.presentViewController(alertController, animated: true) { }
    }
}
