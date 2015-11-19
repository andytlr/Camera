//
//  ListViewViewController.swift
//  Camera
//
//  Created by Cody Evol on 11/13/15.
//  Copyright © 2015 Andy Taylor. All rights reserved.
//

import UIKit

class ListViewViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var ClipReviewList: UITableView!
    
    
    var scenes: [String]!
    var scenetime: [String]!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //scene data
        
        scenes = ["Scene 1", "Scene 2", "Scene 3", "Scene 4", "Scene 5", "Scene 6", "Scene 7"]
        scenetime = ["00:01", "00:02", "00:03", "00:04", "00:05", "00:06", "00:07"]
        
        //table delegates
        
        ClipReviewList.delegate = self
        ClipReviewList.dataSource = self
        
        
       
    }

    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scenes.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("SceneTableViewCell") as! SceneTableViewCell
        
        let scenesname = scenes[indexPath.row]
        let scenetimeduration = scenetime[indexPath.row]
        
        cell.SceneNumber.text = scenesname
        cell.SceneDuration.text = scenetimeduration

        
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


