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

func exportVideo() {
    let composition = AVMutableComposition()
    let trackVideo:AVMutableCompositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID())
    let trackAudio:AVMutableCompositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID())
    var insertTime = kCMTimeZero
    
    let movies = returnContentsOfTemporaryDocumentsDirectory()
    
    for movie in movies {
        let sourceAsset = AVURLAsset(URL: movie, options: nil)
        
        let tracks = sourceAsset.tracksWithMediaType(AVMediaTypeVideo)
        let audios = sourceAsset.tracksWithMediaType(AVMediaTypeAudio)
        
        if tracks.count > 0 {
            let assetTrack:AVAssetTrack = tracks[0] as AVAssetTrack
            let assetTrackAudio:AVAssetTrack = audios[0] as AVAssetTrack
            do {
                try trackVideo.insertTimeRange(CMTimeRangeMake(kCMTimeZero,sourceAsset.duration), ofTrack: assetTrack, atTime: insertTime)
                try trackAudio.insertTimeRange(CMTimeRangeMake(kCMTimeZero,sourceAsset.duration), ofTrack: assetTrackAudio, atTime: insertTime)
            } catch { }
            
            insertTime = CMTimeAdd(insertTime, sourceAsset.duration)
        }
    }
    
    let documentsDirectory = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
    
    let completeMovieUrl = documentsDirectory.URLByAppendingPathComponent("movie.mov")
    let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)!
    exporter.outputURL = completeMovieUrl
    exporter.outputFileType = AVFileTypeMPEG4 // AVFileTypeQuickTimeMovie
    exporter.exportAsynchronouslyWithCompletionHandler({
        switch exporter.status{
        case  AVAssetExportSessionStatus.Failed:
            print("failed \(exporter.error)")
        case AVAssetExportSessionStatus.Cancelled:
            print("cancelled \(exporter.error)")
        default:
            print("complete")
        }
    })
}