//
//  ImageAudioVideoVC.swift
//  VideoMerger
//
//  Created by Hiren Patel on 22/04/19.
//  Copyright © 2019 Hiren Patel. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

class ImageAudioVideoVC: UIViewController, PhotosLibraryVCDelegate {
   
    
    var photosLibraryVC: PhotosLibraryVC?

    var imagesArray: [UIImage] = []
    override func viewDidLoad() {
        super.viewDidLoad()
          photosLibraryVC = self.storyboard?.instantiateViewController(withIdentifier:"PhotosLibraryVC") as? PhotosLibraryVC
          photosLibraryVC?.photosLibraryVCDelegate = self

        // Do any additional setup after loading the view.
    }
    
    func didUpdateSelectedImages(images: [UIImage]) {
        print(images)
        imagesArray = images
    }
    
    @IBAction func makeVideo(_ sender: AnyObject) {
        VideoGenerator.current.generate(withImages: self.imagesArray, andAudios: [], andType: .multiple, { (progress) in
        }, success: { (outPutURL) in
            DispatchQueue.main.async {
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
        }, failure: { (error) in
        })
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
