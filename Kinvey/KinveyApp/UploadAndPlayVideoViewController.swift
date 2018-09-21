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
    
    @available(*, deprecated)
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        if let url = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.mediaURL)] as? URL {
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

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
