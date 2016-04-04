//
//  Push.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-01.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectiveC

#if os(OSX)
    import Cocoa
#endif

/// Class used to register and unregister a device to receive push notifications.
@objc(KNVPush)
public class Push: NSObject {
    
    public typealias BoolCompletionHandler = (Bool, ErrorType?) -> Void
    
    private let client: Client
    
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

#if os(iOS)
    /// Sets and returns the number for the icon badge for the current running app.
    public var badgeNumber: Int {
        get {
            return UIApplication.sharedApplication().applicationIconBadgeNumber
        }
        set {
            let app = UIApplication.sharedApplication()
            guard app.applicationIconBadgeNumber == newValue else {
                return
            }
            app.applicationIconBadgeNumber = newValue
        }
    }
    
    private typealias ApplicationDidRegisterForRemoteNotificationsWithDeviceTokenImplementation = @convention(c) (NSObject, Selector, UIApplication, NSData) -> Void
    private typealias ApplicationDidFailToRegisterForRemoteNotificationsWithErrorImplementation = @convention(c) (NSObject, Selector, UIApplication, NSError) -> Void
#endif
    
    private var originalApplicationDidRegisterForRemoteNotificationsWithDeviceTokenImplementation: IMP?
    private var originalApplicationDidFailToRegisterForRemoteNotificationsWithErrorImplementation: IMP?

#if os(iOS)
    private func replaceAppDelegateMethods(completionHandler: BoolCompletionHandler?) {
        let app = UIApplication.sharedApplication()
        guard let appDelegate = app.delegate else { return }
        let appDelegateType = appDelegate.dynamicType
        
        let applicationDidRegisterForRemoteNotificationsWithDeviceTokenSelector = #selector(UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:))
        let applicationDidFailToRegisterForRemoteNotificationsWithErrorSelector = #selector(UIApplicationDelegate.application(_:didFailToRegisterForRemoteNotificationsWithError:))
        
        let originalApplicationDidRegisterForRemoteNotificationsWithDeviceTokenMethod = class_getInstanceMethod(appDelegateType, applicationDidRegisterForRemoteNotificationsWithDeviceTokenSelector)
        let originalApplicationDidFailToRegisterForRemoteNotificationsWithErrorMethod = class_getInstanceMethod(appDelegateType, applicationDidFailToRegisterForRemoteNotificationsWithErrorSelector)
        
        let applicationDidRegisterForRemoteNotificationsWithDeviceTokenBlock: @convention(block) (NSObject, UIApplication, NSData) -> Void = { obj, application, deviceToken in
            self.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken, completionHandler: completionHandler)
            
            if let originalApplicationDidRegisterForRemoteNotificationsWithDeviceTokenImplementation = self.originalApplicationDidRegisterForRemoteNotificationsWithDeviceTokenImplementation {
                let implementation = unsafeBitCast(originalApplicationDidRegisterForRemoteNotificationsWithDeviceTokenImplementation, ApplicationDidRegisterForRemoteNotificationsWithDeviceTokenImplementation.self)
                implementation(obj, applicationDidRegisterForRemoteNotificationsWithDeviceTokenSelector, application, deviceToken)
            }
        }
        
        let originalApplicationDidFailToRegisterForRemoteNotificationsWithErrorBlock: @convention(block) (NSObject, UIApplication, NSError) -> Void = { obj, application, error in
            if let originalApplicationDidFailToRegisterForRemoteNotificationsWithErrorImplementation = self.originalApplicationDidFailToRegisterForRemoteNotificationsWithErrorImplementation {
                let implementation = unsafeBitCast(originalApplicationDidFailToRegisterForRemoteNotificationsWithErrorImplementation, ApplicationDidFailToRegisterForRemoteNotificationsWithErrorImplementation.self)
                implementation(obj, applicationDidFailToRegisterForRemoteNotificationsWithErrorSelector, application, error)
            }
        }
        
        let applicationDidRegisterForRemoteNotificationsWithDeviceTokenImplementation = imp_implementationWithBlock(unsafeBitCast(applicationDidRegisterForRemoteNotificationsWithDeviceTokenBlock, AnyObject.self))
        let applicationDidFailToRegisterForRemoteNotificationsWithErrorImplementation = imp_implementationWithBlock(unsafeBitCast(originalApplicationDidFailToRegisterForRemoteNotificationsWithErrorBlock, AnyObject.self))
        
        if originalApplicationDidRegisterForRemoteNotificationsWithDeviceTokenMethod == nil {
            class_addMethod(appDelegateType, applicationDidRegisterForRemoteNotificationsWithDeviceTokenSelector, applicationDidRegisterForRemoteNotificationsWithDeviceTokenImplementation, method_getTypeEncoding(originalApplicationDidRegisterForRemoteNotificationsWithDeviceTokenMethod))
            
        } else {
            self.originalApplicationDidRegisterForRemoteNotificationsWithDeviceTokenImplementation = method_setImplementation(originalApplicationDidRegisterForRemoteNotificationsWithDeviceTokenMethod, applicationDidRegisterForRemoteNotificationsWithDeviceTokenImplementation)
        }
        
        if originalApplicationDidFailToRegisterForRemoteNotificationsWithErrorMethod == nil {
            class_addMethod(appDelegateType, applicationDidFailToRegisterForRemoteNotificationsWithErrorSelector, applicationDidFailToRegisterForRemoteNotificationsWithErrorImplementation, method_getTypeEncoding(originalApplicationDidFailToRegisterForRemoteNotificationsWithErrorMethod))
        } else {
            self.originalApplicationDidFailToRegisterForRemoteNotificationsWithErrorImplementation = method_setImplementation(originalApplicationDidFailToRegisterForRemoteNotificationsWithErrorMethod, applicationDidFailToRegisterForRemoteNotificationsWithErrorImplementation)
        }
    }
    
    private var initializeToken: dispatch_once_t = 0
    
    /**
     Register for remote notifications.
     Call this in your implementation for updating the registration in case the device tokens change.
     
     ```
     func applicationDidBecomeActive(application: UIApplication) {
         Kinvey.sharedClient.push.registerForPush()
     }
     ```
     */
    public func registerForPush(completionHandler: BoolCompletionHandler? = nil) {
        dispatch_once(&self.initializeToken) {
            if NSThread.isMainThread() {
                self.replaceAppDelegateMethods(completionHandler)
            } else {
                dispatch_sync(dispatch_get_main_queue()) {
                    self.replaceAppDelegateMethods(completionHandler)
                }
            }
        }
        
        let app = UIApplication.sharedApplication()
        let userNotificationSettings = UIUserNotificationSettings(
            forTypes: [
                UIUserNotificationType.Alert,
                UIUserNotificationType.Badge,
                UIUserNotificationType.Sound
            ],
            categories: nil
        )
        app.registerUserNotificationSettings(userNotificationSettings)
        app.registerForRemoteNotifications()
    }
#endif
    
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
#if os(iOS)
    private func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData, completionHandler: BoolCompletionHandler? = nil) {
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
    
    /// Resets the badge number to zero.
    public func resetBadgeNumber() {
        badgeNumber = 0
    }
#endif
    
    
}
