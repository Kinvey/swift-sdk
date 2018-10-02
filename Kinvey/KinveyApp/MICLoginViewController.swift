//
//  ViewController.swift
//  KinveyApp
//
//  Created by Victor Barros on 2016-03-14.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import UIKit
import Kinvey
import WebKit

open class MICLoginViewController: UIViewController {

    @IBOutlet weak var userIdLabel: UILabel!
    @IBOutlet weak var micUserInterfaceSegmentedControl: UISegmentedControl!
    @IBOutlet weak var safariViewControllerSwitch: UISwitch!
    @IBOutlet weak var sfAuthenticationSessionSwitch: UISwitch!
    @IBOutlet weak var wkWebViewSwitch: UISwitch!
    @IBOutlet weak var uiWebViewSwitch: UISwitch!
    @IBOutlet weak var textFieldDelay: UITextField!
    
    @available(*, deprecated)
    open var completionHandler: User.UserHandler<User>?
    
    var delay: Int = 0 {
        didSet {
            textFieldDelay.text = String(delay)
        }
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        let toolbar = UIToolbar()
        toolbar.items = [
            UIBarButtonItem(
                barButtonSystemItem: .flexibleSpace,
                target: nil,
                action: nil
            ),
            UIBarButtonItem(
                barButtonSystemItem: .done,
                target: self,
                action: #selector(doneEditing)
            )
        ]
        toolbar.sizeToFit()
        textFieldDelay.inputView = toolbar
        
        if let appKey = ProcessInfo.processInfo.environment["KINVEY_MIC_APP_KEY"],
            let appSecret = ProcessInfo.processInfo.environment["KINVEY_MIC_APP_SECRET"]
        {
            var apiUrl: URL? = nil
            if let apiUrlString = ProcessInfo.processInfo.environment["KINVEY_MIC_API_URL"] {
                apiUrl = URL(string: apiUrlString)
            }
            
            var authUrl: URL? = nil
            if let authUrlString = ProcessInfo.processInfo.environment["KINVEY_MIC_AUTH_URL"] {
                authUrl = URL(string: authUrlString)
            }
            
            Kinvey.sharedClient.initialize(
                appKey: appKey,
                appSecret: appSecret,
                apiHostName: apiUrl ?? Client.defaultApiHostName,
                authHostName: authUrl ?? Client.defaultAuthHostName
            ) {
                switch $0 {
                case .success(let user):
                    if let user = user {
                        print(user)
                    }
                case .failure(let error):
                    print(error)
                }
            }
        }
    }

    @IBAction func doneEditing() {
        textFieldDelay.resignFirstResponder()
    }
    
    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func dismiss(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }

    @available(*, deprecated)
    @IBAction func login(_ sender: UIButton) {
        URLCache.shared.removeAllCachedResponses()
        HTTPCookieStorage.shared.removeCookies(since: Date(timeIntervalSince1970: 0))
        WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: Date(timeIntervalSince1970: 0), completionHandler: {})
        
        var micUserInterface: MICUserInterface!
        switch micUserInterfaceSegmentedControl.selectedSegmentIndex {
        case 0:
            micUserInterface = .safari
        case 1:
            micUserInterface = .safariAuthenticationSession
        case 2:
            micUserInterface = .wkWebView
        case 3:
            micUserInterface = .uiWebView
        default:
            micUserInterface = MICUserInterface.default
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(delay)) {
            User.presentMICViewController(redirectURI: redirectURI, micUserInterface: micUserInterface) {
                switch $0 {
                case .success(let user):
                    self.userIdLabel.text = user.userId
                    self.completionHandler?(user, nil)
                case .failure(let error):
                    self.userIdLabel.text = ""
                    print("\(error)")
                    self.completionHandler?(nil, error)
                }
            }
        }
    }
    
    @IBAction func micUserInterfaceChanged(_ sender: UISegmentedControl) {
        safariViewControllerSwitch.setOn(sender.selectedSegmentIndex == 0, animated: true)
        sfAuthenticationSessionSwitch.setOn(sender.selectedSegmentIndex == 1, animated: true)
        wkWebViewSwitch.setOn(sender.selectedSegmentIndex == 2, animated: true)
        uiWebViewSwitch.setOn(sender.selectedSegmentIndex == 3, animated: true)
    }
    
    @IBAction func safariViewControllerSwitchValueChanged(_ sender: UISwitch) {
        micUserInterfaceSegmentedControl.selectedSegmentIndex = 0
        micUserInterfaceChanged(micUserInterfaceSegmentedControl)
    }
    
    @IBAction func sfAuthenticationSessionSwitchValueChanged(_ sender: UISwitch) {
        micUserInterfaceSegmentedControl.selectedSegmentIndex = 1
        micUserInterfaceChanged(micUserInterfaceSegmentedControl)
    }
    
    @IBAction func wkWebViewSwitchValueChanged(_ sender: UISwitch) {
        micUserInterfaceSegmentedControl.selectedSegmentIndex = 2
        micUserInterfaceChanged(micUserInterfaceSegmentedControl)
    }
    
    @IBAction func uiWebViewSwitchValueChanged(_ sender: UISwitch) {
        micUserInterfaceSegmentedControl.selectedSegmentIndex = 3
        micUserInterfaceChanged(micUserInterfaceSegmentedControl)
    }
    
    @IBAction func stepperValueChanged(_ sender: UIStepper) {
        delay = Int(sender.value)
    }

}

extension MICLoginViewController : UITextFieldDelegate {
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == textFieldDelay,
            let delayString = textField.text,
            let delay = Int(delayString)
        {
            self.delay = delay
        }
    }
    
}
