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
var overlayLayers = [CALayer]()
var textLayers = [CALayer]()

var assetTrack:AVAssetTrack?
var assetTrackAudio:AVAssetTrack?
var largestAssetSize = CGSizeMake(0, 0)

var reallySmallNumber = 0.0000000000000000000000000001

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
    savingToCameraRollBackgroundTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({ () -> Void in
        
        print("Background Task Expired")
    })
    
    let composition = AVMutableComposition()
    let trackVideo:AVMutableCompositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID())
    
    trackVideo.preferredTransform = CGAffineTransformMakeDegreeRotation(90)
    
    let trackAudio:AVMutableCompositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID())
    var insertTime = kCMTimeZero
    
    let videoCompositionLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: trackVideo)
    let videoCompositionInstruction = AVMutableVideoCompositionInstruction()
    
    let videoLayer = CALayer()
    let parentLayer = CALayer()
    
    let realm = try! Realm()
    let clips = realm.objects(Clip).sorted("filename", ascending: true)
    
    for clip in clips {
        let sourceUrl = NSURL(fileURLWithPath: getAbsolutePathForFile(clip.filename))
        let sourceAsset = AVURLAsset(URL: sourceUrl, options: nil)
        
        let tracks = sourceAsset.tracksWithMediaType(AVMediaTypeVideo)
        let audios = sourceAsset.tracksWithMediaType(AVMediaTypeAudio)
        
        // Set up video composition
        videoComposition = AVMutableVideoComposition(propertiesOfAsset: sourceAsset)
        
        if tracks.count > 0 {
            assetTrack = tracks[0] as AVAssetTrack
            
            if audios.count > 0 {
                assetTrackAudio = audios[0] as AVAssetTrack
            }
            
            // Get largest asset size
            if assetTrack!.naturalSize.height > largestAssetSize.width {
                largestAssetSize = CGSizeMake(assetTrack!.naturalSize.height, assetTrack!.naturalSize.width)
            }
            
            // Set global render size
            videoComposition.renderSize = largestAssetSize
            let renderSize = videoComposition.renderSize
            let renderFrame = CGRectMake(0, 0, renderSize.width, renderSize.height)
            
            // Set up transforms
            let rotationTransform = assetTrack?.preferredTransform
            let scaleFactor = renderSize.width / assetTrack!.naturalSize.height
            let scaleTransform = CGAffineTransformMakeScale(scaleFactor, scaleFactor)
            let combinedTransform = CGAffineTransformConcat(rotationTransform!, scaleTransform)
            
            print("Render size: \(videoComposition.renderSize)")
            print("Scale factor: \(scaleFactor)")
            
            // If any video is smaller than the render size, scale it up
            if assetTrack!.naturalSize.height < renderSize.width {
                print("scaling!!!")
                videoCompositionLayerInstruction.setTransform(combinedTransform, atTime: insertTime)
            } else {
                videoCompositionLayerInstruction.setTransform(rotationTransform!, atTime: insertTime)
            }
            
            do {
                try trackVideo.insertTimeRange(CMTimeRangeMake(kCMTimeZero,sourceAsset.duration), ofTrack: assetTrack!, atTime: insertTime)
                if audios.count > 0 {
                    try trackAudio.insertTimeRange(CMTimeRangeMake(kCMTimeZero,sourceAsset.duration), ofTrack: assetTrackAudio!, atTime: insertTime)
                }
                
                // Parent layer contains video and all overlays
                parentLayer.frame = renderFrame
                
                videoLayer.frame = renderFrame
                parentLayer.addSublayer(videoLayer)
                
                // Embed overlay
                if clip.overlay != nil {
                    let overlayImage = UIImage(data: clip.overlay!)
                    
                    let overlayLayer = CALayer()
                    overlayLayer.opacity = 0
                    overlayLayer.frame = renderFrame
                    overlayLayer.contents = overlayImage?.CGImage
                    
                    let animation = CABasicAnimation(keyPath: "opacity")
                    animation.duration = CMTimeGetSeconds(sourceAsset.duration)
                    animation.fromValue = 1
                    animation.toValue = 1
                    animation.beginTime = CMTimeGetSeconds(insertTime) + reallySmallNumber
                    animation.fillMode = kCAFillModeForwards
                    animation.removedOnCompletion = true
                    
                    overlayLayer.addAnimation(animation, forKey: "animateOpacity")
                    
                    overlayLayers.append(overlayLayer)
                }
                
                // Embed text
                if clip.textLayer != nil {
                    // Create mock view
                    let textView = UIView(frame: CGRectMake(0, 0, screenSize.width, screenSize.height))
                    let label = UILabel(frame: CGRectFromString((clip.textLayer?.frame)!))
                    label.text = clip.textLayer?.text
                    label.textColor = UIColor.redColor()
                    label.textAlignment = .Center
                    label.textColor = UIColor.whiteColor()
                    label.font = UIFont.systemFontOfSize(32.0, weight: UIFontWeightBold)
                    textView.addSubview(label)
                    
                    // Generate image from mock view
                    UIGraphicsBeginImageContextWithOptions(textView.frame.size, false, UIScreen.mainScreen().scale)
                    textView.layer.renderInContext(UIGraphicsGetCurrentContext()!)
                    let image = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    
                    // Set up text layer
                    let textLayer = CALayer()
                    textLayer.opacity = 0
                    textLayer.frame = renderFrame
                    textLayer.contents = image.CGImage
                    textLayer.contentsScale = UIScreen.mainScreen().scale
                    
                    // Show text layer at correct times
                    let animation = CABasicAnimation(keyPath: "opacity")
                    animation.duration = CMTimeGetSeconds(sourceAsset.duration)
                    animation.fromValue = 1
                    animation.toValue = 1
                    animation.beginTime = CMTimeGetSeconds(insertTime) + reallySmallNumber
                    animation.fillMode = kCAFillModeForwards
                    animation.removedOnCompletion = true
                    
                    textLayer.addAnimation(animation, forKey: "animateOpacity")
                    
                    textLayers.append(textLayer)
                }
            } catch { }
            
            insertTime = CMTimeAdd(insertTime, sourceAsset.duration)
            
            videoCompositionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, insertTime)
        }
    }
    
    if overlayLayers.count > 0 {
        for overlayLayer in overlayLayers {
            parentLayer.addSublayer(overlayLayer)
        }
    }
    
    if textLayers.count > 0 {
        for textLayer in textLayers {
            parentLayer.addSublayer(textLayer)
        }
    }
    
    print("render size: \(videoComposition.renderSize)")
    
    // Finalize video composition
    videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, inLayer: parentLayer)
    
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