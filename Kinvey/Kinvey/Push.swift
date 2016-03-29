//
//  Push.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-01.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import PromiseKit

/// Class used to register and unregister a device to receive push notifications.
@objc(KNVPush)
public class Push: NSObject {
    
    public typealias BoolCompletionHandler = (Bool, ErrorType?) -> Void
    
    private let client: Client
    private let push: KCSPush = KCSPush.sharedPush()
    
    private var keychain: Keychain {
        get {
            return Keychain(appKey: client.appKey!)
        }
    }
    
    private var deviceToken: NSData? {
        get {
            return keychain.deviceToken
        }
        set {
            keychain.deviceToken = newValue
        }
    }
    
    init(client: Client) {
        self.client = client
    }
    
    /// Call this method as the 1st step to register the current device to receive push notifications.
    public func registerForPush() {
        KCSPush.registerForPush()
    }
    
    /// Unregister the current device to receive push notifications.
    public func unRegisterDeviceToken(completionHandler: BoolCompletionHandler? = nil) {
        guard let deviceToken = deviceToken else {
            fatalError("Device token not found")
        }
        
        Promise<Bool> { fulfill, reject in
            let request = self.client.networkRequestFactory.buildPushUnRegisterDevice(deviceToken)
            request.execute({ (data, response, error) -> Void in
                if let response = response where response.isResponseOK {
                    fulfill(true)
                } else if let error = error {
                    reject(error)
                } else {
                    reject(Error.InvalidResponse)
                }
            })
        }.then { success in
            completionHandler?(success, nil)
        }.error { error in
            completionHandler?(false, error)
        }
    }
    
    /// Call this method inside your App Delegate method `application(application:didRegisterForRemoteNotificationsWithDeviceToken:completionHandler:)`.
    public func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData, completionHandler: BoolCompletionHandler? = nil) {
        self.deviceToken = deviceToken
        Promise<Bool> { fulfill, reject in
            let request = self.client.networkRequestFactory.buildPushRegisterDevice(deviceToken)
            request.execute({ (data, response, error) -> Void in
                if let response = response where response.isResponseOK {
                    fulfill(true)
                } else if let error = error {
                    reject(error)
                } else {
                    reject(Error.InvalidResponse)
                }
            })
        }.then { success in
            completionHandler?(success, nil)
        }.error { error in
            completionHandler?(false, error)
        }
    }
    
    /// Call this method inside your App Delegate method `application(application:didFailToRegisterForRemoteNotificationsWithError:)`.
    public func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        push.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }
    
    /// Call this method inside your App Delegate method `application(application:didReceiveRemoteNotification:)`.
    public func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        push.application(application, didReceiveRemoteNotification: userInfo)
    }
    
}
