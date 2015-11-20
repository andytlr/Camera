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
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
} // end curly

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */


