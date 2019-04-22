//
//  ViewController.swift
//  VideoMerger
//
//  Created by Hiren Patel on 08/04/19.
//  Copyright © 2019 Hiren Patel. All rights reserved.
//

import UIKit
import AVFoundation
private let MergedMovieFileName = "mergedMovie"

private let MovExtension = "mov"
private let Mp3Extension = "mp3"
private let MOVExtension = "mov"
private let Mp4Extension = "mp4"

/// Resource file names
private let Audio1 = "audio1"
private let Audio2 = "audio2"
private let Audio3 = "audio3"
private let Audio4 = "audio4"

private let Video1 = "video1"
private let Video2 = "video2"
private let Video3 = "video3"
private let Video4 = "video4"
private let PortraitVideo = "portraitVideo"


class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func reversed(_ sender: Any) {
        let videoURL1 = Bundle.main.url(forResource: Video1, withExtension: "MOV")
        if let _url = URL(string: videoURL1!.absoluteString) {
            let avasset = AVAsset(url: _url)
            
            var completeMoviePath: URL?
            if let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
                /// create a path to the video file
                completeMoviePath = URL(fileURLWithPath: documentsPath).appendingPathComponent("reversed.m4v")
                
                if let completeMoviePath = completeMoviePath {
                    if FileManager.default.fileExists(atPath: completeMoviePath.path) {
                        do {
                            /// delete an old duplicate file
                            try FileManager.default.removeItem(at: completeMoviePath)
                        } catch {
                        }
                    }
                }
            } else {
            }
            self.reverse(avasset, outputURL: completeMoviePath!) { (avasset) in
                
            }
        }
    }
     @IBAction func mergedVideo(_ sender: Any) {
        
        let videoURL1 = Bundle.main.url(forResource: Video1, withExtension: "MOV")
        let videoURL2 = Bundle.main.url(forResource: PortraitVideo, withExtension: Mp4Extension)
        if let videoURL1 = videoURL1, let videoURL2 = videoURL2 {
            self.mergeMovies(videoURLs: [videoURL2, videoURL1], andFileName: "mergedPotrait1Video", success: { (url) in
                print(url)
            }) { (error) in
                print(error)
            }
        }
    }
    
     func mergeMovies(videoURLs: [URL], andFileName fileName: String, success: @escaping ((URL) -> Void), failure: @escaping ((Error) -> Void)) {
        let acceptableVideoExtensions = ["mov", "mp4", "m4v"]
        let _videoURLs = videoURLs.filter({ !$0.absoluteString.contains(".DS_Store") && acceptableVideoExtensions.contains($0.pathExtension.lowercased()) })
        let _fileName = fileName == "" ? "mergedVideo" : fileName
        
        /// guard against missing URLs
        guard !_videoURLs.isEmpty else {
            return
        }
        
        var videoAssets: [AVURLAsset] = []
        var completeMoviePath: URL?
        
        for path in _videoURLs {
            if let _url = URL(string: path.absoluteString) {
                videoAssets.append(AVURLAsset(url: _url))
            }
        }
        
        if let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            /// create a path to the video file
            completeMoviePath = URL(fileURLWithPath: documentsPath).appendingPathComponent("\(_fileName).m4v")
            
            if let completeMoviePath = completeMoviePath {
                if FileManager.default.fileExists(atPath: completeMoviePath.path) {
                    do {
                        /// delete an old duplicate file
                        try FileManager.default.removeItem(at: completeMoviePath)
                    } catch {
                        failure(error)
                    }
                }
            }
        } else {
        }
        
        let composition = AVMutableComposition()
        
        if let completeMoviePath = completeMoviePath {
            
            /// add audio and video tracks to the composition
            if let videoTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid), let audioTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                
                var insertTime = CMTime(seconds: 0, preferredTimescale: 1)
                
                /// for each URL add the video and audio tracks and their duration to the composition
                for sourceAsset in videoAssets {
                    do {
                        if let assetVideoTrack = sourceAsset.tracks(withMediaType: .video).first, let assetAudioTrack = sourceAsset.tracks(withMediaType: .audio).first {
                            let frameRange = CMTimeRange(start: CMTime(seconds: 0, preferredTimescale: 1), duration: sourceAsset.duration)
                            try videoTrack.insertTimeRange(frameRange, of: assetVideoTrack, at: insertTime)
                            try audioTrack.insertTimeRange(frameRange, of: assetAudioTrack, at: insertTime)
                            
                            videoTrack.preferredTransform = assetVideoTrack.preferredTransform
                        }
                        
                        insertTime = insertTime + sourceAsset.duration
                    } catch {
                        failure(error)
                    }
                }
                
                /// try to start an export session and set the path and file type
                if let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) {
                    exportSession.outputURL = completeMoviePath
                    exportSession.outputFileType = AVFileType.mp4
                    exportSession.shouldOptimizeForNetworkUse = true
                    
                    /// try to export the file and handle the status cases
                    exportSession.exportAsynchronously(completionHandler: {
                        switch exportSession.status {
                        case .failed:
                            if let _error = exportSession.error {
                                failure(_error)
                            }
                            
                        case .cancelled:
                            if let _error = exportSession.error {
                                failure(_error)
                            }
                            
                        default:
                            print("finished")
                            success(completeMoviePath)
                        }
                    })
                } else {
                }
            }
        }
    }
    
    func reverse(_ original: AVAsset, outputURL: URL, completion: @escaping (AVAsset) -> Void) {
        
        // Initialize the reader
        
        var reader: AVAssetReader! = nil
        do {
            reader = try AVAssetReader(asset: original)
        } catch {
            print("could not initialize reader.")
            return
        }
        
        guard let videoTrack = original.tracks(withMediaType: AVMediaType.video).last else {
            print("could not retrieve the video track.")
            return
        }
        
        let readerOutputSettings: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
        let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerOutputSettings)
        reader.add(readerOutput)
        
        reader.startReading()
        
        // read in samples
        var samples: [CMSampleBuffer] = []
        var samples0: [CMSampleBuffer] = []
        var samples1: [CMSampleBuffer] = []
        var samples2: [CMSampleBuffer] = []
        while let sample = readerOutput.copyNextSampleBuffer() {
            samples0.append(sample)
        }
        samples1 = samples0.reversed()
        samples2 = samples0

        samples.append(contentsOf: samples0)
        samples.append(contentsOf: samples1)
        samples.append(contentsOf: samples2)
        // Initialize the writer
        
        let writer: AVAssetWriter
        do {
            writer = try AVAssetWriter(outputURL: outputURL, fileType: AVFileType.mov)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        let videoCompositionProps = [AVVideoAverageBitRateKey: videoTrack.estimatedDataRate]
        let writerOutputSettings = [
//            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: videoTrack.naturalSize.width,
            AVVideoHeightKey: videoTrack.naturalSize.height,
            AVVideoCompressionPropertiesKey: videoCompositionProps
            ] as [String : Any]
        
        let writerInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: writerOutputSettings)
        writerInput.expectsMediaDataInRealTime = false
        writerInput.transform = videoTrack.preferredTransform
        
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: nil)
        
        writer.add(writerInput)
        writer.startWriting()
        writer.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(samples.first!))
        
        for (index, sample) in samples.enumerated() {
            print(index)
            let presentationTime = CMSampleBufferGetPresentationTimeStamp(sample)
            let imageBufferRef = CMSampleBufferGetImageBuffer(samples[samples.count - 1 - index])
            while !writerInput.isReadyForMoreMediaData {
                Thread.sleep(forTimeInterval: 0.1)
            }
            pixelBufferAdaptor.append(imageBufferRef!, withPresentationTime: presentationTime)
            
        }
        
        writer.finishWriting {
            completion(AVAsset(url: outputURL))
        }
    }

    
    
}

