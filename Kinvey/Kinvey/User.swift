//
//  User.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import PromiseKit

/// Class that represents an `User`.
@objc(__KNVUser)
public class User: NSObject, Credential {
    
    /// Username Key.
    public static let PersistableUsernameKey = "username"
    
    public typealias UserHandler = (User?, ErrorType?) -> Void
    public typealias VoidHandler = (ErrorType?) -> Void
    public typealias BoolHandler = (Bool, ErrorType?) -> Void
    
    /// `_id` property of the user.
    public private(set) var userId: String
    
    /// `_acl` property of the user.
    public private(set) var acl: Acl?
    
    /// `_kmd` property of the user.
    public private(set) var metadata: Metadata?
    
    /// `username` property of the user.
    public var username: String?
    
    /// `email` property of the user.
    public var email: String?
    
    internal let client: Client
    
    /// Creates a new `User` taking (optionally) a username and password. If no `username` or `password` was provided, random values will be generated automatically.
    public class func signup(username username: String? = nil, password: String? = nil, client: Client = Kinvey.sharedClient, completionHandler: UserHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildUserSignUp(username: username, password: password)
        Promise<User> { fulfill, reject in
            request.execute() { (data, response, error) in
                if let response = response where response.isResponseOK {
                    client.activeUser = client.responseParser.parseUser(data)
                    fulfill(client.activeUser!)
                } else if let error = error {
                    reject(error)
                } else {
                    reject(Error.InvalidResponse)
                }
            }
        }.then { user in
            completionHandler?(user, nil)
        }.error { error in
            completionHandler?(nil, error)
        }
        return request
    }
    
    /// Deletes a `User` by the `userId` property.
    public class func destroy(userId userId: String, hard: Bool = true, client: Client = Kinvey.sharedClient, completionHandler: VoidHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildUserDelete(userId: userId, hard: hard)
        Promise<Void> { fulfill, reject in
            request.execute() { (data, response, error) in
                if let response = response where response.isResponseOK {
                    if let activeUser = client.activeUser where activeUser.userId == userId {
                        client.activeUser = nil
                    }
                    fulfill()
                } else if let error = error {
                    reject(error)
                } else {
                    reject(Error.InvalidResponse)
                }
            }
        }.then { _ in
            completionHandler?(nil)
        }.error { error in
            completionHandler?(error)
        }
        return request
    }
    
    /// Deletes the `User`.
    public func destroy(hard hard: Bool = true, client: Client = Kinvey.sharedClient, completionHandler: VoidHandler? = nil) -> Request {
        return User.destroy(userId: userId, hard: hard, client: client, completionHandler: completionHandler)
    }
    
    /// Sign in a user and set as a current active user.
    public class func login(username username: String, password: String, client: Client = Kinvey.sharedClient, completionHandler: UserHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildUserLogin(username: username, password: password)
        Promise<User> { fulfill, reject in
            request.execute() { (data, response, error) in
                if let response = response where response.isResponseOK {
                    let user = client.responseParser.parseUser(data)
                    if let user = user {
                        client.activeUser = user
                        fulfill(user)
                    } else {
                        reject(Error.InvalidResponse)
                    }
                } else if let error = error {
                    reject(error)
                } else {
                    reject(Error.InvalidResponse)
                }
            }
        }.then { user in
            completionHandler?(client.activeUser, nil)
        }.error { error in
            completionHandler?(nil, error)
        }
        return request
    }
    
    private class func resetPassword(usernameOrEmail usernameOrEmail: String, client: Client = Kinvey.sharedClient, completionHandler: VoidHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildUserResetPassword(usernameOrEmail: usernameOrEmail)
        Promise<Void> { fulfill, reject in
            request.execute() { (data, response, error) in
                if let response = response where response.isResponseOK {
                    fulfill()
                } else if let error = error {
                    reject(error)
                } else {
                    reject(Error.InvalidResponse)
                }
            }
        }.then {
            completionHandler?(nil)
        }.error { error in
            completionHandler?(error)
        }
        return request
    }
    
    /// Sends an email to the user with a link to reset the password using the `username` property.
    public class func resetPassword(username username: String, client: Client = Kinvey.sharedClient, completionHandler: VoidHandler? = nil) -> Request {
        return resetPassword(usernameOrEmail: username, client: client, completionHandler:  completionHandler)
    }
    
    /// Sends an email to the user with a link to reset the password using the `email` property.
    public class func resetPassword(email email: String, client: Client = Kinvey.sharedClient, completionHandler: VoidHandler? = nil) -> Request {
        return resetPassword(usernameOrEmail: email, client: client, completionHandler:  completionHandler)
    }
    
