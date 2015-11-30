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

class ListViewViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var clipReviewList: UITableView!

    var screenEdgeRecognizer: UIScreenEdgePanGestureRecognizer!

    var clips: Results<Clip>!
    var clipCount: Int = 0
    
    var thumbnail: UIImage!
    
    var loadingIndicator: UIActivityIndicatorView!
    var blurView: UIVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.view.backgroundColor = darkGreyColor
        clipReviewList.backgroundColor = darkGreyColor
        
        screenEdgeRecognizer = UIScreenEdgePanGestureRecognizer(target: self,
            action: "panLeftEdge:")
        screenEdgeRecognizer.edges = .Left
        view.addGestureRecognizer(screenEdgeRecognizer)
        
        blurView.frame = self.view.bounds
        loadingIndicator = UIActivityIndicatorView(frame: CGRectMake(50, 10, 37, 37)) as UIActivityIndicatorView
        loadingIndicator.center = self.view.center;
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.White
    }
    
    func updateTableView() {
        let realm = try! Realm()
        clips = realm.objects(Clip).sorted("filename", ascending: false)
        
        clipReviewList.reloadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        clipReviewList.dataSource = self
        clipReviewList.delegate = self
        
        updateTableView()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return clips.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SceneTableViewCell") as! SceneTableViewCell

        let clip = clips[indexPath.row]
        
        print("clip: \(clip)")
        
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
        
        return cell
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "editClipSegue" {
            let editViewController = segue.destinationViewController as! EditClipViewController
            let selectedClipIndex = self.clipReviewList.indexPathForCell(sender as! UITableViewCell)?.row
    
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
