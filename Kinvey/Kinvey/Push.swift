//
//  Push.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-01.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import KinveyKit
import PromiseKit
import KeychainAccess

public class Push {
    
    public typealias BoolCompletionHandler = (Bool, ErrorType?) -> Void
    
    private let client: Client
    private let push: KCSPush = KCSPush.sharedPush()
    private var keychain:Keychain {
        get {
            return Keychain(service: "com.kinvey.KinveyKit.\(client.appKey!)")
        }
    }
    
    private static let authTokenKey = "authToken"
    
    private var deviceToken: NSData? {
        get {
            return keychain[data: Push.authTokenKey]
        }
        set {
            keychain[data: Push.authTokenKey] = newValue
        }
    }
    
    init(client: Client) {
        self.client = client
        deviceToken = keychain[data: Push.authTokenKey]
    }
    
    public func registerForPush() {
        KCSPush.registerForPush()
    }
    
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
    
    public func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        push.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }
    
    public func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        push.application(application, didReceiveRemoteNotification: userInfo)
    }
    
}
