//
//  PlayVideoVC.swift
//  VideoMerger
//
//  Created by Hiren Patel on 15/04/19.
//  Copyright © 2019 Hiren Patel. All rights reserved.
//

import UIKit
import AVKit
import MobileCoreServices

class PlayVideoVC: UIViewController {
    
    @IBOutlet var btnplayVideo: UIButton!

    @IBAction func playVideo(_ sender: AnyObject) {
        VideoHelper.startMediaBrowser(delegate: self, sourceType: .savedPhotosAlbum)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.btnplayVideo.clipsToBounds = true
        self.btnplayVideo.layer.cornerRadius = 25
    }
}

// MARK: - UIImagePickerControllerDelegate

extension PlayVideoVC: UIImagePickerControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    
        guard let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String,
            mediaType == (kUTTypeMovie as String),
            let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL
            else { return }
        
        dismiss(animated: true) {
            let player = AVPlayer(url: url)
            let vcPlayer = AVPlayerViewController()
            vcPlayer.player = player
            self.present(vcPlayer, animated: true, completion: nil)
        }
    }
}

// MARK: - UINavigationControllerDelegate

extension PlayVideoVC: UINavigationControllerDelegate {
}
