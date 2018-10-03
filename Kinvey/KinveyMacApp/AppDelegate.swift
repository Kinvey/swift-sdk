//
//  AppDelegate.swift
//  KinveyMacApp
//
//  Created by Victor Hugo on 2017-05-31.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import Cocoa
import Kinvey

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    static let appKey = ProcessInfo.processInfo.environment["KINVEY_APP_KEY"]
    static let appSecret = ProcessInfo.processInfo.environment["KINVEY_APP_SECRET"]
    static let hostUrl: URL? = {
        guard let hostUrl = ProcessInfo.processInfo.environment["KINVEY_HOST_URL"] else {
            return nil
        }
        return URL(string: hostUrl)
    }()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let appKey = AppDelegate.appKey,
            let appSecret = AppDelegate.appSecret
        {
            Kinvey.sharedClient.initialize(
                appKey: appKey,
                appSecret: appSecret,
                apiHostName: AppDelegate.hostUrl ?? Client.defaultApiHostName
            ) { user, error in
                if let user = user {
                    print("user: \(user)")
                }
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

}
