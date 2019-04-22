//
//  MergeVideoVC.swift
//  VideoMerger
//
//  Created by Hiren Patel on 15/04/19.
//  Copyright © 2019 Hiren Patel. All rights reserved.
//

import UIKit
import MobileCoreServices
import MediaPlayer
import Photos
import AVFoundation
import AVKit

class MergeVideoVC: UIViewController {
    var firstAsset: AVAsset?
    var secondAsset: AVAsset?
    var audioAsset: AVAsset?
    var loadingAssetOne = false
    
    @IBOutlet var activityMonitor: UIActivityIndicatorView!
    @IBOutlet var thumbImageViewFirst: UIImageView!
    @IBOutlet var thumbImageViewSecond: UIImageView!

    @IBOutlet var btnLoadVideo1: UIButton!
    @IBOutlet var btnMerge: UIButton!
    @IBOutlet var btnLoadAudio: UIButton!


    override func viewDidLoad() {
        super.viewDidLoad()
        self.btnLoadVideo1.clipsToBounds = true
        self.btnLoadVideo1.layer.cornerRadius = 25
        self.btnMerge.clipsToBounds = true
        self.btnMerge.layer.cornerRadius = 25
        self.btnLoadAudio.clipsToBounds = true
        self.btnLoadAudio.layer.cornerRadius = 25

    }

    func savedPhotosAvailable() -> Bool {
        guard !UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) else { return true }
        
        let alert = UIAlertController(title: "Not Available", message: "No Saved Album found", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
        present(alert, animated: true, completion: nil)
        return false
    }
    
    func exportDidFinish(_ session: AVAssetExportSession) {
        
        // Cleanup assets
        activityMonitor.stopAnimating()
        firstAsset = nil
        secondAsset = nil
        audioAsset = nil
        
        guard session.status == AVAssetExportSession.Status.completed,
            let outputURL = session.outputURL else { return }
        
        let saveVideoToPhotos = {
            PHPhotoLibrary.shared().performChanges({ PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL) }) { saved, error in
                let success = saved && (error == nil)
                let title = success ? "Success" : "Error"
                let message = success ? "Video saved" : "Failed to save video"
                
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
        
        // Ensure permission to access Photo Library
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            PHPhotoLibrary.requestAuthorization({ status in
                if status == .authorized {
                    saveVideoToPhotos()
                }
            })
        } else {
            saveVideoToPhotos()
        }
    }
    
    @IBAction func loadAssetOne(_ sender: AnyObject) {
        if savedPhotosAvailable() {
            loadingAssetOne = true
            VideoHelper.startMediaBrowser(delegate: self, sourceType: .savedPhotosAlbum)
        }
    }
    
    @IBAction func loadAssetTwo(_ sender: AnyObject) {
        if savedPhotosAvailable() {
            loadingAssetOne = false
            VideoHelper.startMediaBrowser(delegate: self, sourceType: .savedPhotosAlbum)
        }
    }
    
    @IBAction func loadAudio(_ sender: AnyObject) {
        let mediaPickerController = MPMediaPickerController(mediaTypes: .any)
        mediaPickerController.delegate = self
        mediaPickerController.prompt = "Select Audio"
        present(mediaPickerController, animated: true, completion: nil)
    }
    
    
    @IBAction func merge(_ sender: AnyObject) {
        
        func mergeAudioFiles(audioFileUrls: [URL]) {
            
            // Create the audio composition
            let composition = AVMutableComposition()
            
            for url in audioFileUrls {
                let compositionAudioTrack :AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: CMPersistentTrackID())!
                let asset = AVURLAsset(url: url)
                let track = asset.tracks(withMediaType: AVMediaType.audio)[0]
                let timeRange = CMTimeRange(start: CMTimeMake(value: 0, timescale: 600), duration: track.timeRange.duration)
                try! compositionAudioTrack.insertTimeRange(timeRange, of: track, at: composition.duration)
            }
            
            guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .short
            let date = dateFormatter.string(from: Date())
            let url = documentDirectory.appendingPathComponent("mergeAudio-\(date).mov")

            
            let assetExport = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)
            assetExport?.outputFileType = AVFileType.m4a
            assetExport?.outputURL = url
            
