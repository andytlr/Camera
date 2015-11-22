//
//  CameraRoll.swift
//  Camera
//
//  Created by Andy Taylor on 11/21/15.
//  Copyright © 2015 Andy Taylor. All rights reserved.
//

import Photos

class CustomPhotoAlbum {
    
    static let albumName = "Show"
    static let sharedInstance = CustomPhotoAlbum()
    
    var assetCollection: PHAssetCollection!
    
    init() {
        
        func fetchAssetCollectionForAlbum() -> PHAssetCollection! {
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "title = %@", CustomPhotoAlbum.albumName)
            let collection = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions)
            
            if let _: AnyObject = collection.firstObject {
                return collection.firstObject as! PHAssetCollection
            }
            
            return nil
        }
        
        if let assetCollection = fetchAssetCollectionForAlbum() {
            self.assetCollection = assetCollection
            return
        }
        
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({
            PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle(CustomPhotoAlbum.albumName)
            }) { success, _ in
                if success {
                    self.assetCollection = fetchAssetCollectionForAlbum()
                }
        }
    }
    
    func saveMovieWithUrl(url: NSURL, fileToDelete: String) {
        
        if assetCollection == nil {
            return   // If there was an error upstream, skip the save.
        }
        
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({
            let assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(url)
            let assetPlaceholder = assetChangeRequest!.placeholderForCreatedAsset
            let albumChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: self.assetCollection)
            albumChangeRequest!.addAssets([assetPlaceholder!])
            }, completionHandler: { (success: Bool, error: NSError?) in
                
                if (success) {
                    print("Finished saving to camera roll, ready to delete from temp.")
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        NSNotificationCenter.defaultCenter().postNotificationName("Finished Saving To Camera Roll", object: nil)
                    }
                    
                    do {
                        try NSFileManager.defaultManager().removeItemAtPath(fileToDelete)
                        print("Deleted")
                    } catch { print("Couldn't Delete") }
                }
        
        })
    }
    
    
}