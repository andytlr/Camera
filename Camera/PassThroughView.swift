//
//  PassThroughView.swift
//  Camera
//
//  Created by Ben Ashman on 11/24/15.
//  Copyright © 2015 Andy Taylor. All rights reserved.
//

import UIKit

class PassThroughView: UIView {
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        for subview in subviews as [UIView] {
            if !subview.hidden && subview.alpha > 0 && subview.userInteractionEnabled && subview.pointInside(self.convertPoint(point, toView: subview), withEvent: event) {
                return true
            }
        }
        return false
    }
}
