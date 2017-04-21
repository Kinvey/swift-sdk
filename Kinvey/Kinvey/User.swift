//
//  User.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper

#if os(iOS) || os(OSX)
    import SafariServices
#endif

/// Class that represents an `User`.
open class User: NSObject, Credential, Mappable {
    
    /// Username Key.
    open static let PersistableUsernameKey = "username"
    
    public typealias UserHandler<U: User> = (U?, Swift.Error?) -> Void
    public typealias UsersHandler<U: User> = ([U]?, Swift.Error?) -> Void
    public typealias VoidHandler = (Swift.Error?) -> Void
    public typealias BoolHandler = (Bool, Swift.Error?) -> Void
    
    /// `_id` property of the user.
    open var userId: String {
        guard let userId = _userId, !userId.isEmpty else {
            let message = "User has an empty or nil `userId` value."
            log.severe(message)
            fatalError(message)
        }
        return userId
    }
    
    private var _userId: String?
    
    /// `_acl` property of the user.
    open fileprivate(set) var acl: Acl?
    
    /// `_kmd` property of the user.
    open fileprivate(set) var metadata: UserMetadata?
    
    /// `_socialIdentity` property of the user.
    open fileprivate(set) var socialIdentity: UserSocialIdentity?
    
    /// `username` property of the user.
    open var username: String?
    
    /// `email` property of the user.
    open var email: String?
    
    internal var client: Client
    
    private class func validate(client: Client) {
        guard client.isInitialized() else {
            let message = "Client is not initialized. Call Kinvey.sharedClient.initialize(...) to initialize the client before attempting to sign up or login."
            log.severe(message)
            fatalError(message)
        }
    }
    
    /// Creates a new `User` taking (optionally) a username and password. If no `username` or `password` was provided, random values will be generated automatically.
    @discardableResult
    open class func signup<U: User>(username: String? = nil, password: String? = nil, user: U? = nil, client: Client = Kinvey.sharedClient, completionHandler: UserHandler<U>? = nil) -> Request {
        validate(client: client)

