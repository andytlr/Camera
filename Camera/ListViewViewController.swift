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
    @IBOutlet weak var SceneView: UIView!
    @IBOutlet weak var DeleteView: UIView!
    
    
    //set the centers
    
    var SceneOriginalCenter: CGPoint!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        SceneOriginalCenter = SceneView.frame.origin
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func ScenePan(sender: UIPanGestureRecognizer) {
        
        let translation = sender.translationInView(view)
        let velocity = sender.velocityInView(view)
        
        
        // start to swipe
        if sender.state == UIGestureRecognizerState.Began {
            
            print("began")
            
            SceneOriginalCenter = SceneView.center
        
            
        // swipping
        }else if sender.state == UIGestureRecognizerState.Changed {
            
                print(translation.x)
                //print(velocity.x)
            
                SceneView.center = CGPoint(x: SceneOriginalCenter.x + translation.x, y: SceneOriginalCenter.y)
            
            if translation.x < -290{
                print("should snap")

                
                
                UIView.animateWithDuration(1.0, animations: { () -> Void in
                    self.SceneView.frame.origin.x = -100
                })
                
                
            }

            
            
        // end swipe
        }else if sender.state == UIGestureRecognizerState.Ended {
    
            print("endPan")
            
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                self.SceneView.frame.origin.x = 0
            })
        
            
     
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
