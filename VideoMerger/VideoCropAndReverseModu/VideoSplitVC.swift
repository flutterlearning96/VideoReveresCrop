//
//  VideoSplitVC.swift
//  VideoMerger
//
//  Created by Hiren Patel on 21/04/19.
//  Copyright © 2019 Hiren Patel. All rights reserved.
//

import UIKit
import MobileCoreServices
import MediaPlayer
import Photos
import AVFoundation
import AVKit

class VideoSplitVC: UIViewController {
    var firstAsset: AVAsset?
    var loadingAssetOne = false
    var firstAssetURL: URL?

    @IBOutlet var activityMonitor: UIActivityIndicatorView!
    @IBOutlet var thumbImageViewFirst: UIImageView!
    
    @IBOutlet var btnLoadVideo1: UIButton!
    var startSplitDuration: CGFloat = 0.0
    var endSplitDuration: CGFloat = 0.3
    @IBOutlet fileprivate weak var changeBorderSlider: RangeSeekSlider!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.btnLoadVideo1.clipsToBounds = true
        self.btnLoadVideo1.layer.cornerRadius = 25
        
        changeBorderSlider.delegate = self
        changeBorderSlider.minDistance = 0.0
        changeBorderSlider.maxDistance = 0.06
        changeBorderSlider.minValue = 0.0
        changeBorderSlider.maxValue = 0.06

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
        firstAssetURL = nil
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
    
   
    @IBAction func splitVideo(_ sender: AnyObject) {
        activityMonitor.startAnimating()
        
        VideoGenerator.current.splitVideo(withURL: firstAssetURL!, atStartTime: Double(self.startSplitDuration), andEndTime: Double(self.endSplitDuration), success: { (outPutURL) in
            DispatchQueue.main.async {
                self.activityMonitor.stopAnimating()
                
                let saveVideoToPhotos = {
                    PHPhotoLibrary.shared().performChanges({ PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outPutURL) }) { saved, error in
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
        }) { (error) in
            DispatchQueue.main.async {
                self.activityMonitor.stopAnimating()
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

extension VideoSplitVC: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String,
            mediaType == (kUTTypeMovie as String),
            let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL
            else { return }
        
        let avAsset = AVAsset(url: url)
        var message = ""
        message = "Video one loaded"
        firstAsset = avAsset
        print(firstAsset?.duration.value)
        firstAssetURL = url
        // !! check the error before proceeding
        thumbImageViewFirst.image = self.generateThumbnail(asset: firstAsset!)
        
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

extension VideoSplitVC: UINavigationControllerDelegate {
    
}

extension VideoSplitVC: RangeSeekSliderDelegate {
    
    func rangeSeekSlider(_ slider: RangeSeekSlider, didChange minValue: CGFloat, maxValue: CGFloat) {
        if slider === changeBorderSlider {
            print("Standard slider updated. Min Value: \(minValue) Max Value: \(maxValue)")
            self.startSplitDuration = minValue
            self.endSplitDuration = maxValue
        }
        
    }
    
    func didStartTouches(in slider: RangeSeekSlider) {
        print("did start touches")
    }
    
    func didEndTouches(in slider: RangeSeekSlider) {
        print("did end touches")
    }
}
