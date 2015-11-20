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

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        scenes = ["Scene 1", "Scene 2", "Scene 3", "Scene 4", "Scene 5", "Scene 6", "Scene 7"]
//        scenetime = ["00:01", "00:02", "00:03", "00:04", "00:05", "00:06", "00:07"]
        
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
        
//        let scenesname = scenes[indexPath.row]
//        let scenetimeduration = scenetime[indexPath.row]
//        
//        cell.SceneNumber.text = scenesname
//        cell.SceneDuration.text = scenetimeduration

        let clip = clips[indexPath.row]
        let clipAsset = AVURLAsset(URL: clip)
        let clipDuration = clipAsset.duration
        let clipDurationInSeconds = Int(round(CMTimeGetSeconds(clipDuration)))
        let clipDurationSuffix: String!
        if clipDurationInSeconds == 1 {
            clipDurationSuffix = "Second"
        } else {
            clipDurationSuffix = "Seconds"
        }
        
        print(clipDuration)
        
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
            
            editViewController.clip = clips[selectedClipIndex!]
        }
    }

    
} // end curly


