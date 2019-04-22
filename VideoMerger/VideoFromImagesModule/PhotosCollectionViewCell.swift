//
//  PhotosCollectionViewCell.swift
//  Filters
//
//  Created by Soham Bhattacharjee on 10/02/17.
//  
//

import UIKit
class PhotosCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var livePhotoBadgeImageView: UIImageView!
    @IBOutlet var blurView: UIVisualEffectView!
    @IBOutlet var lblPhotoCount: UILabel!
    var representedAssetIdentifier: String!
    
    var thumbnailImage: UIImage! {
        didSet {
            imageView.image = thumbnailImage
        }
    }
    var livePhotoBadgeImage: UIImage! {
        didSet {
            livePhotoBadgeImageView.image = livePhotoBadgeImage
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        livePhotoBadgeImageView.image = nil
    }
}
