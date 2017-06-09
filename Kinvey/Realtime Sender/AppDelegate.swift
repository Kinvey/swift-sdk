//
//  AppDelegate.swift
//  Realtime Sender
//
//  Created by Victor Hugo on 2017-06-09.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let processInfo = ProcessInfo.processInfo
        print("\(processInfo.environment.map({ "\t\($0.key)=\"\($0.value)\" \\\n" }).joined(separator: " ")) \(processInfo.arguments.map({ "\"\($0)\"" }).joined(separator: " "))")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

