//
//  FilesUploadViewController.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-01-30.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import UIKit
import Kinvey
import MobileCoreServices
import AVFoundation
import AVKit

class UploadAndPlayVideoViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var progressView: UIProgressView!
    
    lazy var fileStore = FileStore()
    var file: File?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func uploadFile(_ sender: Any) {
        let videoPicker = UIImagePickerController()
        videoPicker.delegate = self
        videoPicker.sourceType = .photoLibrary
        videoPicker.mediaTypes = [kUTTypeMovie as String]
        present(videoPicker, animated: true)
    }
    
    @IBAction func playFile(_ sender: Any) {
        if let file = file {
            let player = AVPlayer(url: file.downloadURL!)
            let playerVC = AVPlayerViewController()
            playerVC.player = player
            player.play()
            self.present(playerVC, animated: true)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let url = info[UIImagePickerControllerMediaURL] as? URL {
            let file = File()
            file.mimeType = "video/mp4"
            self.progressView.progress = 0
            fileStore.upload(file, path: url.path) { file, error in
                if let file = file {
                    self.file = file
                    print("File Uploaded: \(String(describing: file.downloadURL))")
                } else {
                    let alertVC = UIAlertController(title: "Error", message: error?.localizedDescription ?? "Unknow error", preferredStyle: .alert)
                    self.present(alertVC, animated: true)
                }
            }
        }
        picker.dismiss(animated: true)
    }
    
}
