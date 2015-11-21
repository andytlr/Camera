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

class ListViewViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var ClipReviewList: UITableView!
    
    var scenes: [String]!
    var scenetime: [String]!
    
    var clips: [NSURL]!
    var clipCount: Int = 0

    var thumbnail: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        ClipReviewList.dataSource = self
        ClipReviewList.delegate = self
        
        clips = returnContentsOfDocumentsDirectory()
        clipCount = clips.count
        print("Number of clips: \(clipCount)")
        
        ClipReviewList.reloadData()
    }

    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(clipCount)
        return clipCount
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SceneTableViewCell") as! SceneTableViewCell

        let clip = clips[indexPath.row]
        let clipAsset = AVURLAsset(URL: clip)
        
        //getthumb
        
        let generator = AVAssetImageGenerator(asset: clipAsset)
        
        let timestamp = CMTime(seconds: 1, preferredTimescale: 60)

        do {
            let imageRef = try generator.copyCGImageAtTime(timestamp, actualTime: nil)
            thumbnail = UIImage(CGImage: imageRef)
        }
        catch let error as NSError
        {
            print("Image generation failed with error \(error)")
        }
    
        print(thumbnail)
        
        let clipDuration = clipAsset.duration
        let clipDurationInSeconds = Int(round(CMTimeGetSeconds(clipDuration)))
        let clipDurationSuffix: String!
        if clipDurationInSeconds == 1 {
            clipDurationSuffix = "Second"
        } else {
            clipDurationSuffix = "Seconds"
        }
        
        print(clipDuration)
        cell.SceneClip.image = thumbnail
        cell.SceneNumber.text = String(clip.absoluteString)
        cell.SceneDuration.text = String("\(clipDurationInSeconds) \(clipDurationSuffix)")
        
        return cell
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "editClipSegue" {
            let editViewController = segue.destinationViewController as! EditClipViewController
            let selectedClipIndex = self.ClipReviewList.indexPathForCell(sender as! UITableViewCell)?.row
            
            editViewController.clipURL = clips[selectedClipIndex!]
        }
    }

    @IBAction func backToCamera(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func tapDeleteButton(sender: AnyObject) {
        
        let alertController = UIAlertController(title: nil, message: "This will delete all your clips. Are you sure?", preferredStyle: .ActionSheet)
        
        let cancelAction = UIAlertAction(title: "Nope, save them.", style: .Cancel) { (action) in }
        alertController.addAction(cancelAction)
        
        let destroyAction = UIAlertAction(title: "Yep, delete them.", style: .Destructive) { (action) in
            deleteAllFilesInDocumentsDirectory()
            // Need to reload the list here
        }
        alertController.addAction(destroyAction)
        
        self.presentViewController(alertController, animated: true) { }
    }
    
}
