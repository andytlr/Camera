//
//  VideoProcessingModel.swift
//  Camera
//
//  Created by Andy Taylor on 11/21/15.
//  Copyright © 2015 Andy Taylor. All rights reserved.
//

import Foundation
import AVKit
import AVFoundation
import Photos
import RealmSwift

var totalTimeAsDouble: Double = 0
var totalDurationInSeconds: String = ""
var screenSize = UIScreen.mainScreen().bounds

var videoComposition: AVMutableVideoComposition!

func formatTime(timeInSeconds: Int) -> String {
    
    let hours = timeInSeconds / 3600
    let minutes = (timeInSeconds % 3600) / 60
    let seconds = (timeInSeconds % 3600) % 60
    
    if hours != 0 {
        return String(format: "%02d", hours) + ":" + String(format: "%02d", minutes) + ":" + String(format: "%02d", seconds)
    } else {
        return String(format: "%02d", minutes) + ":" + String(format: "%02d", seconds)
    }
}

func updateTotalTime() {
    let realm = try! Realm()
    let clips = realm.objects(Clip).sorted("filename", ascending: true)
    
    totalTimeAsDouble = 0
    
    for clip in clips {
        let duration = AVURLAsset(URL: NSURL(fileURLWithPath: getAbsolutePathForFile(clip.filename))).duration
        totalTimeAsDouble += CMTimeGetSeconds(duration)
        
        totalDurationInSeconds = formatTime(Int(totalTimeAsDouble))
    }
}

func exportVideo() {
    let composition = AVMutableComposition()
    let trackVideo:AVMutableCompositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID())
    
    trackVideo.preferredTransform = CGAffineTransformMakeDegreeRotation(90)
    
    let trackAudio:AVMutableCompositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID())
    var insertTime = kCMTimeZero
    
    let videoCompositionLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: trackVideo)
    let videoCompositionInstruction = AVMutableVideoCompositionInstruction()
    
    let realm = try! Realm()
    let clips = realm.objects(Clip).sorted("filename", ascending: true)
    
    for clip in clips {
        let sourceUrl = NSURL(fileURLWithPath: getAbsolutePathForFile(clip.filename))
        let sourceAsset = AVURLAsset(URL: sourceUrl, options: nil)
        
        let tracks = sourceAsset.tracksWithMediaType(AVMediaTypeVideo)
        let audios = sourceAsset.tracksWithMediaType(AVMediaTypeAudio)
        
        // Set up video composition
        videoComposition = AVMutableVideoComposition(propertiesOfAsset: sourceAsset)
        
        // Parent layer contains video and all overlays
        let parentLayer = CALayer()
        parentLayer.frame = CGRectMake(0, 0, tracks[0].naturalSize.height, tracks[0].naturalSize.width)
        
        let videoLayer = CALayer()
        videoLayer.frame = CGRectMake(0, 0, tracks[0].naturalSize.height, tracks[0].naturalSize.width)
        parentLayer.addSublayer(videoLayer)
        
        // Add drawing to composition if the clip has one
        if clip.overlay != nil {
            let overlayImage = UIImage(data: clip.overlay!)
            
            let overlayLayer = CALayer()
            overlayLayer.frame = CGRectMake(0, 0, tracks[0].naturalSize.height, tracks[0].naturalSize.width)
            overlayLayer.contents = overlayImage?.CGImage
            parentLayer.addSublayer(overlayLayer)
        }
        
        // Finalize video composition
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, inLayer: parentLayer)
        
        if tracks.count > 0 {
            let assetTrack:AVAssetTrack = tracks[0] as AVAssetTrack
            let assetTrackAudio:AVAssetTrack = audios[0] as AVAssetTrack
            do {
                try trackVideo.insertTimeRange(CMTimeRangeMake(kCMTimeZero,sourceAsset.duration), ofTrack: assetTrack, atTime: insertTime)
                try trackAudio.insertTimeRange(CMTimeRangeMake(kCMTimeZero,sourceAsset.duration), ofTrack: assetTrackAudio, atTime: insertTime)
            } catch { }
            
            insertTime = CMTimeAdd(insertTime, sourceAsset.duration)
            
            videoCompositionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, insertTime)
        }
    }
    
    videoCompositionInstruction.layerInstructions = NSArray(object: videoCompositionLayerInstruction) as! [AVVideoCompositionLayerInstruction]
    videoComposition.instructions = NSArray(object: videoCompositionInstruction) as! [AVVideoCompositionInstructionProtocol]
    
    let exportPath = NSTemporaryDirectory().stringByAppendingFormat("/\(currentTimeStamp()).mov")
    let completeMovieUrl: NSURL = NSURL.fileURLWithPath(exportPath)
    
    let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)!
    exporter.outputURL = completeMovieUrl
    exporter.videoComposition = videoComposition
    exporter.outputFileType = AVFileTypeMPEG4
    exporter.exportAsynchronouslyWithCompletionHandler({
        
        switch exporter.status {
        case AVAssetExportSessionStatus.Failed:
            print("Failed \(exporter.error)")
            // Error Toast here.
        case AVAssetExportSessionStatus.Cancelled:
            print("Cancelled \(exporter.error)")
            // Error Toast here.
        default:
            CustomPhotoAlbum.sharedInstance.saveMovieWithUrl(completeMovieUrl, tempFileToDeleteOnCompletion: exportPath)
        }
    })
}