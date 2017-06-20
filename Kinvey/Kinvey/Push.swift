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
#elseif os(iOS)
    import UIKit
    import UserNotifications
#else
    import UserNotifications
#endif

/// Class used to register and unregister a device to receive push notifications.
open class Push {
    
    public typealias BoolCompletionHandler = (Bool, Swift.Error?) -> Void
    
    fileprivate let client: Client
    
    fileprivate var keychain: Keychain {
        get {
            return Keychain(appKey: client.appKey!, client: client)
        }
    }
    
    internal var deviceToken: Data? {
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
    open var badgeNumber: Int {
        get {
            return UIApplication.shared.applicationIconBadgeNumber
        }
        set {
            UIApplication.shared.applicationIconBadgeNumber = newValue
        }
    }
    
    fileprivate typealias ApplicationDidRegisterForRemoteNotificationsWithDeviceTokenImplementation = @convention(c) (NSObject, Selector, UIApplication, Data) -> Void
    fileprivate typealias ApplicationDidFailToRegisterForRemoteNotificationsWithErrorImplementation = @convention(c) (NSObject, Selector, UIApplication, NSError) -> Void
#endif
    
    fileprivate var originalApplicationDidRegisterForRemoteNotificationsWithDeviceTokenImplementation: IMP?
    fileprivate var originalApplicationDidFailToRegisterForRemoteNotificationsWithErrorImplementation: IMP?

#if os(iOS)
    
    fileprivate var initializeToken: Int = 0
    
    private static let lock = NSLock()
    private static var appDelegateMethodsNeedsToRun = true
    
    private func replaceAppDelegateMethods(
        options: Options?,
        completionHandler: ((Result<Bool, Swift.Error>) -> Void)?
    ) {
        func replaceAppDelegateMethods(_ completionHandler: ((Result<Bool, Swift.Error>) -> Void)?) {
            let app = UIApplication.shared
            let appDelegate = app.delegate!
            let appDelegateType = type(of: appDelegate)
            
            let applicationDidRegisterForRemoteNotificationsWithDeviceTokenSelector = #selector(UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:))
            let applicationDidFailToRegisterForRemoteNotificationsWithErrorSelector = #selector(UIApplicationDelegate.application(_:didFailToRegisterForRemoteNotificationsWithError:))
            
            let originalApplicationDidRegisterForRemoteNotificationsWithDeviceTokenMethod = class_getInstanceMethod(appDelegateType, applicationDidRegisterForRemoteNotificationsWithDeviceTokenSelector)
            let originalApplicationDidFailToRegisterForRemoteNotificationsWithErrorMethod = class_getInstanceMethod(appDelegateType, applicationDidFailToRegisterForRemoteNotificationsWithErrorSelector)
            
            let applicationDidRegisterForRemoteNotificationsWithDeviceTokenBlock: @convention(block) (NSObject, UIApplication, Data) -> Void = { obj, application, deviceToken in
                self.application(
                    application,
                    didRegisterForRemoteNotificationsWithDeviceToken: deviceToken,
                    options: options,
                    completionHandler: completionHandler
                )
                
                if let originalApplicationDidRegisterForRemoteNotificationsWithDeviceTokenImplementation = self.originalApplicationDidRegisterForRemoteNotificationsWithDeviceTokenImplementation {
                    let implementation = unsafeBitCast(originalApplicationDidRegisterForRemoteNotificationsWithDeviceTokenImplementation, to: ApplicationDidRegisterForRemoteNotificationsWithDeviceTokenImplementation.self)
                    implementation(obj, applicationDidRegisterForRemoteNotificationsWithDeviceTokenSelector, application, deviceToken)
                }
            }
            
            let originalApplicationDidFailToRegisterForRemoteNotificationsWithErrorBlock: @convention(block) (NSObject, UIApplication, NSError) -> Void = { obj, application, error in
                if let originalApplicationDidFailToRegisterForRemoteNotificationsWithErrorImplementation = self.originalApplicationDidFailToRegisterForRemoteNotificationsWithErrorImplementation {
                    let implementation = unsafeBitCast(originalApplicationDidFailToRegisterForRemoteNotificationsWithErrorImplementation, to: ApplicationDidFailToRegisterForRemoteNotificationsWithErrorImplementation.self)
                    implementation(obj, applicationDidFailToRegisterForRemoteNotificationsWithErrorSelector, application, error)
                }
            }
            
            let applicationDidRegisterForRemoteNotificationsWithDeviceTokenImplementation = imp_implementationWithBlock(unsafeBitCast(applicationDidRegisterForRemoteNotificationsWithDeviceTokenBlock, to: AnyObject.self))
            let applicationDidFailToRegisterForRemoteNotificationsWithErrorImplementation = imp_implementationWithBlock(unsafeBitCast(originalApplicationDidFailToRegisterForRemoteNotificationsWithErrorBlock, to: AnyObject.self))
            
            if originalApplicationDidRegisterForRemoteNotificationsWithDeviceTokenMethod == nil {
                let result = class_addMethod(appDelegateType, applicationDidRegisterForRemoteNotificationsWithDeviceTokenSelector, applicationDidRegisterForRemoteNotificationsWithDeviceTokenImplementation, method_getTypeEncoding(originalApplicationDidRegisterForRemoteNotificationsWithDeviceTokenMethod))
                assert(result)
            } else {
                self.originalApplicationDidRegisterForRemoteNotificationsWithDeviceTokenImplementation = method_setImplementation(originalApplicationDidRegisterForRemoteNotificationsWithDeviceTokenMethod, applicationDidRegisterForRemoteNotificationsWithDeviceTokenImplementation)
            }
            
            if originalApplicationDidFailToRegisterForRemoteNotificationsWithErrorMethod == nil {
                let result = class_addMethod(appDelegateType, applicationDidFailToRegisterForRemoteNotificationsWithErrorSelector, applicationDidFailToRegisterForRemoteNotificationsWithErrorImplementation, method_getTypeEncoding(originalApplicationDidFailToRegisterForRemoteNotificationsWithErrorMethod))
                assert(result)
            } else {
                self.originalApplicationDidFailToRegisterForRemoteNotificationsWithErrorImplementation = method_setImplementation(originalApplicationDidFailToRegisterForRemoteNotificationsWithErrorMethod, applicationDidFailToRegisterForRemoteNotificationsWithErrorImplementation)
            }
        }
        
        Push.lock.lock()
        if Push.appDelegateMethodsNeedsToRun {
            if Thread.isMainThread {
                replaceAppDelegateMethods(completionHandler)
            } else {
                DispatchQueue.main.sync {
                    replaceAppDelegateMethods(completionHandler)
                }
            }
            Push.appDelegateMethodsNeedsToRun = false
        }
        Push.lock.unlock()
    }
    
    /**
     Register for remote notifications.
     Call this in your implementation for updating the registration in case the device tokens change.
     
     ```
     func applicationDidBecomeActive(application: UIApplication) {
         Kinvey.sharedClient.push.registerForPush()
     }
     ```
     */
    @available(iOS, deprecated: 10.0, message: "Please use registerForNotifications() instead")
    open func registerForPush(
        forTypes types: UIUserNotificationType = [.alert, .badge, .sound],
        categories: Set<UIUserNotificationCategory>? = nil,
        completionHandler: BoolCompletionHandler? = nil
    ) {
        registerForPush(
            forTypes: types,
            categories: categories
        ) { (result: Result<Bool, Swift.Error>) in
            switch result {
            case .success(let granted):
                completionHandler?(granted, nil)
            case .failure(let error):
                completionHandler?(false, error)
            }
        }
    }
    
    /**
     Register for remote notifications.
     Call this in your implementation for updating the registration in case the device tokens change.
     
     ```
     func applicationDidBecomeActive(application: UIApplication) {
     Kinvey.sharedClient.push.registerForPush()
     }
     ```
     */
    @available(iOS, deprecated: 10.0, message: "Please use registerForNotifications() instead")
    open func registerForPush(
        forTypes types: UIUserNotificationType = [.alert, .badge, .sound],
        categories: Set<UIUserNotificationCategory>? = nil,
        completionHandler: ((Result<Bool, Swift.Error>) -> Void)? = nil
    ) {
        replaceAppDelegateMethods(
            options: Options(
                client: client
            ),
            completionHandler: completionHandler
        )
        
        let app = UIApplication.shared
        let userNotificationSettings = UIUserNotificationSettings(
            types: types,
            categories: categories
        )
        app.registerUserNotificationSettings(userNotificationSettings)
        app.registerForRemoteNotifications()
    }
    
    @available(iOS 10.0, *)
    open func registerForNotifications(
        authorizationOptions: UNAuthorizationOptions = [.badge, .sound, .alert, .carPlay],
        categories: Set<UNNotificationCategory>? = nil,
        completionHandler: BoolCompletionHandler? = nil
    ) {
        registerForNotifications(
            authorizationOptions: authorizationOptions,
            categories: categories,
            options: Options(
                client: client
            )
        ) { (result: Result<Bool, Swift.Error>) in
            switch result {
            case .success(let granted):
                completionHandler?(granted, nil)
            case .failure(let error):
                completionHandler?(false, error)
            }
        }
    }
    
    @available(iOS 10.0, *)
    open func registerForNotifications(
        authorizationOptions: UNAuthorizationOptions = [.badge, .sound, .alert, .carPlay],
        categories: Set<UNNotificationCategory>? = nil,
        completionHandler: ((Result<Bool, Swift.Error>) -> Void)? = nil
    ) {
        return registerForNotifications(
            authorizationOptions: authorizationOptions,
            categories: categories,
            options: Options(
                client: client
            ),
            completionHandler: completionHandler
        )
    }
    
    @available(iOS 10.0, *)
    open func registerForNotifications(
        authorizationOptions: UNAuthorizationOptions = [.badge, .sound, .alert, .carPlay],
        categories: Set<UNNotificationCategory>? = nil,
        options: Options? = nil,
        completionHandler: ((Result<Bool, Swift.Error>) -> Void)? = nil
    ) {
        UNUserNotificationCenter.current().requestAuthorization(options: authorizationOptions) { granted, error in
            if granted {
                if let categories = categories {
                    UNUserNotificationCenter.current().setNotificationCategories(categories)
                }
                self.replaceAppDelegateMethods(
                    options: options,
                    completionHandler: completionHandler
                )
                UIApplication.shared.registerForRemoteNotifications()
            } else {
                if let error = error {
                    completionHandler?(.failure(error))
                } else {
                    completionHandler?(.success(granted))
                }
            }
        }
    }
#endif
    
    /// Unregister the current device to receive push notifications.
    open func unRegisterDeviceToken(
        _ completionHandler: BoolCompletionHandler? = nil
    ) {
        unRegisterDeviceToken(
            options: Options(
                client: client
            )
        ) { (result: Result<Void, Swift.Error>) in
            switch result {
            case .success:
                completionHandler?(true, nil)
            case .failure(let error):
                completionHandler?(false, error)
            }
        }
    }
    
    /// Unregister the current device to receive push notifications.
    open func unRegisterDeviceToken(
        _ completionHandler: ((Result<Void, Swift.Error>) -> Void)? = nil
    ) {
        return unRegisterDeviceToken(
            options: Options(
                client: client
            ),
            completionHandler: completionHandler
        )
    }
    
    /// Unregister the current device to receive push notifications.
    open func unRegisterDeviceToken(
        options: Options? = nil,
        completionHandler: ((Result<Void, Swift.Error>) -> Void)? = nil
    ) {
        Promise<Void> { fulfill, reject in
            guard let deviceToken = deviceToken else {
                reject(Error.invalidOperation(description: "Device token not found"))
                return
            }
            
            let request = self.client.networkRequestFactory.buildPushUnRegisterDevice(
                deviceToken,
                options: options
            )
            request.execute { (data, response, error) -> Void in
                if let response = response,
                    response.isOK
                {
                    self.deviceToken = nil
                    fulfill()
                } else {
                    reject(buildError(data, response, error, self.client))
                }
            }
        }.then { success in
            completionHandler?(.success())
        }.catch { error in
            completionHandler?(.failure(error))
        }
    }
    
    /// Call this method inside your App Delegate method `application(application:didRegisterForRemoteNotificationsWithDeviceToken:completionHandler:)`.
#if os(iOS)
    fileprivate func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data,
        options: Options?,
        completionHandler: ((Result<Bool, Swift.Error>) -> Void)? = nil
    ) {
        self.deviceToken = deviceToken
        let block: () -> Void = {
            Promise<Bool> { fulfill, reject in
                let request = self.client.networkRequestFactory.buildPushRegisterDevice(
                    deviceToken,
                    options: options
                )
                request.execute { (data, response, error) -> Void in
                    if let response = response, response.isOK {
                        fulfill(true)
                    } else {
                        reject(buildError(data, response, error, self.client))
                    }
                }
            }.then { success in
                completionHandler?(.success(success))
            }.catch { error in
                completionHandler?(.failure(error))
            }
        }
        if let _ = self.client.activeUser {
            block()
        } else {
            self.client.userChangedListener = { user in
                if let _ = user {
                    block()
                    self.client.userChangedListener = nil
                }
            }
        }
    }
    
    /// Resets the badge number to zero.
    open func resetBadgeNumber() {
        badgeNumber = 0
    }
#endif
    
    
}
