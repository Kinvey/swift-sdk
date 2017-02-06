//
//  AppDelegate.swift
//  SSOApp2
//
//  Created by Victor Hugo on 2016-11-10.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import UIKit
import Kinvey

let micRedirectURI = URL(string: "ssoApp2://")!

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var completionHandler: User.UserHandler<User>? {
        didSet {
            if let result = result {
                completionHandler?(result.user, result.error)
            }
        }
    }
    
    var result: (user: User?, error: Swift.Error?)? {
        didSet {
            if let result = result {
                completionHandler?(result.user, result.error)
            }
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let envs = ProcessInfo.processInfo.environment
        let unitTesting = envs["KINVEY_APP_KEY"] == nil && envs["KINVEY_APP_SECRET"] == nil
        if !unitTesting {
            initializeKinvey()
        }
        
        return true
    }
    
    func initializeKinvey() {
        Kinvey.sharedClient.initialize(appKey: "appKey", appSecret: "appSecret", accessGroup: "5W7CYNR7UE.com.kinvey.SSOApp") { user, error in
            self.result = (user: user, error: error)
            if let user = user  {
                print("User: \(user)")
            }
        }
    }
    
    func discardLocalCachedUser(completionHandler: @escaping User.UserHandler<User>) {
        Kinvey.sharedClient.initialize(appKey: "appKey", appSecret: "appSecret", completionHandler: completionHandler)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

