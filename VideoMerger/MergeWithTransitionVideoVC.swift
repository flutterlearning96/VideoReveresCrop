//
//  MergeWithTransitionVideoVC.swift
//  VideoMerger
//
//  Created by Hiren Patel on 15/04/19.
//  Copyright © 2019 Hiren Patel. All rights reserved.
//

import UIKit
import MobileCoreServices
import MediaPlayer
import Photos

class MergeWithTransitionVideoVC: MergeVideoVC {
    
    @IBOutlet var btnLoadVideo2: UIButton!

    override func viewDidLoad() {
        
        self.btnLoadVideo2.clipsToBounds = true
        self.btnLoadVideo2.layer.cornerRadius = 25
        super.viewDidLoad()
    }
}
