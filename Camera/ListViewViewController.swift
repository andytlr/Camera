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
    
//    var scenes: [String]!
//    var scenetime: [String]!
    
//    var clips: [NSURL]!
//    var clipCount: Int = 0

    var clips: Results<Clip>!
    var clipCount: Int = 0
    
    var thumbnail: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func updateTableView() {
//        clips = returnContentsOfTemporaryDocumentsDirectory()
//        clipCount = clips.count
        
        let realm = try! Realm()
        clips = realm.objects(Clip)
        
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
        print(clipAsset)
        // Get thumbnail
        
        let generator = AVAssetImageGenerator(asset: clipAsset)
        let timestamp = CMTime(seconds: 1, preferredTimescale: 60)
        
        do {
            let imageRef = try generator.copyCGImageAtTime(timestamp, actualTime: nil)
            let thumbnail = UIImage(CGImage: imageRef)
        } catch {
            print("Thumbanil generation failed with error \(error)")
        }
        
        let clipDuration = clipAsset.duration
        let clipDurationInSeconds = Int(round(CMTimeGetSeconds(clipDuration)))
        let clipDurationSuffix: String!
        if clipDurationInSeconds == 1 {
            clipDurationSuffix = "Second"
        } else {
            clipDurationSuffix = "Seconds"
        }
        
        cell.SceneClip.image = thumbnail
        cell.SceneNumber.text = clip.filename
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
            
            let url = NSURL(string: getAbsolutePathForFile(clips[selectedClipIndex!].filename))
            editViewController.clipURL = url
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
            let realm = try! Realm()
            try! realm.write {
                realm.deleteAll()
            }
            
            self.updateTableView()
        }
        
        alertController.addAction(destroyAction)
        self.presentViewController(alertController, animated: true) { }
    }
}
