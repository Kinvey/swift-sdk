//
//  User.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import PromiseKit
import SafariServices

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
                if let response = response where response.isOK {
                    client.activeUser = client.responseParser.parseUser(data)
                    fulfill(client.activeUser!)
                } else {
                    reject(buildError(data, response, error, client))
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
                if let response = response where response.isOK {
                    if let activeUser = client.activeUser where activeUser.userId == userId {
                        client.activeUser = nil
                    }
                    fulfill()
                } else {
                    reject(buildError(data, response, error, client))
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
                if let response = response where response.isOK, let user = client.responseParser.parseUser(data) {
                    client.activeUser = user
                    fulfill(user)
                } else {
                    reject(buildError(data, response, error, client))
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
                if let response = response where response.isOK, let user = client.responseParser.parseUser(data) {
                    client.activeUser = user
                    fulfill(user)
                } else {
                    reject(buildError(data, response, error, client))
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
                if let response = response where response.isOK {
                    fulfill()
                } else {
                    reject(buildError(data, response, error, client))
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
                if let response = response where response.isOK {
                    fulfill()
                } else {
                    reject(buildError(data, response, error, client))
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
    
    /**
     Sends an email with the username associated with the email provided.
     - parameter email: Email associated with the user
     - parameter client: Define the `Client` to be used for all the requests for the `DataStore` that will be returned. Default value: `Kinvey.sharedClient`
     - parameter completionHandler: Completion handler to be called once the response returns from the server
     */
    public class func forgotUsername(email email: String, client: Client = Kinvey.sharedClient, completionHandler: VoidHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildUserForgotUsername(email: email)
        Promise<Void> { fulfill, reject in
            request.execute() { (data, response, error) in
                if let response = response where response.isOK {
                    fulfill()
                } else {
                    reject(buildError(data, response, error, client))
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
                if let response = response where response.isOK, let json = client.responseParser.parse(data), let usernameExists = json["usernameExists"] as? Bool {
                    fulfill(usernameExists)
                } else {
                    reject(buildError(data, response, error, client))
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
                if let response = response where response.isOK, let user = client.responseParser.parseUser(data) {
                    fulfill(user)
                } else {
                    reject(buildError(data, response, error, client))
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
                if let response = response where response.isOK, let user = client.responseParser.parseUser(data) {
                    client.activeUser = user
                    fulfill(user)
                } else {
                    reject(buildError(data, response, error, client))
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
                if let response = response where response.isOK, let users = client.responseParser.parseUsers(data) {
                    fulfill(users)
                } else {
                    reject(buildError(data, response, error, client))
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
    
    internal convenience init(_ kcsUser: KCSUser, client: Client) {
        let authString = kcsUser.authString
        let authtoken = authString.hasPrefix(User.authtokenPrefix) ? authString.substringFromIndex(authString.startIndex.advancedBy(User.authtokenPrefix.characters.count)) : authString
        self.init(userId: kcsUser.userId, metadata: Metadata(JSON: [Metadata.AuthTokenKey : authtoken]), client: client)
        username = kcsUser.username
        email = kcsUser.email
    }
    
    private class func onMicLoginComplete(user kcsUser: KCSUser?, error: NSError?, actionResult: KCSUserActionResult, client: Client, completionHandler: UserHandler? = nil) {
        var user: User? = nil
        if let kcsUser = kcsUser {
            user = User(kcsUser, client: client)
            client.activeUser = user
        }
        if actionResult == KCSUserActionResult.KCSUserInteractionCancel {
            completionHandler?(user, Error.RequestCancelled)
        } else if actionResult == KCSUserActionResult.KCSUserInteractionTimeout {
            completionHandler?(user, Error.RequestTimeout)
        } else {
            completionHandler?(user, error)
        }
    }
    
    /**
     Login with MIC using Automated Authorization Grant Flow. We strongly recommend use [Authorization Code Grant Flow](http://devcenter.kinvey.com/rest/guides/mobile-identity-connect#authorization-grant) instead of [Automated Authorization Grant Flow](http://devcenter.kinvey.com/rest/guides/mobile-identity-connect#automated-authorization-grant) for security reasons.
     */
    public class func loginWithAuthorization(redirectURI redirectURI: NSURL, username: String, password: String, client: Client = Kinvey.sharedClient, completionHandler: UserHandler? = nil) {
        let options = [
            "username" : username,
            "password" : password
        ]
        KCSUser.loginWithAuthorizationCodeAPI(redirectURI.absoluteString, options: options) { (kcsUser, error, actionResult) in
            onMicLoginComplete(user: kcsUser, error: error, actionResult: actionResult, client: client, completionHandler: completionHandler)
        }
    }

#if os(iOS)
    private static let MICSafariViewControllerNotificationName = "Kinvey.User.MICSafariViewController"

    private static var MICSafariViewControllerNotificationObserver: AnyObject? = nil {
        willSet {
            if let token = MICSafariViewControllerNotificationObserver {
                NSNotificationCenter.defaultCenter().removeObserver(token, name: MICSafariViewControllerNotificationName, object: nil)
            }
        }
    }

    /// Performs a login using the MIC Redirect URL that contains a temporary token.
    @available(iOS 9, *)
    public class func login(redirectURI redirectURI: NSURL, micURL: NSURL, client: Client = Kinvey.sharedClient) -> Bool {
        if KCSUser.isValidMICRedirectURI(redirectURI.absoluteString, forURL: micURL) {
            KCSUser.parseMICRedirectURI(redirectURI.absoluteString, forURL: micURL, withCompletionBlock: { (kcsUser, error, actionResult) in
                onMicLoginComplete(user: kcsUser, error: error, actionResult: actionResult, client: client) { (user: User?, error: ErrorType?) in
                    NSNotificationCenter.defaultCenter().postNotificationName(
                        MICSafariViewControllerNotificationName,
                        object: nil,
                        userInfo: [
                            "user" : user ?? NSNull(),
                            "error" : (error as? AnyObject) ?? NSNull()
                        ]
                    )
                }
            })
            return true
        }
        return false
    }
    
    /// Presents the MIC View Controller to sign in a user using MIC (Mobile Identity Connect).
    @available(*, deprecated=3.2.2, message="Please use the method presentMICViewController(micUserInterface:) instead")
    public class func presentMICViewController(redirectURI redirectURI: NSURL, timeout: NSTimeInterval = 0, forceUIWebView: Bool, client: Client = Kinvey.sharedClient, completionHandler: UserHandler? = nil) {
        presentMICViewController(redirectURI: redirectURI, timeout: timeout, micUserInterface: forceUIWebView ? .UIWebView : .WKWebView, client: client, completionHandler: completionHandler)
    }
    
    /// Presents the MIC View Controller to sign in a user using MIC (Mobile Identity Connect).
    public class func presentMICViewController(redirectURI redirectURI: NSURL, timeout: NSTimeInterval = 0, micUserInterface: MICUserInterface = .Safari, currentViewController: UIViewController? = nil, client: Client = Kinvey.sharedClient, completionHandler: UserHandler? = nil) {
        precondition(client.isInitialized(), "Client is not initialized. Call Kinvey.sharedClient.initialize(...) to initialize the client before attempting to log in.")
        
        var micVC: UIViewController!
        if micUserInterface == .Safari {
            let url = KCSUser.URLforLoginWithMICRedirectURI(redirectURI.absoluteString!)!
            micVC = SFSafariViewController(URL: url)
            micVC.modalPresentationStyle = .OverCurrentContext
            MICSafariViewControllerNotificationObserver = NSNotificationCenter.defaultCenter().addObserverForName(
                MICSafariViewControllerNotificationName,
                object: nil,
                queue: NSOperationQueue.mainQueue())
            { notification in
                micVC.dismissViewControllerAnimated(true) {
                    MICSafariViewControllerNotificationObserver = nil
                    
                    let object = notification.object as? UserError
                    completionHandler?(object?.user, object?.error)
                }
            }
        } else {
            let micLoginVC = KCSMICLoginViewController(redirectURI: redirectURI.absoluteString!, timeout: timeout) { (kcsUser, error, actionResult) in
                onMicLoginComplete(user: kcsUser, error: error, actionResult: actionResult, client: client, completionHandler: completionHandler)
            }
            let forceUIWebView = micUserInterface == .UIWebView
            if forceUIWebView {
                micLoginVC.setValue(forceUIWebView, forKey: "forceUIWebView")
            }
            micLoginVC.client = client
            micLoginVC.micApiVersion = client.micApiVersion
            micVC = UINavigationController(rootViewController: micLoginVC)
        }
        
        var viewController = currentViewController
        if viewController == nil {
            viewController = UIApplication.sharedApplication().keyWindow?.rootViewController
            if let presentedViewController =  viewController?.presentedViewController {
                viewController = presentedViewController
            }
        }
        viewController?.presentViewController(micVC, animated: true, completion: nil)
    }
#endif

}

private struct UserError {
    
    let user: User?
    let error: ErrorType?
    
    init(user: User?, error: ErrorType?) {
        self.user = user
        self.error = error
    }
    
}

/// Used to tell which user interface must be used during the login process using MIC.
public enum MICUserInterface {
    
    /// Uses SFSafariViewController
    case Safari
    
    /// Uses WKWebView
    case WKWebView
    
    /// Uses UIWebView
    case UIWebView
    
}
