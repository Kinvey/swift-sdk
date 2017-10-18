//
//  PullDataStoreViewController.swift
//  KinveyApp
//
//  Created by Victor Hugo Carvalho Barros on 2017-10-16.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import UIKit
import Kinvey

class PullDataStoreViewController: UIViewController {
    
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var timeoutSlider: UISlider!
    @IBOutlet weak var timeoutLabel: UILabel!
    
    @IBAction func timeoutValueChanged(_ sender: Any) {
        timeoutLabel.text = String(Int(round(timeoutSlider.value)))
    }
    
    var timer: Timer? {
        willSet {
            timer?.invalidate()
        }
    }
    
    var startTime: CFAbsoluteTime?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Kinvey.sharedClient.initialize(
            appKey: "kid_B15Lb5Pl-",
            appSecret: "be64651eceb54bb58e47425db0b3918b",
            apiHostName: URL(string: "https://stg-us1-baas.kinvey.com")!
        ) {
            switch $0 {
            case .success(let user):
                if let user = user {
                    print(user)
                } else {
                    User.signup(options: nil) {
                        switch $0 {
                        case .success(let user):
                            print(user)
                        case .failure(let error):
                            print(error)
                        }
                    }
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    lazy var dataStore = DataStore<HierarchyCache>.collection(.sync, autoPagination: true)
    var progress: Progress?
    
    @objc func updateTimer() {
        let seconds = CFAbsoluteTimeGetCurrent() - startTime!
        self.timerLabel.text = String(format: "%2.1f second(s)", seconds)
    }
    
    @IBAction func pullDataStore(_ sender: Any) {
        startTime = CFAbsoluteTimeGetCurrent()
        Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        let options = Options(timeout: TimeInterval(round(timeoutSlider.value)))
        progress = dataStore.pull(options: options) {
            self.timer = nil
            switch $0 {
            case .success(let results):
                print(results.count)
            case .failure(let error):
                print(error)
            }
        }
        progress?.addObserver(self, forKeyPath: "fractionCompleted", options: [.initial, .new], context: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let progress = progress {
            progress.removeObserver(self, forKeyPath: "fractionCompleted")
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let progress = object as? Progress, progress == self.progress {
            progressView.progress = Float(progress.fractionCompleted)
        }
    }
    
}
