//
//  Clip.swift
//  Camera
//
//  Created by Ben Ashman on 11/21/15.
//  Copyright © 2015 Andy Taylor. All rights reserved.
//

import Foundation
import RealmSwift

class Clip: Object {
    dynamic var filename: String! = ""
    dynamic var type: String! = ""
    dynamic var overlay: NSData? = nil
    dynamic var text: TextLayer?
}

class TextLayer: Object {
    dynamic var text: String!
    dynamic var position: String!
}