        let request = client.networkRequestFactory.buildUserSignUp(username: username, password: password, user: user)
        Promise<U> { fulfill, reject in
            request.execute() { (data, response, error) in
                if let response = response , response.isOK, let user = client.responseParser.parseUser(data) as? U {
                    client.activeUser = user
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
    open class func login<U: User>(authSource: AuthSource, _ authData: [String : Any], createIfNotExists: Bool = true, client: Client = Kinvey.sharedClient, completionHandler: UserHandler<U>? = nil) -> Request {
        validate(client: client)
        
        let requests = MultiRequest()
        Promise<U> { fulfill, reject in
            let request = client.networkRequestFactory.buildUserSocialLogin(authSource, authData: authData)
            request.execute() { (data, response, error) in
                if let response = response {
                    if response.isOK, let user = client.responseParser.parseUser(data) as? U {
                        client.activeUser = user
                        fulfill(user)
                    } else if response.isNotFound, createIfNotExists {
                        let request = client.networkRequestFactory.buildUserSocialCreate(authSource, authData: authData)
                        request.execute { (data, response, error) in
                            if let response = response, response.isOK, let user = client.responseParser.parseUser(data) as? U {
                                client.activeUser = user
                                fulfill(user)
                            } else {
                                reject(buildError(data, response, error, client))
                            }
                        }
                        requests += request
                    } else {
                        reject(buildError(data, response, error, client))
                    }
                } else {
                    reject(buildError(data, response, error, client))
                }
            }
            requests += request
        }.then { user in
            completionHandler?(user, nil)
        }.catch { error in
            completionHandler?(nil, error)
        }
        return requests
    }
    
    /// Sign in a user and set as a current active user.
    @discardableResult
    open class func login<U: User>(username: String, password: String, client: Client = Kinvey.sharedClient, completionHandler: UserHandler<U>? = nil) -> Request {
        validate(client: client)

        let request = client.networkRequestFactory.buildUserLogin(username: username, password: password)
        Promise<U> { fulfill, reject in
            request.execute() { (data, response, error) in
                if let response = response , response.isOK, let user = client.responseParser.parseUser(data) as? U {
                    client.activeUser = user
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
            let message = "Username is required to send the email confirmation"
            log.severe(message)
            fatalError(message)
        }
        guard let _ = email else {
            let message = "Email is required to send the email confirmation"
            log.severe(message)
            fatalError(message)
        }
        
        return User.sendEmailConfirmation(forUsername: username, client: client, completionHandler: completionHandler)
    }
    
    @discardableResult
    /// Sends an email to the user with a link to reset the password
    open class func resetPassword(usernameOrEmail: String, client: Client = Kinvey.sharedClient, completionHandler: VoidHandler? = nil) -> Request {
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
    @available(*, deprecated: 3.3.4, message: "Use resetPassword(usernameOrEmail:) instead")
    open class func resetPassword(username: String, client: Client = Kinvey.sharedClient, completionHandler: VoidHandler? = nil) -> Request {
        return resetPassword(usernameOrEmail: username, client: client, completionHandler:  completionHandler)
    }
    
    /// Sends an email to the user with a link to reset the password using the `email` property.
    @discardableResult
    @available(*, deprecated: 3.3.4, message: "Use resetPassword(usernameOrEmail:) instead")
    open class func resetPassword(email: String, client: Client = Kinvey.sharedClient, completionHandler: VoidHandler? = nil) -> Request {
        return resetPassword(usernameOrEmail: email, client: client, completionHandler:  completionHandler)
    }
    
    /// Sends an email to the user with a link to reset the password.
    @discardableResult
    open func resetPassword(_ client: Client = Kinvey.sharedClient, completionHandler: VoidHandler? = nil) -> Request {
        if let email = email {
            return User.resetPassword(usernameOrEmail: email, client: client, completionHandler: completionHandler)
        } else if let username = username  {
            return User.resetPassword(usernameOrEmail: username, client: client, completionHandler: completionHandler)
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
    open func changePassword<U: User>(newPassword: String, client: Client = Kinvey.sharedClient, completionHandler: UserHandler<U>? = nil) -> Request {
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
    open class func get<U: User>(userId: String, client: Client = Kinvey.sharedClient, completionHandler: UserHandler<U>? = nil) -> Request {
        let request = client.networkRequestFactory.buildUserGet(userId: userId)
        Promise<U> { fulfill, reject in
            request.execute() { (data, response, error) in
                if let response = response , response.isOK, let user = client.responseParser.parseUser(data) as? U {
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
    
    /// Refresh the user's data.
    @discardableResult
    open func refresh(completionHandler: VoidHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildUserGet(userId: userId)
        Promise<Void> { fulfill, reject in
            request.execute() { (data, response, error) in
                if let response = response, response.isOK, let json = self.client.responseParser.parse(data) {
                    let map = Map(mappingType: .fromJSON, JSON: json)
                    self.mapping(map: map)
                    self.client.activeUser = self
                    fulfill()
                } else {
                    reject(buildError(data, response, error, self.client))
                }
            }
        }.then { user in
            completionHandler?(nil)
        }.catch { error in
            completionHandler?(error)
        }
        return request
    }
    
    /// Default Constructor.
    public init(userId: String? = nil, acl: Acl? = nil, metadata: UserMetadata? = nil, client: Client = Kinvey.sharedClient) {
        self._userId = userId
        self.acl = acl
        self.metadata = metadata
        self.client = client
    }
    
    /// Constructor that validates if the map contains at least the `userId`.
    public required convenience init?(map: Map) {
        var userId: String?
        var acl: Acl?
        var metadata: UserMetadata?
        
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
        _userId <- map[PersistableIdKey]
        acl <- map[PersistableAclKey]
        metadata <- map[PersistableMetadataKey]
        socialIdentity <- map["_socialIdentity"]
        username <- map["username"]
        email <- map["email"]
        socialIdentity <- map["_socialIdentity"]
    }
    
    /// Sign out the current active user.
    open func logout() {
        if self == client.activeUser {
            client.activeUser = nil
        }
    }
    
    /// Creates or updates a `User`.
    @discardableResult
    open func save<U: User>(newPassword: String? = nil, client: Client = Kinvey.sharedClient, completionHandler: UserHandler<U>? = nil) -> Request {
        let request = client.networkRequestFactory.buildUserSave(user: self, newPassword: newPassword)
        Promise<U> { fulfill, reject in
            request.execute() { (data, response, error) in
                if let response = response , response.isOK, let user = client.responseParser.parseUser(data) as? U {
                    client.activeUser = user
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
    
    /**
     This method allows users to do exact queries for other users restricted to the `UserQuery` attributes.
     */
    @discardableResult
    open func lookup<U: User>(_ userQuery: UserQuery, client: Client = Kinvey.sharedClient, completionHandler: UsersHandler<U>? = nil) -> Request {
        let request = client.networkRequestFactory.buildUserLookup(user: self, userQuery: userQuery)
        Promise<[U]> { fulfill, reject in
            request.execute() { (data, response, error) in
                if let response = response, response.isOK, let users: [U] = client.responseParser.parseUsers(data) {
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
    
    /**
     Login with MIC using Automated Authorization Grant Flow. We strongly recommend use [Authorization Code Grant Flow](http://devcenter.kinvey.com/rest/guides/mobile-identity-connect#authorization-grant) instead of [Automated Authorization Grant Flow](http://devcenter.kinvey.com/rest/guides/mobile-identity-connect#automated-authorization-grant) for security reasons.
     */
    open class func login<U: User>(redirectURI: URL, username: String, password: String, client: Client = sharedClient, completionHandler: UserHandler<U>? = nil) {
        MIC.login(redirectURI: redirectURI, username: username, password: password, client: client) { user, error in
            DispatchQueue.main.async {
                completionHandler?(user, error)
            }
        }
    }

#if os(iOS)
    
    private static let MICSafariViewControllerNotificationName = NSNotification.Name("Kinvey.User.MICSafariViewController")
    
    private static var MICSafariViewControllerNotificationObserver: Any? = nil {
        willSet {
            if let token = MICSafariViewControllerNotificationObserver {
                NotificationCenter.default.removeObserver(token, name: MICSafariViewControllerNotificationName, object: nil)
            }
        }
    }
    
    /// Performs a login using the MIC Redirect URL that contains a temporary token.
    open class func login(redirectURI: URL, micURL: URL, client: Client = sharedClient) -> Bool {
        if let code = MIC.parseCode(redirectURI: redirectURI, url: micURL) {
            MIC.login(redirectURI: redirectURI, code: code, client: client) { (user, error) in
                let object = UserError(user: user, error: error)
                NotificationCenter.default.post(
                    name: MICSafariViewControllerNotificationName,
                    object: object
                )
            }
            return true
        }
        return false
    }

    /// Presents the MIC View Controller to sign in a user using MIC (Mobile Identity Connect).
    @available(*, deprecated: 3.3.2, message: "Please use the method presentMICViewController(micUserInterface:) instead")
    open class func presentMICViewController(redirectURI: URL, timeout: TimeInterval = 0, forceUIWebView: Bool, client: Client = Kinvey.sharedClient, completionHandler: UserHandler<User>? = nil) {
        presentMICViewController(redirectURI: redirectURI, timeout: timeout, micUserInterface: forceUIWebView ? .uiWebView : .wkWebView, client: client, completionHandler: completionHandler)
    }
    
    /// Presents the MIC View Controller to sign in a user using MIC (Mobile Identity Connect).
    open class func presentMICViewController<U: User>(redirectURI: URL, timeout: TimeInterval = 0, micUserInterface: MICUserInterface = .safari, currentViewController: UIViewController? = nil, client: Client = Kinvey.sharedClient, completionHandler: UserHandler<U>? = nil) {
        validate(client: client)
        
        Promise<U> { fulfill, reject in
            var micVC: UIViewController!
            
            switch micUserInterface {
            case .safari:
                let url = MIC.urlForLogin(redirectURI: redirectURI)
                micVC = SFSafariViewController(url: url)
                micVC.modalPresentationStyle = .overCurrentContext
                MICSafariViewControllerNotificationObserver = NotificationCenter.default.addObserver(
                    forName: MICSafariViewControllerNotificationName,
                    object: nil,
                    queue: OperationQueue.main)
                { notification in
                    micVC.dismiss(animated: true) {
                        MICSafariViewControllerNotificationObserver = nil
                        
                        if let object = notification.object as? UserError<U> {
                            if let user = object.user {
                                fulfill(user)
                            } else if let error = object.error {
                                reject(error)
                            } else {
                                reject(Error.invalidResponse(httpResponse: nil, data: nil))
                            }
                        } else {
                            reject(Error.invalidResponse(httpResponse: nil, data: nil))
                        }
                    }
                }
            default:
                let forceUIWebView = micUserInterface == .uiWebView
                let micLoginVC = MICLoginViewController(redirectURI: redirectURI, userType: client.userType, timeout: timeout, forceUIWebView: forceUIWebView, client: client) { user, error, userActionResult in
                    if let userActionResult = userActionResult {
                        switch userActionResult {
                        case .cancel:
                            reject(Error.requestCancelled)
                        case .timeout:
                            reject(Error.requestTimeout)
                        }
                    } else {
                        if let user = user as? U {
                            fulfill(user)
                        } else if let error = error {
                            reject(error)
                        } else {
                            reject(Error.invalidResponse(httpResponse: nil, data: nil))
                        }
                    }
                }
                micVC = UINavigationController(rootViewController: micLoginVC)
            }
            
            var viewController = currentViewController
            if viewController == nil {
                viewController = UIApplication.shared.keyWindow?.rootViewController
                if let presentedViewController =  viewController?.presentedViewController {
                    viewController = presentedViewController
                }
            }
            viewController?.present(micVC, animated: true)
        }.then { user in
            completionHandler?(user, nil)
        }.catch { error in
            completionHandler?(nil, error)
        }
    }
#endif

}

private struct UserError<U: User> {
    
    let user: U?
    let error: Swift.Error?
    
}

public struct UserAuthToken : StaticMappable {
    
    var accessToken: String
    var refreshToken: String?
    var tokenType: String?
    var expiresIn: Int?
    
    public static func objectForMapping(map: Map) -> BaseMappable? {
        guard let accessToken: String = map["access_token"].value() else {
            return nil
        }
        return UserAuthToken(accessToken: accessToken, refreshToken: nil, tokenType: nil, expiresIn: nil)
    }
    
    public mutating func mapping(map: Map) {
        accessToken <- map["access_token"]
        refreshToken <- map["refresh_token"]
        tokenType <- map["token_type"]
        expiresIn <- map["expires_in"]
    }
    
}

public struct UserSocialIdentity : StaticMappable {
    
    /// Facebook social identity
    var facebook: UserAuthToken?
    
    /// Twitter social identity
    var twitter: UserAuthToken?
    
    /// Google+ social identity
    var googlePlus: UserAuthToken?
    
    /// LinkedIn social identity
    var linkedIn: UserAuthToken?
    
    /// Kinvey MIC social identity
    var kinvey: UserAuthToken?
    
    public static func objectForMapping(map: Map) -> BaseMappable? {
        return UserSocialIdentity()
    }
    
    public mutating func mapping(map: Map) {
        facebook <- map[AuthSource.facebook.rawValue]
        twitter <- map[AuthSource.twitter.rawValue]
        googlePlus <- map[AuthSource.googlePlus.rawValue]
        linkedIn <- map[AuthSource.linkedIn.rawValue]
        kinvey <- map[AuthSource.kinvey.rawValue]
    }
    
}
