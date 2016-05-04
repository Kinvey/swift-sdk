//
//  ViewController.swift
//  BuSber Driver
//
//  Created by Victor Barros on 2016-05-04.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import UIKit
import Kinvey

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        if let _ = Kinvey.sharedClient.activeUser {
            performSegueWithIdentifier("loginNoAnimation", sender: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        switch identifier {
        case "login":
            User.login(username: "driver", password: "driver") { user, error in
                if let _ = user {
                    self.performSegueWithIdentifier(identifier, sender: sender)
                }
            }
            return false
        default:
            return true
        }
    }


}

