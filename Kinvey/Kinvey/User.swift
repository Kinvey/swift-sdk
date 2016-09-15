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
open class User: NSObject, Credential, Mappable {
    
    /// Username Key.
    open static let PersistableUsernameKey = "username"
    
    public typealias UserHandler = (User?, Swift.Error?) -> Void
    public typealias UsersHandler = ([User]?, Swift.Error?) -> Void
    public typealias VoidHandler = (Swift.Error?) -> Void
    public typealias BoolHandler = (Bool, Swift.Error?) -> Void
    
    /// `_id` property of the user.
    open fileprivate(set) var userId: String
    
    /// `_acl` property of the user.
    open fileprivate(set) var acl: Acl?
    
    /// `_kmd` property of the user.
    open fileprivate(set) var metadata: Metadata?
    
    /// `username` property of the user.
    open var username: String?
    
    /// `email` property of the user.
    open var email: String?
    
    internal var client: Client
    
    /// Creates a new `User` taking (optionally) a username and password. If no `username` or `password` was provided, random values will be generated automatically.
    @discardableResult
    open class func signup(username: String? = nil, password: String? = nil, client: Client = Kinvey.sharedClient, completionHandler: UserHandler? = nil) -> Request {
        precondition(client.isInitialized(), "Client is not initialized. Call Kinvey.sharedClient.initialize(...) to initialize the client before attempting to sign up.")

        let request = client.networkRequestFactory.buildUserSignUp(username: username, password: password)
        Promise<User> { fulfill, reject in
            request.execute() { (data, response, error) in
                if let response = response , response.isOK {
                    client.activeUser = client.responseParser.parseUser(data)
                    fulfill(client.activeUser!)
                } else {
                    reject(buildError(data, response, error, client))
                }
            }
        }.then { user in
            completionHandler?(user, nil)
        }.catch { error in
            completionHandler?(nil, error)
        }
        return request
    }
    
    /// Deletes a `User` by the `userId` property.
    @discardableResult
    open class func destroy(userId: String, hard: Bool = true, client: Client = Kinvey.sharedClient, completionHandler: VoidHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildUserDelete(userId: userId, hard: hard)
        Promise<Void> { fulfill, reject in
            request.execute() { (data, response, error) in
                if let response = response , response.isOK {
                    if let activeUser = client.activeUser , activeUser.userId == userId {
                        client.activeUser = nil
                    }
                    fulfill()
                } else {
                    reject(buildError(data, response, error, client))
                }
            }
        }.then { _ in
            completionHandler?(nil)
        }.catch { error in
            completionHandler?(error)
        }
        return request
    }
    
    /// Deletes the `User`.
    @discardableResult
    open func destroy(hard: Bool = true, client: Client = Kinvey.sharedClient, completionHandler: VoidHandler? = nil) -> Request {
        return User.destroy(userId: userId, hard: hard, client: client, completionHandler: completionHandler)
    }
    
    /**
     Sign in a user with a social identity.
     - parameter authSource: Authentication source enum
     - parameter authData: Authentication data from the social provider
     - parameter client: Define the `Client` to be used for all the requests for the `DataStore` that will be returned. Default value: `Kinvey.sharedClient`
     - parameter completionHandler: Completion handler to be called once the response returns from the server
     */
    @discardableResult
    open class func login(authSource: AuthSource, _ authData: [String : Any], client: Client = Kinvey.sharedClient, completionHandler: UserHandler? = nil) -> Request {
        precondition(client.isInitialized(), "Client is not initialized. Call Kinvey.sharedClient.initialize(...) to initialize the client before attempting to log in.")
        
        let request = client.networkRequestFactory.buildUserSocialLogin(authSource.rawValue, authData: authData)
        Promise<User> { fulfill, reject in
            request.execute() { (data, response, error) in
                if let response = response , response.isOK, let user = client.responseParser.parseUser(data) {
                    client.activeUser = user
                    fulfill(user)
                } else {
                    reject(buildError(data, response, error, client))
                }
            }
            }.then { user in
                completionHandler?(client.activeUser, nil)
            }.catch { error in
                completionHandler?(nil, error)
        }
        return request
    }
    
    /// Sign in a user and set as a current active user.
    @discardableResult
    open class func login(username: String, password: String, client: Client = Kinvey.sharedClient, completionHandler: UserHandler? = nil) -> Request {
        precondition(client.isInitialized(), "Client is not initialized. Call Kinvey.sharedClient.initialize(...) to initialize the client before attempting to log in.")

