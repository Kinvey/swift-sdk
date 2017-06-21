//
//  AppDelegate.swift
//  KinveyApp
//
//  Created by Victor Barros on 2016-03-14.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import UIKit
import Kinvey

let redirectURI = URL(string: "kinveyAuthDemo://")!

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    static let appKey = ProcessInfo.processInfo.environment["KINVEY_APP_KEY"]
    static let appSecret = ProcessInfo.processInfo.environment["KINVEY_APP_SECRET"]
    static let hostUrl: URL? = {
        guard let hostUrl = ProcessInfo.processInfo.environment["KINVEY_HOST_URL"] else {
            return nil
        }
        return URL(string: hostUrl)
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        // Override point for customization after application launch.
        
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
        
//        if #available(iOS 10.0, *) {
//            Kinvey.sharedClient.push.registerForNotifications { (succeed, error) in
//                print("succeed: \(succeed)")
//                if let error = error {
//                    print("error: \(error)")
//                }
//            }
//        } else {
//            Kinvey.sharedClient.push.registerForPush { (succeed, error) in
//                print("succeed: \(succeed)")
//                if let error = error {
//                    print("error: \(error)")
//                }
//            }
//        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        if User.login(redirectURI: redirectURI, micURL: url) {
            return true
        }
        
        return false
    }

}