    /// Sends an email to the user with a link to reset the password.
    public func resetPassword(client: Client = Kinvey.sharedClient, completionHandler: VoidHandler? = nil) -> Request {
        if let email = email {
            return User.resetPassword(email: email, client: client, completionHandler: completionHandler)
        } else if let username = username  {
            return User.resetPassword(username: username, client: client, completionHandler: completionHandler)
        } else if let completionHandler = completionHandler {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completionHandler(Error.UserWithoutEmailOrUsername)
            })
        }
        return LocalRequest()
    }
    
    class func forgotUsername(email email: String, client: Client = Kinvey.sharedClient, completionHandler: VoidHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildUserForgotUsername(email: email)
        Promise<Void> { fulfill, reject in
            request.execute() { (data, response, error) in
                if let response = response where response.isResponseOK {
                    fulfill()
                } else if let error = error {
                    reject(error)
                } else {
                    reject(Error.InvalidResponse)
                }
            }
        }.then {
            completionHandler?(nil)
        }.error { error in
            completionHandler?(error)
        }
        return request
    }
    
    /// Checks if a `username` already exists or not.
    public class func exists(username username: String, client: Client = Kinvey.sharedClient, completionHandler: BoolHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildUserExists(username: username)
        Promise<Bool> { fulfill, reject in
            request.execute() { (data, response, error) in
                if let response = response where response.isResponseOK, let json = client.responseParser.parse(data), let usernameExists = json["usernameExists"] as? Bool {
                    fulfill(usernameExists)
                } else if let error = error {
                    reject(error)
                } else {
                    reject(Error.InvalidResponse)
                }
            }
        }.then { exists in
            completionHandler?(exists, nil)
        }.error { error in
            completionHandler?(false, error)
        }
        return request
    }
    
    /// Gets a `User` instance using the `userId` property.
    public class func get(userId userId: String, client: Client = Kinvey.sharedClient, completionHandler: UserHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildUserGet(userId: userId)
        Promise<User> { fulfill, reject in
            request.execute() { (data, response, error) in
                if let response = response where response.isResponseOK, let user = client.responseParser.parseUser(data) {
                    fulfill(user)
                } else if let error = error {
                    reject(error)
                } else {
                    reject(Error.InvalidResponse)
                }
            }
        }.then { user in
            completionHandler?(user, nil)
        }.error { error in
            completionHandler?(nil, error)
        }
        return request
    }
    
    /// Default Constructor.
    public init(userId: String, acl: Acl? = nil, metadata: Metadata? = nil, client: Client = Kinvey.sharedClient) {
        self.userId = userId
        self.acl = acl
        self.metadata = metadata
        self.client = client
    }
    
    /// Constructor used to build a new `User` instance from a JSON object.
    public required init?(json: JsonDictionary, client: Client = Kinvey.sharedClient) {
        if let userId = json[PersistableIdKey] as? String {
            self.userId = userId
        } else {
            return nil
        }
        
        if let username = json["username"] as? String {
            self.username = username
        }
        
        if let email = json["email"] as? String {
            self.email = email
        }
        
        if let kmd = json[PersistableMetadataKey] as? [String : AnyObject] {
            metadata = Metadata(json: kmd)
        } else {
            metadata = nil
        }
        
        self.client = client
        
        super.init()
    }
    
    /// The JSON representation for the `User` instance.
    public func toJson() -> [String : AnyObject] {
        var json: [String : AnyObject] = [:]
        
        json[Kinvey.PersistableIdKey] = userId
        
        if let metadata = metadata {
            json[Kinvey.PersistableMetadataKey] = metadata.toJson()
        }
        
        if let username = username {
            json["username"] = username
        }
        
        if let email = email {
            json["email"] = email
        }
        
        return json
    }
    
    /// Sign out the current active user.
    public func logout() {
        if self == client.activeUser {
            client.activeUser = nil
        }
    }
    
    /// Creates or updates a `User`.
    public func save(client client: Client = Kinvey.sharedClient, completionHandler: UserHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildUserSave(user: self)
        Promise<User> { fulfill, reject in
            request.execute() { (data, response, error) in
                if let response = response where response.isResponseOK, let user = client.responseParser.parseUser(data) {
                    client.activeUser = user
                    fulfill(user)
                } else if let error = error {
                    reject(error)
                } else {
                    reject(Error.InvalidResponse)
                }
            }
        }.then { user in
            completionHandler?(client.activeUser, nil)
        }.error { error in
            completionHandler?(nil, error)
        }
        return request
    }
    
    internal static let authtokenPrefix = "Kinvey "
    
    /// Autorization header used for calls that requires a logged `User`.
    public var authorizationHeader: String? {
        get {
            var authorization: String? = nil
            if let authtoken = metadata?.authtoken {
                authorization = "Kinvey \(authtoken)"
            }
            return authorization
        }
    }

#if os(iOS)
    /// Presents the MIC View Controller to sign in a user using MIC (Mobile Identity Connect).
    public class func presentMICViewController(redirectURI redirectURI: NSURL, timeout: NSTimeInterval = 0, forceUIWebView: Bool = false, client: Client = Kinvey.sharedClient, completionHandler: UserHandler? = nil) {
        let micVC = KCSMICLoginViewController(redirectURI: redirectURI.absoluteString, timeout: timeout) { (kcsUser, error, actionResult) -> Void in
            var user: User? = nil
            if let kcsUser = kcsUser {
                let authString = kcsUser.authString
                let authtoken = authString.hasPrefix(authtokenPrefix) ? authString.substringFromIndex(authString.startIndex.advancedBy(authtokenPrefix.characters.count)) : authString
                user = User(userId: kcsUser.userId, metadata: Metadata(authtoken: authtoken), client: client)
                user?.username = kcsUser.username
                user?.email = kcsUser.email
                client.activeUser = user
            }
            completionHandler?(user, error)
        }
        if forceUIWebView {
            micVC.setValue(forceUIWebView, forKey: "forceUIWebView")
        }
        micVC.client = client
        let navigationVC = UINavigationController(rootViewController: micVC)
        
        var viewController = UIApplication.sharedApplication().keyWindow?.rootViewController
        if let presentedViewController =  viewController?.presentedViewController {
            viewController = presentedViewController;
        }
        viewController?.presentViewController(navigationVC, animated: true, completion: nil)
    }
#endif

}
