//
//  FileManagment.swift
//  Camera
//
//  Created by Andy Taylor on 11/26/15.
//  Copyright © 2015 Andy Taylor. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift

func deleteClip(fileName: String) {
    let fileManager:NSFileManager = NSFileManager.defaultManager()
    
    let documentsDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
    let filePath = documentsDir.stringByAppendingPathComponent("/clips/\(fileName)")
    
    do {
        try fileManager.removeItemAtPath(filePath)
    } catch {
        
    }
}

func deleteSingleClip(clip: Clip) {
    // Delete from documents directory
    deleteClip(clip.filename)
    
    // Delete reference from DB
    let realm = try! Realm()
    try! realm.write {
        print(clip)
        realm.delete(clip)
    }
}

func deleteAllClips() {
    let clips = returnContentsOfClipsDirectory()
    
    for clip in clips {
        deleteClip(clip.lastPathComponent!)
    }
    
    // Delete reference from DB
    let realm = try! Realm()
    try! realm.write {
        realm.deleteAll()
    }
}