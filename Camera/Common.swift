//
//  Common.swift
//  test
//
//  Created by Timothy Lee on 10/21/14.
//  Copyright (c) 2014 Timothy Lee. All rights reserved.
//

import Foundation
import UIKit

func CGAffineTransformMakeDegreeRotation(rotation: CGFloat) -> CGAffineTransform {
    return CGAffineTransformMakeRotation(rotation * CGFloat(M_PI / 180))
}

func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}

func convertValue(value: CGFloat, r1Min: CGFloat, r1Max: CGFloat, r2Min: CGFloat, r2Max: CGFloat) -> CGFloat {
    let ratio = (r2Max - r2Min) / (r1Max - r1Min)
    return value * ratio + r2Min - r1Min * ratio
}

func returnContentsOfTemporaryDocumentsDirectory() -> [NSURL] {
    let paths = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
    let documentsRootPath = paths[0]
    let temporaryDocumentsURL = NSURL(string: "\(documentsRootPath)/clips/")!
    
    do {
        let directoryContents = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(temporaryDocumentsURL, includingPropertiesForKeys: nil, options: [])
        return directoryContents
        
    } catch let error as NSError {
        print(error.localizedDescription)
        return []
    }
}

func listContentsOfDocumentsDirectory() {
    let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
    do {
        let directoryContents = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(documentsUrl, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions())
        print(directoryContents)
        
    } catch let error as NSError {
        print(error.localizedDescription)
    }
}

func currentTimeStamp() -> String {
    let date = NSDate()
    let formatter = NSDateFormatter()
    formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
    
    return formatter.stringFromDate(date)
}

func removeItemFromDocumentsDirectory(fileName: String) {
    let fileManager:NSFileManager = NSFileManager.defaultManager()
    
    let documentsDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
    let filePath = documentsDir.stringByAppendingPathComponent("/clips/\(fileName)")

    do {
        try fileManager.removeItemAtPath(filePath)
    } catch {
        
    }
}

func deleteAllFilesInDocumentsDirectory() {
    let files = returnContentsOfTemporaryDocumentsDirectory()
    
    for file in files {
        removeItemFromDocumentsDirectory(file.lastPathComponent!)
    }
}

func getAbsolutePathForFile(filename: String) -> String {
    let documentsDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
    let path = documentsDir.stringByAppendingPathComponent("/clips/\(filename)")
    
    return path
}