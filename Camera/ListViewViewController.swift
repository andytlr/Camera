//
//  ListViewViewController.swift
//  Camera
//
//  Created by Cody Evol on 11/13/15.
//  Copyright © 2015 Andy Taylor. All rights reserved.
//

import UIKit

class ListViewViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var ListView: UIView!
    @IBOutlet weak var SceneOne: UIView!
    
    
    //set the centers
    
    var SceneOriginalCenter: CGPoint!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        SceneOriginalCenter = SceneOne.frame.origin
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func ScenePan(sender: UIPanGestureRecognizer) {
        
        let translation = sender.translationInView(view)
        
        if sender.state == UIGestureRecognizerState.Began {
            
            print("began")
            
            SceneOriginalCenter = SceneOne.center
            
            }else if sender.state == UIGestureRecognizerState.Changed {
            
                print(translation.x)
            
                SceneOne.center = CGPoint(x: SceneOriginalCenter.x + translation.x, y: SceneOriginalCenter.y)
            
            
            
                } else if translation.x < -1  && translation.x > -160{
            
                    SceneOne.backgroundColor = UIColor(red: 192/255.0, green: 57/255.0, blue: 43/255.0, alpha: 1.0)

            }else if sender.state == UIGestureRecognizerState.Ended {
    
    print("ended")
    
    }
}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
