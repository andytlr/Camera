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

    var clips: Results<Clip>!
    var clipCount: Int = 0
    
    var thumbnail: UIImage!
    
    var loadingIndicator: UIActivityIndicatorView!
    let colorView = UIView()
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        colorView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.8)
        colorView.frame = self.view.bounds
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
        
//        print("clip: \(clip)")
        
        let clipAsset = AVURLAsset(URL: NSURL(fileURLWithPath: getAbsolutePathForFile(clip.filename)))
//        print(clipAsset)
        // Get thumbnail
        
        let generator = AVAssetImageGenerator(asset: clipAsset)
        let timestamp = CMTime(seconds: 1, preferredTimescale: 60)
        
        do {
            let imageRef = try generator.copyCGImageAtTime(timestamp, actualTime: nil)
            _ = UIImage(CGImage: imageRef)
        } catch {
            print("Thumbanil generation failed with error \(error)")
        }
        
        let clipDuration = clipAsset.duration
        let clipDurationInSeconds = roundToOneDecimalPlace(CMTimeGetSeconds(clipDuration))
        let clipDurationSuffix: String!
        if clipDurationInSeconds == 1 {
            clipDurationSuffix = "Second"
        } else {
            clipDurationSuffix = "Seconds"
        }
        
        cell.SceneClip.image = thumbnail
        cell.SceneNumber.text = "\(clip.type): \(clip.filename)"
        cell.clip = clip
        cell.SceneDuration.text = String("\(clipDurationInSeconds) \(clipDurationSuffix)")
        
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

    @IBAction func backToCamera(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func tapExport(sender: AnyObject) {
        
        savingToCameraRollBackgroundTask = UIApplication.sharedApplication().beginBackgroundTaskWithName("Exporting To Camera Roll") { () -> Void in
            print("Background Task Expired")
        }
        exportVideo()
        
        loadingIndicator.startAnimating()
        view.addSubview(colorView)
        view.addSubview(loadingIndicator)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "runWhenFinishedSavingToCameraRoll", name: "Finished Saving To Camera Roll", object: nil)
    }
    
    func runWhenFinishedSavingToCameraRoll() {
        loadingIndicator.stopAnimating()
        colorView.removeFromSuperview()
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
