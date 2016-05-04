//
//  ViewController.swift
//  BuSber
//
//  Created by Victor Barros on 2016-05-03.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import UIKit
import Kinvey

class LoginViewController: UIViewController {

    @IBOutlet weak var userTextField: UITextField!
    @IBOutlet weak var passTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        switch identifier {
        case "login":
            User.login(username: userTextField.text!, password: passTextField.text!) { user, error in
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

