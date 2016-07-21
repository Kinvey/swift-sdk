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
public class User: NSObject, Credential, Mappable {
    
    /// Username Key.
    public static let PersistableUsernameKey = "username"
    
    public typealias UserHandler = (User?, ErrorType?) -> Void
    public typealias UsersHandler = ([User]?, ErrorType?) -> Void
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
    
    internal var client: Client
    
    /// Creates a new `User` taking (optionally) a username and password. If no `username` or `password` was provided, random values will be generated automatically.
    public class func signup(username username: String? = nil, password: String? = nil, client: Client = Kinvey.sharedClient, completionHandler: UserHandler? = nil) -> Request {
        precondition(client.isInitialized(), "Client is not initialized. Call Kinvey.sharedClient.initialize(...) to initialize the client before attempting to sign up.")

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
    
    /**
     Sign in a user with a social identity.
     - parameter authSource: Authentication source enum
     - parameter authData: Authentication data from the social provider
     - parameter client: Define the `Client` to be used for all the requests for the `DataStore` that will be returned. Default value: `Kinvey.sharedClient`
     - parameter completionHandler: Completion handler to be called once the response returns from the server
     */
    public class func login(authSource authSource: AuthSource, _ authData: [String : AnyObject], client: Client = Kinvey.sharedClient, completionHandler: UserHandler? = nil) -> Request {
        precondition(client.isInitialized(), "Client is not initialized. Call Kinvey.sharedClient.initialize(...) to initialize the client before attempting to log in.")
        
        let request = client.networkRequestFactory.buildUserSocialLogin(authSource.rawValue, authData: authData)
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
    
    /// Sign in a user and set as a current active user.
    public class func login(username username: String, password: String, client: Client = Kinvey.sharedClient, completionHandler: UserHandler? = nil) -> Request {
        precondition(client.isInitialized(), "Client is not initialized. Call Kinvey.sharedClient.initialize(...) to initialize the client before attempting to log in.")

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
    
    /**
     Sends a request to confirm email address to the specified user.
     
     The user must have a valid email set in its `email` field, on the server, for this to work. The user will receive an email with a time-bound link to a verification web page.
     
     - parameter username: Username of the user that needs to send the email confirmation
     - parameter client: define the `Client` to be used for all the requests for the `DataStore` that will be returned. Default value: `Kinvey.sharedClient`
     - parameter completionHandler: Completion handler to be called once the response returns from the server
     */
    public class func sendEmailConfirmation(forUsername username: String, client: Client = Kinvey.sharedClient, completionHandler: VoidHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildSendEmailConfirmation(forUsername: username)
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
    
    /**
     Sends a request to confirm email address to the user.
     
     The user must have a valid email set in its `email` field, on the server, for this to work. The user will receive an email with a time-bound link to a verification web page.
     
     - parameter client: define the `Client` to be used for all the requests for the `DataStore` that will be returned. Default value: `Kinvey.sharedClient`
     - parameter completionHandler: Completion handler to be called once the response returns from the server
     */
    public func sendEmailConfirmation(client: Client = Kinvey.sharedClient, completionHandler: VoidHandler? = nil) -> Request {
        guard let username = username else {
            preconditionFailure("Username is required to send the email confirmation")
        }
        guard let _ = email else {
            preconditionFailure("Email is required to send the email confirmation")
        }
        
        return User.sendEmailConfirmation(forUsername: username, client: client, completionHandler: completionHandler)
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
    
    /**
     Changes the password for the current user and automatically updates the session with a new valid session.
     - parameter newPassword: A new password for the user
     - parameter client: Define the `Client` to be used for all the requests for the `DataStore` that will be returned. Default value: `Kinvey.sharedClient`
     - parameter completionHandler: Completion handler to be called once the response returns from the server
     */
    public func changePassword(newPassword newPassword: String, client: Client = Kinvey.sharedClient, completionHandler: UserHandler? = nil) -> Request {
        return save(newPassword: newPassword, client: client, completionHandler: completionHandler)
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
    
    /// Constructor that validates if the map contains at least the `userId`.
    public required convenience init?(_ map: Map) {
        var userId: String?
        var acl: Acl?
        var metadata: Metadata?
        
        userId <- map[PersistableIdKey]
        guard let userIdValue = userId else {
            return nil
        }
        
        acl <- map[PersistableAclKey]
        metadata <- map[PersistableMetadataKey]
        self.init(userId: userIdValue, acl: acl, metadata: metadata)
    }
    
    /// This function is where all variable mappings should occur. It is executed by Mapper during the mapping (serialization and deserialization) process.
    public func mapping(map: Map) {
        userId <- map[PersistableIdKey]
        acl <- map[PersistableAclKey]
        metadata <- map[PersistableMetadataKey]
        username <- map["username"]
        email <- map["email"]
    }
    
    /// Sign out the current active user.
    public func logout() {
        if self == client.activeUser {
            client.activeUser = nil
        }
    }
    
    /// Creates or updates a `User`.
    public func save(newPassword newPassword: String? = nil, client: Client = Kinvey.sharedClient, completionHandler: UserHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildUserSave(user: self, newPassword: newPassword)
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
    
    /**
     This method allows users to do exact queries for other users restricted to the `UserQuery` attributes.
     */
    public func lookup(userQuery: UserQuery, client: Client = Kinvey.sharedClient, completionHandler: UsersHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildUserLookup(user: self, userQuery: userQuery)
        Promise<[User]> { fulfill, reject in
            request.execute() { (data, response, error) in
                if let response = response where response.isResponseOK, let users = client.responseParser.parseUsers(data) {
                    fulfill(users)
                } else if let error = error {
                    reject(error)
                } else {
                    reject(Error.InvalidResponse)
                }
            }
            }.then { users in
                completionHandler?(users, nil)
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
        precondition(client.isInitialized(), "Client is not initialized. Call Kinvey.sharedClient.initialize(...) to initialize the client before attempting to log in.")

        let micVC = KCSMICLoginViewController(redirectURI: redirectURI.absoluteString, timeout: timeout) { (kcsUser, error, actionResult) -> Void in
            var user: User? = nil
            if let kcsUser = kcsUser {
                let authString = kcsUser.authString
                let authtoken = authString.hasPrefix(authtokenPrefix) ? authString.substringFromIndex(authString.startIndex.advancedBy(authtokenPrefix.characters.count)) : authString
                user = User(userId: kcsUser.userId, metadata: Metadata(JSON: [Metadata.AuthTokenKey : authtoken]), client: client)
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