            assetExport!.exportAsynchronously() {
                DispatchQueue.main.async {
                
                }
            }
        }
    }
    
    @IBAction func mergeSingleAudioAndVideo(_ sender: AnyObject) {
        guard let firstAsset = firstAsset else { return }
        
        activityMonitor.startAnimating()
        
        // 1 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
        let mixComposition = AVMutableComposition()
        
        // 2 - Create two video tracks
        guard let firstTrack = mixComposition.addMutableTrack(withMediaType: .video,
                                                              preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { return }
        do {
            try firstTrack.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: firstAsset.duration),
                                           of: firstAsset.tracks(withMediaType: .video)[0],
                                           at: CMTime.zero)
        } catch {
            print("Failed to load first track")
            return
        }
        

        
        // 2.1
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: firstAsset.duration)
        
        // 2.2
        let firstInstruction = VideoHelper.videoCompositionInstruction(firstTrack, asset: firstAsset)
        firstInstruction.setOpacity(0.0, at: firstAsset.duration)
        
        // 2.3
        mainInstruction.layerInstructions = [firstInstruction]
        let mainComposition = AVMutableVideoComposition()
        mainComposition.instructions = [mainInstruction]
        mainComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        mainComposition.renderSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        
        // 3 - Audio track
        if let loadedAudioAsset = audioAsset {
            let audioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: 0)
            do {
                try audioTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: firstAsset.duration),
                                                of: loadedAudioAsset.tracks(withMediaType: .audio)[0] ,
                                                at: CMTime.zero)
            } catch {
                print("Failed to load Audio track")
            }
        }
        
        // 4 - Get path
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        let date = dateFormatter.string(from: Date())
        let url = documentDirectory.appendingPathComponent("mergeVideo-\(date).mov")
        
        // 5 - Create Exporter
        guard let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else { return }
        exporter.outputURL = url
        exporter.outputFileType = AVFileType.mov
        exporter.shouldOptimizeForNetworkUse = true
        exporter.videoComposition = mainComposition
        
        // 6 - Perform the Export
        exporter.exportAsynchronously() {
            DispatchQueue.main.async {
                self.exportDidFinish(exporter)
            }
        }
    }
    
    @IBAction func mergeMulipleVideoAndAudio(_ sender: AnyObject) {
        guard let firstAsset = firstAsset, let secondAsset = secondAsset else { return }
        
        activityMonitor.startAnimating()
        
        // 1 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
        let mixComposition = AVMutableComposition()
        
        // 2 - Create two video tracks
        guard let firstTrack = mixComposition.addMutableTrack(withMediaType: .video,
                                                              preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { return }
        do {
            try firstTrack.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: firstAsset.duration),
                                           of: firstAsset.tracks(withMediaType: .video)[0],
                                           at: CMTime.zero)
        } catch {
            print("Failed to load first track")
            return
        }
        
        guard let secondTrack = mixComposition.addMutableTrack(withMediaType: .video,
                                                               preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { return }
        do {
            try secondTrack.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: secondAsset.duration),
                                            of: secondAsset.tracks(withMediaType: .video)[0],
                                            at: firstAsset.duration)
        } catch {
            print("Failed to load second track")
            return
        }
        
        // 2.1
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: CMTimeAdd(firstAsset.duration, secondAsset.duration))
        
        // 2.2
        let firstInstruction = VideoHelper.videoCompositionInstruction(firstTrack, asset: firstAsset)
        firstInstruction.setOpacity(0.0, at: firstAsset.duration)
        let secondInstruction = VideoHelper.videoCompositionInstruction(secondTrack, asset: secondAsset)
        
        // 2.3
        mainInstruction.layerInstructions = [firstInstruction, secondInstruction]
        let mainComposition = AVMutableVideoComposition()
        mainComposition.instructions = [mainInstruction]
        mainComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        mainComposition.renderSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        
        // 3 - Audio track
        if let loadedAudioAsset = audioAsset {
            let audioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: 0)
            do {
                try audioTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: CMTimeAdd(firstAsset.duration, secondAsset.duration)),
                                                of: loadedAudioAsset.tracks(withMediaType: .audio)[0] ,
                                                at: CMTime.zero)
            } catch {
                print("Failed to load Audio track")
            }
        }
        
        // 4 - Get path
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        let date = dateFormatter.string(from: Date())
        let url = documentDirectory.appendingPathComponent("mergeVideo-\(date).mov")
        
        // 5 - Create Exporter
        guard let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else { return }
        exporter.outputURL = url
        exporter.outputFileType = AVFileType.mov
        exporter.shouldOptimizeForNetworkUse = true
        exporter.videoComposition = mainComposition
        
        // 6 - Perform the Export
        exporter.exportAsynchronously() {
            DispatchQueue.main.async {
                self.exportDidFinish(exporter)
            }
        }
    }
    
    func openPreviewScreen(_ videoURL:URL) -> Void {
        let player = AVPlayer(url: videoURL)
        let playerController = AVPlayerViewController()
        playerController.player = player
        
        present(playerController, animated: true, completion: {
            player.play()
        })
    }
    
}

extension MergeVideoVC: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String,
            mediaType == (kUTTypeMovie as String),
            let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL
            else { return }
        
        let avAsset = AVAsset(url: url)
        var message = ""
        if loadingAssetOne {
            message = "Video one loaded"
            firstAsset = avAsset
            // !! check the error before proceeding
            thumbImageViewFirst.image = self.generateThumbnail(asset: firstAsset!)

        } else {
            message = "Video two loaded"
            secondAsset = avAsset
            thumbImageViewSecond.image = self.generateThumbnail(asset: secondAsset!)
        }
        picker.dismiss(animated: true) {
            let alert = UIAlertController(title: "Asset Loaded", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func generateThumbnail(asset: AVAsset) -> UIImage? {
        do {
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            return thumbnail
        } catch let error {
            print("*** Error generating thumbnail: \(error.localizedDescription)")
            return nil
        }
    }
}

extension MergeVideoVC: UINavigationControllerDelegate {
    
}

extension MergeVideoVC: MPMediaPickerControllerDelegate {
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        
        dismiss(animated: true) {
            let selectedSongs = mediaItemCollection.items
            guard let song = selectedSongs.first else { return }
            
            let url = song.value(forProperty: MPMediaItemPropertyAssetURL) as? URL
            self.audioAsset = (url == nil) ? nil : AVAsset(url: url!)
            let title = (url == nil) ? "Asset Not Available" : "Asset Loaded"
            let message = (url == nil) ? "Audio Not Loaded" : "Audio Loaded"
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler:nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        
        let audioURL1 = Bundle.main.url(forResource: "audio1", withExtension: "mp3")
        self.audioAsset = (audioURL1 == nil) ? nil : AVAsset(url: audioURL1!)
        dismiss(animated: true, completion: nil)
    }
}

