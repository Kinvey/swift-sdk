//
//  ViewController.swift
//  SSOApp1
//
//  Created by Victor Hugo on 2016-11-10.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import UIKit
import Kinvey

class ViewController: UIViewController {
    
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var labelUser: UILabel!
    
    var micUserInterface: MICUserInterface = .safari
    
    var completionHandler: User.UserHandler<User>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        signInButton.accessibilityLabel = "Sign In"
        signInButton.accessibilityIdentifier = "Sign In"
        
        loadUserInfo()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func signIn(_ sender: Any) {
        if let user = Kinvey.sharedClient.activeUser {
            user.logout()
            self.loadUserInfo()
        } else {
            Kinvey.sharedClient.micApiVersion = .v3
            URLCache.shared.removeAllCachedResponses()
            User.presentMICViewController(
                redirectURI: micRedirectURI,
                micUserInterface: micUserInterface,
                clientId: clientId
            ) { user, error in
                self.completionHandler?(user, error)
                if let user = user {
                    self.display(title: "Success", message: "User: \(user)")
                } else {
                    self.display(title: "Failure", message: "Error: \(error!)")
                }
                self.loadUserInfo()
            }
        }
    }
    
    func display(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
    func loadUserInfo() {
        if let user = Kinvey.sharedClient.activeUser {
            labelUser.text = "User: \(user.userId)"
            signInButton.setTitle("Logout", for: .normal)
        } else {
            labelUser.text = ""
            signInButton.setTitle("Sign In", for: .normal)
        }
    }

}