        let request = client.networkRequestFactory.buildUserLogin(username: username, password: password)
        Promise<User> { fulfill, reject in
            request.execute() { (data, response, error) in
                if let response = response , response.isOK, let user = client.responseParser.parseUser(data) {
                    client.activeUser = user
                    fulfill(user)
                } else {
                    reject(buildError(data, response, error, client))
                }
            }
        }.then { user in
            completionHandler?(client.activeUser, nil)
        }.catch { error in
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
    @discardableResult
    open class func sendEmailConfirmation(forUsername username: String, client: Client = Kinvey.sharedClient, completionHandler: VoidHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildSendEmailConfirmation(forUsername: username)
        Promise<Void> { fulfill, reject in
            request.execute() { (data, response, error) in
                if let response = response , response.isOK {
                    fulfill()
                } else {
                    reject(buildError(data, response, error, client))
                }
            }
            }.then {
                completionHandler?(nil)
            }.catch { error in
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
    @discardableResult
    open func sendEmailConfirmation(_ client: Client = Kinvey.sharedClient, completionHandler: VoidHandler? = nil) -> Request {
        guard let username = username else {
            preconditionFailure("Username is required to send the email confirmation")
        }
        guard let _ = email else {
            preconditionFailure("Email is required to send the email confirmation")
        }
        
        return User.sendEmailConfirmation(forUsername: username, client: client, completionHandler: completionHandler)
    }
    
    fileprivate class func resetPassword(usernameOrEmail: String, client: Client = Kinvey.sharedClient, completionHandler: VoidHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildUserResetPassword(usernameOrEmail: usernameOrEmail)
        Promise<Void> { fulfill, reject in
            request.execute() { (data, response, error) in
                if let response = response , response.isOK {
                    fulfill()
                } else {
                    reject(buildError(data, response, error, client))
                }
            }
        }.then {
            completionHandler?(nil)
        }.catch { error in
            completionHandler?(error)
        }
        return request
    }
    
    /// Sends an email to the user with a link to reset the password using the `username` property.
    @discardableResult
    open class func resetPassword(username: String, client: Client = Kinvey.sharedClient, completionHandler: VoidHandler? = nil) -> Request {
        return resetPassword(usernameOrEmail: username, client: client, completionHandler:  completionHandler)
    }
    
    /// Sends an email to the user with a link to reset the password using the `email` property.
    @discardableResult
    open class func resetPassword(email: String, client: Client = Kinvey.sharedClient, completionHandler: VoidHandler? = nil) -> Request {
        return resetPassword(usernameOrEmail: email, client: client, completionHandler:  completionHandler)
    }
    
    /// Sends an email to the user with a link to reset the password.
    @discardableResult
    open func resetPassword(_ client: Client = Kinvey.sharedClient, completionHandler: VoidHandler? = nil) -> Request {
        if let email = email {
            return User.resetPassword(email: email, client: client, completionHandler: completionHandler)
        } else if let username = username  {
            return User.resetPassword(username: username, client: client, completionHandler: completionHandler)
        } else if let completionHandler = completionHandler {
            DispatchQueue.main.async(execute: { () -> Void in
                completionHandler(Error.userWithoutEmailOrUsername)
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
    @discardableResult
    open func changePassword(newPassword: String, client: Client = Kinvey.sharedClient, completionHandler: UserHandler? = nil) -> Request {
        return save(newPassword: newPassword, client: client, completionHandler: completionHandler)
    }
    
    /**
     Sends an email with the username associated with the email provided.
     - parameter email: Email associated with the user
     - parameter client: Define the `Client` to be used for all the requests for the `DataStore` that will be returned. Default value: `Kinvey.sharedClient`
     - parameter completionHandler: Completion handler to be called once the response returns from the server
     */
    @discardableResult
    open class func forgotUsername(email: String, client: Client = Kinvey.sharedClient, completionHandler: VoidHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildUserForgotUsername(email: email)
        Promise<Void> { fulfill, reject in
            request.execute() { (data, response, error) in
                if let response = response , response.isOK {
                    fulfill()
                } else {
                    reject(buildError(data, response, error, client))
                }
            }
        }.then {
            completionHandler?(nil)
        }.catch { error in
            completionHandler?(error)
        }
        return request
    }
    
    /// Checks if a `username` already exists or not.
    @discardableResult
    open class func exists(username: String, client: Client = Kinvey.sharedClient, completionHandler: BoolHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildUserExists(username: username)
        Promise<Bool> { fulfill, reject in
            request.execute() { (data, response, error) in
                if let response = response , response.isOK, let json = client.responseParser.parse(data), let usernameExists = json["usernameExists"] as? Bool {
                    fulfill(usernameExists)
                } else {
                    reject(buildError(data, response, error, client))
                }
            }
        }.then { exists in
            completionHandler?(exists, nil)
        }.catch { error in
            completionHandler?(false, error)
        }
        return request
    }
    
    /// Gets a `User` instance using the `userId` property.
    @discardableResult
    open class func get(userId: String, client: Client = Kinvey.sharedClient, completionHandler: UserHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildUserGet(userId: userId)
        Promise<User> { fulfill, reject in
            request.execute() { (data, response, error) in
                if let response = response , response.isOK, let user = client.responseParser.parseUser(data) {
                    fulfill(user)
                } else {
                    reject(buildError(data, response, error, client))
                }
            }
        }.then { user in
            completionHandler?(user, nil)
        }.catch { error in
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
    public required convenience init?(map: Map) {
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
    open func mapping(map: Map) {
        userId <- map[PersistableIdKey]
        acl <- map[PersistableAclKey]
        metadata <- map[PersistableMetadataKey]
        username <- map["username"]
        email <- map["email"]
    }
    
    /// Sign out the current active user.
    open func logout() {
        if self == client.activeUser {
            client.activeUser = nil
        }
    }
    
    /// Creates or updates a `User`.
    @discardableResult
    open func save(newPassword: String? = nil, client: Client = Kinvey.sharedClient, completionHandler: UserHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildUserSave(user: self, newPassword: newPassword)
        Promise<User> { fulfill, reject in
            request.execute() { (data, response, error) in
                if let response = response , response.isOK, let user = client.responseParser.parseUser(data) {
                    client.activeUser = user
                    fulfill(user)
                } else {
                    reject(buildError(data, response, error, client))
                }
            }
        }.then { user in
            completionHandler?(client.activeUser, nil)
        }.catch { error in
            completionHandler?(nil, error)
        }
        return request
    }
    
    /**
     This method allows users to do exact queries for other users restricted to the `UserQuery` attributes.
     */
    @discardableResult
    open func lookup(_ userQuery: UserQuery, client: Client = Kinvey.sharedClient, completionHandler: UsersHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildUserLookup(user: self, userQuery: userQuery)
        Promise<[User]> { fulfill, reject in
            request.execute() { (data, response, error) in
                if let response = response , response.isOK, let users = client.responseParser.parseUsers(data) {
                    fulfill(users)
                } else {
                    reject(buildError(data, response, error, client))
                }
            }
            }.then { users in
                completionHandler?(users, nil)
            }.catch { error in
                completionHandler?(nil, error)
        }
        return request
    }
    
    internal static let authtokenPrefix = "Kinvey "
    
    /// Autorization header used for calls that requires a logged `User`.
    open var authorizationHeader: String? {
        get {
            var authorization: String? = nil
            if let authtoken = metadata?.authtoken {
                authorization = "Kinvey \(authtoken)"
            }
            return authorization
        }
    }
    
    internal convenience init(_ kcsUser: KCSUser, client: Client) {
        let authString = kcsUser.authString!
        let authtoken = authString.hasPrefix(User.authtokenPrefix) ? authString.substring(from: User.authtokenPrefix.endIndex) : authString
        self.init(userId: kcsUser.userId, metadata: Metadata(JSON: [Metadata.AuthTokenKey : authtoken]), client: client)
        username = kcsUser.username
        email = kcsUser.email
    }
    
    fileprivate class func onMicLoginComplete(user kcsUser: KCSUser?, error: Swift.Error?, actionResult: KCSUserActionResult, client: Client, completionHandler: UserHandler? = nil) {
        var user: User? = nil
        if let kcsUser = kcsUser {
            user = User(kcsUser, client: client)
            client.activeUser = user
        }
        if actionResult == KCSUserActionResult.KCSUserInteractionCancel {
            completionHandler?(user, Error.requestCancelled)
        } else if actionResult == KCSUserActionResult.KCSUserInteractionTimeout {
            completionHandler?(user, Error.requestTimeout)
        } else {
            completionHandler?(user, error)
        }
    }
    
    /**
     Login with MIC using Automated Authorization Grant Flow. We strongly recommend use [Authorization Code Grant Flow](http://devcenter.kinvey.com/rest/guides/mobile-identity-connect#authorization-grant) instead of [Automated Authorization Grant Flow](http://devcenter.kinvey.com/rest/guides/mobile-identity-connect#automated-authorization-grant) for security reasons.
     */
    open class func loginWithAuthorization(redirectURI: URL, username: String, password: String, client: Client = Kinvey.sharedClient, completionHandler: UserHandler? = nil) {
        let options = [
            "username" : username,
            "password" : password
        ]
        KCSUser.login(withAuthorizationCodeAPI: redirectURI.absoluteString, options: options) { (kcsUser, error, actionResult) in
            onMicLoginComplete(user: kcsUser, error: error, actionResult: actionResult, client: client, completionHandler: completionHandler)
        }
    }

#if os(iOS)
    /// Presents the MIC View Controller to sign in a user using MIC (Mobile Identity Connect).
    open class func presentMICViewController(redirectURI: URL, timeout: TimeInterval = 0, forceUIWebView: Bool = false, client: Client = Kinvey.sharedClient, completionHandler: UserHandler? = nil) {
        precondition(client.isInitialized(), "Client is not initialized. Call Kinvey.sharedClient.initialize(...) to initialize the client before attempting to log in.")

        let micVC = KCSMICLoginViewController(redirectURI: redirectURI.absoluteString, timeout: timeout) { (kcsUser, error, actionResult) in
            onMicLoginComplete(user: kcsUser, error: error, actionResult: actionResult, client: client, completionHandler: completionHandler)
        }
        if forceUIWebView {
            micVC.setValue(forceUIWebView, forKey: "forceUIWebView")
        }
        micVC.client = client
        micVC.micApiVersion = client.micApiVersion
        let navigationVC = UINavigationController(rootViewController: micVC)
        
        var viewController = UIApplication.shared.keyWindow?.rootViewController
        if let presentedViewController =  viewController?.presentedViewController {
            viewController = presentedViewController;
        }
        viewController?.present(navigationVC, animated: true)
    }
#endif

}
