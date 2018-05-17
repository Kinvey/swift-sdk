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
        return _userId!
    }
    
    @objc
    private dynamic var _userId: String?
    
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
    
    internal var realtimeRouter: RealtimeRouter?
    
    /// Creates a new `User` taking (optionally) a username and password. If no `username` or `password` was provided, random values will be generated automatically.
    @discardableResult
    open class func signup<U: User>(
        username: String? = nil,
        password: String? = nil,
        user: U? = nil,
        client: Client = Kinvey.sharedClient,
        completionHandler: UserHandler<U>? = nil
    ) -> AnyRequest<Result<U, Swift.Error>> {
        return signup(
            username: username,
            password: password,
            user: user,
            client: client
        ) { (result: Result<U, Swift.Error>) in
            switch result {
            case .success(let user):
                completionHandler?(user, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /// Creates a new `User` taking (optionally) a username and password. If no `username` or `password` was provided, random values will be generated automatically.
    @discardableResult
    open class func signup<U: User>(
        username: String? = nil,
        password: String? = nil,
        user: U? = nil,
        client: Client = Kinvey.sharedClient,
        completionHandler: ((Result<U, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<U, Swift.Error>> {
        return signup(
            username: username,
            password: password,
            user: user,
            options: Options(
                client: client
            ),
            completionHandler: completionHandler
        )
    }
    
    private class func login<U: User>(
        request: HttpRequest<Result<U, Swift.Error>>,
        client: Client,
        userType: U.Type,
        completionHandler: ((Result<U, Swift.Error>) -> Void)?
    ) {
        Promise<U> { resolver in
            request.execute() { (data, response, error) in
                if let response = response,
                    response.isOK,
                    let user = client.responseParser.parseUser(data) as? U
                {
                    client.activeUser = user
                    resolver.fulfill(user)
                } else {
                    resolver.reject(buildError(data, response, error, client))
                }
            }
        }.done { (user) -> Void in
            let result: Result<U, Swift.Error> = .success(user)
            request.result = result
            completionHandler?(result)
        }.catch { error in
            let result: Result<U, Swift.Error> = .failure(error)
            request.result = result
            completionHandler?(result)
        }
    }
    
    /// Creates a new `User` taking (optionally) a username and password. If no `username` or `password` was provided, random values will be generated automatically.
    @discardableResult
    open class func signup<U: User>(
        username: String? = nil,
        password: String? = nil,
        user: U? = nil,
        options: Options? = nil,
        completionHandler: ((Result<U, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<U, Swift.Error>> {
        let client = options?.client ?? sharedClient
        if let error = client.validate() {
            DispatchQueue.main.async {
                completionHandler?(.failure(error))
            }
            return AnyRequest(LocalRequest<Result<U, Swift.Error>>())
        }

        let request = client.networkRequestFactory.buildUserSignUp(
            username: username,
            password: password,
            user: user,
            options: options,
            resultType: Result<U, Swift.Error>.self
        )
        login(
            request: request,
            client: client,
            userType: U.self,
            completionHandler: completionHandler
        )
        return AnyRequest(request)
    }
    
    /// Deletes a `User` by the `userId` property.
    @available(*, deprecated: 3.6.0, message: "Please use destroy(userId:hard:options:completionHandler:) instead")
    @discardableResult
    open class func destroy(
        userId: String,
        hard: Bool = true,
        client: Client = Kinvey.sharedClient,
        completionHandler: ((Result<Void, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<Void, Swift.Error>> {
        return destroy(
            userId: userId,
            hard: hard,
            options: Options(
                client: client
            ),
            completionHandler: completionHandler
        )
    }
    
    /// Deletes a `User` by the `userId` property.
    @discardableResult
    open class func destroy(
        userId: String,
        hard: Bool = true,
        options: Options? = nil,
        completionHandler: ((Result<Void, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<Void, Swift.Error>> {
        let client = options?.client ?? sharedClient
        let request = client.networkRequestFactory.buildUserDelete(
            userId: userId,
            hard: hard,
            options: options,
            resultType: Result<Void, Swift.Error>.self
        )
        Promise<Void> { resolver in
            request.execute() { (data, response, error) in
                if let response = response, response.isOK {
                    if let activeUser = client.activeUser,
                        activeUser.userId == userId
                    {
                        client.activeUser = nil
                    }
                    resolver.fulfill(())
                } else {
                    resolver.reject(buildError(data, response, error, client))
                }
            }
        }.done {
            completionHandler?(.success($0))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return AnyRequest(request)
    }
    
    /// Deletes the `User`.
    @discardableResult
    open func destroy(
        hard: Bool = true,
        options: Options? = nil,
        completionHandler: ((Result<Void, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<Void, Swift.Error>> {
        return User.destroy(
            userId: userId,
            hard: hard,
            options: options,
            completionHandler: completionHandler
        )
    }
    
    /**
     Sign in a user with a social identity.
     - parameter authSource: Authentication source enum
     - parameter authData: Authentication data from the social provider
     - parameter client: Define the `Client` to be used for all the requests for the `DataStore` that will be returned. Default value: `Kinvey.sharedClient`
     - parameter completionHandler: Completion handler to be called once the response returns from the server
     */
    @discardableResult
    open class func login<U: User>(
        authSource: AuthSource,
        _ authData: [String : Any],
        createIfNotExists: Bool = true,
        authServiceId: String? = nil,
        client: Client = sharedClient,
        completionHandler: UserHandler<U>? = nil
    ) -> AnyRequest<Result<U, Swift.Error>> {
        return login(
            authSource: authSource,
            authData,
            createIfNotExists: createIfNotExists,
            authServiceId: authServiceId,
            client: client
        ) { (result: Result<U, Swift.Error>) in
            switch result {
            case .success(let user):
                completionHandler?(user, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /**
     Sign in a user with a social identity.
     - parameter authSource: Authentication source enum
     - parameter authData: Authentication data from the social provider
     - parameter client: Define the `Client` to be used for all the requests for the `DataStore` that will be returned. Default value: `Kinvey.sharedClient`
     - parameter completionHandler: Completion handler to be called once the response returns from the server
     */
    @discardableResult
    open class func login<U: User>(
        authSource: AuthSource,
        _ authData: [String : Any],
        createIfNotExists: Bool = true,
        authServiceId: String? = nil,
        client: Client = sharedClient,
        completionHandler: ((Result<U, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<U, Swift.Error>> {
        return login(
            authSource: authSource,
            authData,
            createIfNotExists: createIfNotExists,
            options: Options(
                client: client,
                authServiceId: authServiceId
            ),
            completionHandler: completionHandler
        )
    }
    
    /**
     Sign in a user with a social identity.
     - parameter authSource: Authentication source enum
     - parameter authData: Authentication data from the social provider
     - parameter client: Define the `Client` to be used for all the requests for the `DataStore` that will be returned. Default value: `Kinvey.sharedClient`
     - parameter completionHandler: Completion handler to be called once the response returns from the server
     */
    @discardableResult
    open class func login<U: User>(
        authSource: AuthSource,
        _ authData: [String : Any],
        createIfNotExists: Bool = true,
        options: Options? = nil,
        completionHandler: ((Result<U, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<U, Swift.Error>> {
        let client = options?.client ?? sharedClient
        if let error = client.validate() {
            DispatchQueue.main.async {
                completionHandler?(.failure(error))
            }
            return AnyRequest(LocalRequest<Result<U, Swift.Error>>())
        }
        
        let requests = MultiRequest<Result<U, Swift.Error>>()
        Promise<U> { resolver in
            let request = client.networkRequestFactory.buildUserSocialLogin(
                authSource,
                authData: authData,
                options: options
            )
            request.execute() { (data, response, error) in
                if let response = response,
                    response.isOK,
                    let user = client.responseParser.parseUser(data) as? U
                {
                    resolver.fulfill(user)
                } else if let response = response,
                    response.isNotFound,
                    createIfNotExists
                {
                    let request = client.networkRequestFactory.buildUserSocialCreate(
                        authSource,
                        authData: authData,
                        options: options
                    )
                    request.execute { (data, response, error) in
                        if let response = response,
                            response.isOK,
                            let user = client.responseParser.parseUser(data) as? U
                        {
                            resolver.fulfill(user)
                        } else {
                            resolver.reject(buildError(data, response, error, client))
                        }
                    }
                    requests += request
                } else {
                    resolver.reject(buildError(data, response, error, client))
                }
            }
            requests += request
        }.done { user in
            client.activeUser = user
            client.clientId = options?.authServiceId
            completionHandler?(.success(user))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return AnyRequest(requests)
    }
    
    /// Sign in a user and set as a current active user.
    @discardableResult
    open class func login<U: User>(
        username: String,
        password: String,
        client: Client = sharedClient,
        completionHandler: UserHandler<U>? = nil
    ) -> AnyRequest<Result<U, Swift.Error>> {
        return login(
            username: username,
            password: password,
            options: Options(
                client: client
            )
        ) { (result: Result<U, Swift.Error>) in
            switch result {
            case .success(let user):
                completionHandler?(user, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /// Sign in a user and set as a current active user.
    @available(*, deprecated: 3.6.0, message: "Please use login(username:password:options:completionHandler:) instead")
    @discardableResult
    open class func login<U: User>(
        username: String,
        password: String,
        client: Client = sharedClient,
        completionHandler: ((Result<U, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<U, Swift.Error>> {
        return login(
            username: username,
            password: password,
            options: Options(
                client: client
            ),
            completionHandler: completionHandler
        )
    }
    
    /// Sign in a user and set as a current active user.
    @discardableResult
    open class func login<U: User>(
        username: String,
        password: String,
        options: Options? = nil,
        completionHandler: ((Result<U, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<U, Swift.Error>> {
        let client = options?.client ?? sharedClient
        if let error = client.validate() {
            DispatchQueue.main.async {
                completionHandler?(.failure(error))
            }
            return AnyRequest(LocalRequest<Result<U, Swift.Error>>())
        }

        let request = client.networkRequestFactory.buildUserLogin(
            username: username,
            password: password,
            options: options,
            resultType: Result<U, Swift.Error>.self
        )
        login(
            request: request,
            client: client,
            userType: U.self,
            completionHandler: completionHandler
        )
        return AnyRequest(request)
    }
    
    /**
     Sends a request to confirm email address to the specified user.
     
     The user must have a valid email set in its `email` field, on the server, for this to work. The user will receive an email with a time-bound link to a verification web page.
     
     - parameter username: Username of the user that needs to send the email confirmation
     - parameter client: define the `Client` to be used for all the requests for the `DataStore` that will be returned. Default value: `Kinvey.sharedClient`
     - parameter completionHandler: Completion handler to be called once the response returns from the server
     */
    @discardableResult
    open class func sendEmailConfirmation(
        forUsername username: String,
        client: Client = sharedClient,
        completionHandler: ((Result<Void, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<Void, Swift.Error>> {
        return sendEmailConfirmation(
            forUsername: username,
            options: Options(
                client: client
            ),
            completionHandler: completionHandler
        )
    }
    
    private class func execute<ResultType>(
        request: HttpRequest<ResultType>,
        client: Client,
        completionHandler: ((Result<Void, Swift.Error>) -> Void)?
    ) {
        Promise<Void> { resolver in
            request.execute() { (data, response, error) in
                if let response = response, response.isOK {
                    resolver.fulfill(())
                } else {
                    resolver.reject(buildError(data, response, error, client))
                }
            }
        }.done {
            completionHandler?(.success($0))
        }.catch { error in
            completionHandler?(.failure(error))
        }
    }
    
    /**
     Sends a request to confirm email address to the specified user.
     
     The user must have a valid email set in its `email` field, on the server, for this to work. The user will receive an email with a time-bound link to a verification web page.
     
     - parameter username: Username of the user that needs to send the email confirmation
     - parameter client: define the `Client` to be used for all the requests for the `DataStore` that will be returned. Default value: `Kinvey.sharedClient`
     - parameter completionHandler: Completion handler to be called once the response returns from the server
     */
    @discardableResult
    open class func sendEmailConfirmation(
        forUsername username: String,
        options: Options? = nil,
        completionHandler: ((Result<Void, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<Void, Swift.Error>> {
        let client = options?.client ?? sharedClient
        let request = client.networkRequestFactory.buildSendEmailConfirmation(
            forUsername: username,
            options: options,
            resultType: Result<Void, Swift.Error>.self
        )
        execute(
            request: request,
            client: client,
            completionHandler: completionHandler
        )
        return AnyRequest(request)
    }
    
    /**
     Sends a request to confirm email address to the user.
     
     The user must have a valid email set in its `email` field, on the server, for this to work. The user will receive an email with a time-bound link to a verification web page.
     
     - parameter client: define the `Client` to be used for all the requests for the `DataStore` that will be returned. Default value: `Kinvey.sharedClient`
     - parameter completionHandler: Completion handler to be called once the response returns from the server
     */
    @discardableResult
    open func sendEmailConfirmation(
        options: Options? = nil,
        completionHandler: ((Result<Void, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<Void, Swift.Error>> {
        guard let _ = email else {
            DispatchQueue.main.async {
                completionHandler?(.failure(Error.invalidOperation(description: "Email is required to send the email confirmation")))
            }
            return AnyRequest(LocalRequest<Result<Void, Swift.Error>>())
        }
        
        return User.sendEmailConfirmation(
            forUsername: username!,
            options: options,
            completionHandler: completionHandler
        )
    }
    
    /// Sends an email to the user with a link to reset the password
    @discardableResult
    private class func resetPassword(
        usernameOrEmail: String,
        client: Client = sharedClient,
        completionHandler: VoidHandler? = nil
    ) -> AnyRequest<Result<Void, Swift.Error>> {
        return resetPassword(
            usernameOrEmail: usernameOrEmail,
            client: client
        ) { (result: Result<Void, Swift.Error>) in
            switch result {
            case .success:
                completionHandler?(nil)
            case .failure(let error):
                completionHandler?(error)
            }
        }
    }
    
    /// Sends an email to the user with a link to reset the password
    @discardableResult
    open class func resetPassword(
        usernameOrEmail: String,
        client: Client = sharedClient,
        completionHandler: ((Result<Void, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<Void, Swift.Error>> {
        return resetPassword(
            usernameOrEmail: usernameOrEmail,
            options: Options(
                client: client
            ),
            completionHandler: completionHandler
        )
    }
    
    /// Sends an email to the user with a link to reset the password
    @discardableResult
    open class func resetPassword(
        usernameOrEmail: String,
        options: Options? = nil,
        completionHandler: ((Result<Void, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<Void, Swift.Error>> {
        let client = options?.client ?? sharedClient
        let request = client.networkRequestFactory.buildUserResetPassword(
            usernameOrEmail: usernameOrEmail,
            options: options,
            resultType: Result<Void, Swift.Error>.self
        )
        execute(
            request: request,
            client: client,
            completionHandler: completionHandler
        )
        return AnyRequest(request)
    }
    
    /// Sends an email to the user with a link to reset the password using the `username` property.
    @discardableResult
    @available(*, deprecated: 3.3.4, message: "Use resetPassword(usernameOrEmail:) instead")
    open class func resetPassword(
        username: String,
        client: Client = sharedClient,
        completionHandler: VoidHandler? = nil
    ) -> AnyRequest<Result<Void, Swift.Error>> {
        return resetPassword(
            usernameOrEmail: username,
            client: client,
            completionHandler:  completionHandler
        )
    }
    
    /// Sends an email to the user with a link to reset the password using the `email` property.
    @discardableResult
    @available(*, deprecated: 3.3.4, message: "Use resetPassword(usernameOrEmail:) instead")
    open class func resetPassword(
        email: String,
        client: Client = sharedClient,
        completionHandler: VoidHandler? = nil
    ) -> AnyRequest<Result<Void, Swift.Error>> {
        return resetPassword(
            usernameOrEmail: email,
            client: client,
            completionHandler:  completionHandler
        )
    }
    
    /// Sends an email to the user with a link to reset the password.
    @discardableResult
    open func resetPassword(
        options: Options? = nil,
        completionHandler: ((Result<Void, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<Void, Swift.Error>> {
        if let email = email {
            return User.resetPassword(
                usernameOrEmail: email,
                options: options,
                completionHandler: completionHandler
            )
        } else if let username = username  {
            return User.resetPassword(
                usernameOrEmail: username,
                options: options,
                completionHandler: completionHandler
            )
        } else if let completionHandler = completionHandler {
            DispatchQueue.main.async(execute: { () -> Void in
                completionHandler(.failure(Error.userWithoutEmailOrUsername))
            })
        }
        return AnyRequest(LocalRequest<Result<Void, Swift.Error>>())
    }
    
    /**
     Changes the password for the current user and automatically updates the session with a new valid session.
     - parameter newPassword: A new password for the user
     - parameter client: Define the `Client` to be used for all the requests for the `DataStore` that will be returned. Default value: `Kinvey.sharedClient`
     - parameter completionHandler: Completion handler to be called once the response returns from the server
     */
    @discardableResult
    open func changePassword<U: User>(
        newPassword: String,
        completionHandler: UserHandler<U>? = nil
    ) -> AnyRequest<Result<U, Swift.Error>> {
        return changePassword(
            newPassword: newPassword,
            options: nil
        ) { (result: Result<U, Swift.Error>) in
            switch result {
            case .success(let user):
                completionHandler?(user, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /**
     Changes the password for the current user and automatically updates the session with a new valid session.
     - parameter newPassword: A new password for the user
     - parameter client: Define the `Client` to be used for all the requests for the `DataStore` that will be returned. Default value: `Kinvey.sharedClient`
     - parameter completionHandler: Completion handler to be called once the response returns from the server
     */
    @discardableResult
    open func changePassword<U: User>(
        newPassword: String,
        completionHandler: ((Result<U, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<U, Swift.Error>> {
        return changePassword(
            newPassword: newPassword,
            options: nil,
            completionHandler: completionHandler
        )
    }
    
    /**
     Changes the password for the current user and automatically updates the session with a new valid session.
     - parameter newPassword: A new password for the user
     - parameter client: Define the `Client` to be used for all the requests for the `DataStore` that will be returned. Default value: `Kinvey.sharedClient`
     - parameter completionHandler: Completion handler to be called once the response returns from the server
     */
    @discardableResult
    open func changePassword<U: User>(
        newPassword: String,
        options: Options? = nil,
        completionHandler: ((Result<U, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<U, Swift.Error>> {
        return save(
            newPassword: newPassword,
            options: options,
            completionHandler: completionHandler
        )
    }
    
    /**
     Sends an email with the username associated with the email provided.
     - parameter email: Email associated with the user
     - parameter client: Define the `Client` to be used for all the requests for the `DataStore` that will be returned. Default value: `Kinvey.sharedClient`
     - parameter completionHandler: Completion handler to be called once the response returns from the server
     */
    @discardableResult
    open class func forgotUsername(
        email: String,
        client: Client = sharedClient,
        completionHandler: ((Result<Void, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<Void, Swift.Error>> {
        return forgotUsername(
            email: email,
            options: Options(
                client: client
            ),
            completionHandler: completionHandler
        )
    }
    
    /**
     Sends an email with the username associated with the email provided.
     - parameter email: Email associated with the user
     - parameter client: Define the `Client` to be used for all the requests for the `DataStore` that will be returned. Default value: `Kinvey.sharedClient`
     - parameter completionHandler: Completion handler to be called once the response returns from the server
     */
    @discardableResult
    open class func forgotUsername(
        email: String,
        options: Options? = nil,
        completionHandler: ((Result<Void, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<Void, Swift.Error>> {
        let client = options?.client ?? sharedClient
        let request = client.networkRequestFactory.buildUserForgotUsername(
            email: email,
            options: options,
            resultType: Result<Void, Swift.Error>.self
        )
        execute(
            request: request,
            client: client,
            completionHandler: completionHandler
        )
        return AnyRequest(request)
    }
    
    /// Checks if a `username` already exists or not.
    @discardableResult
    open class func exists(
        username: String,
        client: Client = sharedClient,
        completionHandler: BoolHandler? = nil
    ) -> AnyRequest<Result<Bool, Swift.Error>> {
        return exists(
            username: username,
            client: client
        ) { (result: Result<Bool, Swift.Error>) in
            switch result {
            case .success(let exists):
                completionHandler?(exists, nil)
            case .failure(let error):
                completionHandler?(false, error)
            }
        }
    }
    
    /// Checks if a `username` already exists or not.
    @discardableResult
    open class func exists(
        username: String,
        client: Client = sharedClient,
        completionHandler: ((Result<Bool, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<Bool, Swift.Error>> {
        return exists(
            username: username,
            options: Options(
                client: client
            ),
            completionHandler: completionHandler
        )
    }
    
    /// Checks if a `username` already exists or not.
    @discardableResult
    open class func exists(
        username: String,
        options: Options? = nil,
        completionHandler: ((Result<Bool, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<Bool, Swift.Error>> {
        let client = options?.client ?? sharedClient
        let request = client.networkRequestFactory.buildUserExists(
            username: username,
            options: options,
            resultType: Result<Bool, Swift.Error>.self
        )
        Promise<Bool> { resolver in
            request.execute() { (data, response, error) in
                if let response = response,
                    response.isOK,
                    let json = client.responseParser.parse(data),
                    let usernameExists = json["usernameExists"] as? Bool
                {
                    resolver.fulfill(usernameExists)
                } else {
                    resolver.reject(buildError(data, response, error, client))
                }
            }
        }.done { exists in
            completionHandler?(.success(exists))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return AnyRequest(request)
    }
    
    /// Gets a `User` instance using the `userId` property.
    @discardableResult
    open class func get<U: User>(
        userId: String,
        client: Client = sharedClient,
        completionHandler: UserHandler<U>? = nil
    ) -> AnyRequest<Result<U, Swift.Error>> {
        return get(
            userId: userId,
            client: client
        ) { (result: Result<U, Swift.Error>) in
            switch result {
            case .success(let user):
                completionHandler?(user, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /// Gets a `User` instance using the `userId` property.
    @discardableResult
    open class func get<U: User>(
        userId: String,
        client: Client = sharedClient,
        completionHandler: ((Result<U, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<U, Swift.Error>> {
        return get(
            userId: userId,
            options: Options(
                client: client
            ),
            completionHandler: completionHandler
        )
    }
    
    /// Gets a `User` instance using the `userId` property.
    @discardableResult
    open class func get<U: User>(
        userId: String,
        options: Options? = nil,
        completionHandler: ((Result<U, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<U, Swift.Error>> {
        let client = options?.client ?? sharedClient
        let request = client.networkRequestFactory.buildUserGet(
            userId: userId,
            options: options,
            resultType: Result<U, Swift.Error>.self
        )
        Promise<U> { resolver in
            request.execute() { (data, response, error) in
                if let response = response,
                    response.isOK,
                    let user = client.responseParser.parseUser(data) as? U
                {
                    resolver.fulfill(user)
                } else {
                    resolver.reject(buildError(data, response, error, client))
                }
            }
        }.done { user in
            completionHandler?(.success(user))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return AnyRequest(request)
    }
    
    /// Gets a `User` instance using the `userId` property.
    @available(*, deprecated: 3.6.0, message: "Please use find(query:options:completionHandler:) instead")
    @discardableResult
    open func find<U: User>(
        query: Query = Query(),
        client: Client = sharedClient,
        completionHandler: ((Result<[U], Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<[U], Swift.Error>> {
        return find(
            query: query,
            options: Options(
                client: client
            ),
            completionHandler: completionHandler
        )
    }
    
    /// Gets a `User` instance using the `userId` property.
    @discardableResult
    open func find<U: User>(
        query: Query = Query(),
        options: Options? = nil,
        completionHandler: ((Result<[U], Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<[U], Swift.Error>> {
        let client = options?.client ?? self.client
        let request = client.networkRequestFactory.buildUserFind(
            query: query,
            options: options,
            resultType: Result<[U], Swift.Error>.self
        )
        Promise<[U]> { resolver in
            request.execute() { (data, response, error) in
                if let response = response,
                    response.isOK,
                    let user = client.responseParser.parseUsers(data) as? [U]
                {
                    resolver.fulfill(user)
                } else {
                    resolver.reject(buildError(data, response, error, client))
                }
            }
        }.done { users in
            completionHandler?(.success(users))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return AnyRequest(request)
    }
    
    /// Refresh the user's data.
    @discardableResult
    open func refresh(
        options: Options? = nil,
        completionHandler: ((Result<Void, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<Void, Swift.Error>> {
        let client = options?.client ?? self.client
        let request = client.networkRequestFactory.buildUserMe(
            options: options,
            resultType: Result<Void, Swift.Error>.self
        )
        Promise<Void> { resolver in
            request.execute() { (data, response, error) in
                if let response = response,
                    response.isOK,
                    let json = self.client.responseParser.parse(data)
                {
                    let map = Map(mappingType: .fromJSON, JSON: json)
                    self.mapping(map: map)
                    if self == self.client.activeUser {
                        self.client.activeUser = self
                    }
                    resolver.fulfill(())
                } else {
                    resolver.reject(buildError(data, response, error, self.client))
                }
            }
        }.done {
            completionHandler?(.success($0))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return AnyRequest(request)
    }
    
    /// Default Constructor.
    public init(
        userId: String? = nil,
        acl: Acl? = nil,
        metadata: UserMetadata? = nil,
        client: Client = sharedClient
    ) {
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
        
        userId <- map[Entity.Key.entityId]
        guard let userIdValue = userId else {
            return nil
        }
        
        acl <- map[Entity.Key.acl]
        metadata <- map[Entity.Key.metadata]
        self.init(userId: userIdValue, acl: acl, metadata: metadata)
    }
    
    /// This function is where all variable mappings should occur. It is executed by Mapper during the mapping (serialization and deserialization) process.
    open func mapping(map: Map) {
        _userId <- map[Entity.Key.entityId]
        acl <- map[Entity.Key.acl]
        metadata <- map[Entity.Key.metadata]
        socialIdentity <- map["_socialIdentity"]
        username <- map["username"]
        email <- map["email"]
    }
    
    /// Sign out the current active user.
    @discardableResult
    open func logout(
        options: Options? = nil,
        completionHandler: ((Result<Void, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<Void, Swift.Error>> {
        let request = client.networkRequestFactory.buildUserLogout(
            user: self,
            options: options,
            resultType: Result<Void, Swift.Error>.self
        )
        Promise<Void> { resolver in
            request.execute { data, response, error in
                if let response = response,
                    response.isOK
                {
                    resolver.fulfill(())
                } else {
                    resolver.reject(error ?? buildError(data, response, error, self.client))
                }
            }
            if self == client.activeUser {
                client.activeUser = nil
            }
        }.done {
            completionHandler?(.success($0))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return AnyRequest(request)
    }
    
    /// Creates or updates a `User`.
    @discardableResult
    open func save<U: User>(
        newPassword: String? = nil,
        completionHandler: UserHandler<U>? = nil
    ) -> AnyRequest<Result<U, Swift.Error>> {
        return save(
            newPassword: newPassword
        ) { (result: Result<U, Swift.Error>) in
            switch result {
            case .success(let user):
                completionHandler?(user, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /// Creates or updates a `User`.
    @discardableResult
    open func save<U: User>(
        newPassword: String? = nil,
        options: Options? = nil,
        completionHandler: ((Result<U, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<U, Swift.Error>> {
        let client = options?.client ?? sharedClient
        let request = client.networkRequestFactory.buildUserSave(
            user: self,
            newPassword: newPassword,
            options: options,
            resultType: Result<U, Swift.Error>.self
        )
        Promise<U> { resolver in
            request.execute() { (data, response, error) in
                if let response = response,
                    response.isOK,
                    let user = client.responseParser.parseUser(data) as? U
                {
                    if user.userId == client.activeUser?.userId {
                        self.client.activeUser = user
                    }
                    resolver.fulfill(user)
                } else {
                    resolver.reject(buildError(data, response, error, self.client))
                }
            }
        }.done { user in
            completionHandler?(.success(user))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return AnyRequest(request)
    }
    
    /**
     This method allows users to do exact queries for other users restricted to the `UserQuery` attributes.
     */
    @discardableResult
    open func lookup<U: User>(
        _ userQuery: UserQuery,
        completionHandler: UsersHandler<U>? = nil
    ) -> AnyRequest<Result<[U], Swift.Error>> {
        return lookup(userQuery) { (result: Result<[U], Swift.Error>) in
            switch result {
            case .success(let users):
                completionHandler?(users, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /**
     This method allows users to do exact queries for other users restricted to the `UserQuery` attributes.
     */
    @discardableResult
    open func lookup<U: User>(
        _ userQuery: UserQuery,
        options: Options? = nil,
        completionHandler: ((Result<[U], Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<[U], Swift.Error>> {
        let client = options?.client ?? sharedClient
        let request = client.networkRequestFactory.buildUserLookup(
            user: self,
            userQuery: userQuery,
            options: options,
            resultType: Result<[U], Swift.Error>.self
        )
        Promise<[U]> { resolver in
            request.execute() { (data, response, error) in
                if let response = response,
                    response.isOK,
                    let users: [U] = client.responseParser.parseUsers(data)
                {
                    resolver.fulfill(users)
                } else {
                    resolver.reject(buildError(data, response, error, self.client))
                }
            }
        }.done { users in
            completionHandler?(.success(users))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return AnyRequest(request)
    }
    
    /// Register the user to start performing realtime / live calls
    @discardableResult
    open func registerForRealtime(
        options: Options? = nil,
        completionHandler: ((Result<Void, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<Void, Swift.Error>> {
        let request = client.networkRequestFactory.buildUserRegisterRealtime(
            user: self,
            deviceId: deviceId,
            options: options,
            resultType: Result<Void, Swift.Error>.self
        )
        Promise<Void> { resolver in
            request.execute() { (data, response, error) in
                if let response = response,
                    response.isOK,
                    let data = data,
                    let json = self.client.responseParser.parse(data),
                    let subscribeKey = json["subscribeKey"] as? String,
                    let publishKey = json["publishKey"] as? String,
                    let userChannelGroup = json["userChannelGroup"] as? String
                {
                    self.realtimeRouter = PubNubRealtimeRouter(user: self, subscribeKey: subscribeKey, publishKey: publishKey, userChannelGroup: userChannelGroup)
                    resolver.fulfill(())
                } else {
                    resolver.reject(buildError(data, response, error, self.client))
                }
            }
        }.done {
            completionHandler?(.success($0))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return AnyRequest(request)
    }
    
    /// Unregister the user to stop performing realtime / live calls
    @discardableResult
    open func unregisterForRealtime(
        options: Options? = nil,
        completionHandler: ((Result<Void, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<Void, Swift.Error>> {
        let request = client.networkRequestFactory.buildUserUnregisterRealtime(
            user: self,
            deviceId: deviceId,
            options: options,
            resultType: Result<Void, Swift.Error>.self
        )
        Promise<Void> { resolver in
            request.execute() { (data, response, error) in
                if let response = response, response.isOK {
                    self.realtimeRouter = nil
                    resolver.fulfill(())
                } else {
                    resolver.reject(buildError(data, response, error, self.client))
                }
            }
        }.done {
            completionHandler?(.success($0))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return AnyRequest(request)
    }
    
    internal static let authtokenPrefix = "Kinvey "
    
    /// Autorization header used for calls that requires a logged `User`.
    open var authorizationHeader: String? {
        var authorization: String? = nil
        if let authtoken = metadata?.authtoken {
            authorization = "Kinvey \(authtoken)"
        }
        return authorization
    }
    
    /**
     Login with MIC using Automated Authorization Grant Flow. We strongly recommend use [Authorization Code Grant Flow](http://devcenter.kinvey.com/rest/guides/mobile-identity-connect#authorization-grant) instead of [Automated Authorization Grant Flow](http://devcenter.kinvey.com/rest/guides/mobile-identity-connect#automated-authorization-grant) for security reasons.
     */
    @available(*, deprecated: 3.16.0, message: "Please use login(username:password:provider:options:completionHandler:) instead")
    open class func login<U: User>(
        redirectURI: URL,
        username: String,
        password: String,
        authServiceId: String? = nil,
        client: Client = sharedClient,
        completionHandler: UserHandler<U>? = nil
    ) {
        return login(
            redirectURI: redirectURI,
            username: username,
            password: password,
            authServiceId: authServiceId,
            client: client
        ) { (result: Result<U, Swift.Error>) in
            switch result {
            case .success(let user):
                completionHandler?(user, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /**
     Login with MIC using Automated Authorization Grant Flow. We strongly recommend use [Authorization Code Grant Flow](http://devcenter.kinvey.com/rest/guides/mobile-identity-connect#authorization-grant) instead of [Automated Authorization Grant Flow](http://devcenter.kinvey.com/rest/guides/mobile-identity-connect#automated-authorization-grant) for security reasons.
     */
    @available(*, deprecated: 3.16.0, message: "Please use login(username:password:provider:options:completionHandler:) instead")
    open class func login<U: User>(
        redirectURI: URL,
        username: String,
        password: String,
        authServiceId: String? = nil,
        client: Client = sharedClient,
        completionHandler: ((Result<U, Swift.Error>) -> Void)? = nil
    ) {
        return login(
            redirectURI: redirectURI,
            username: username,
            password: password,
            options: Options(
                client: client,
                authServiceId: authServiceId
            ),
            completionHandler: completionHandler
        )
    }
    
    /**
     Login with MIC using Automated Authorization Grant Flow. We strongly recommend use [Authorization Code Grant Flow](http://devcenter.kinvey.com/rest/guides/mobile-identity-connect#authorization-grant) instead of [Automated Authorization Grant Flow](http://devcenter.kinvey.com/rest/guides/mobile-identity-connect#automated-authorization-grant) for security reasons.
     */
    @available(*, deprecated: 3.16.0, message: "Please use login(username:password:provider:options:completionHandler:) instead")
    open class func login<U: User>(
        redirectURI: URL,
        username: String,
        password: String,
        options: Options? = nil,
        completionHandler: ((Result<U, Swift.Error>) -> Void)? = nil
    ) {
        MIC.login(
            redirectURI: redirectURI,
            username: username,
            password: password,
            options: options,
            completionHandler: completionHandler
        )
    }
    
    /**
     Login with MIC using Automated Authorization Grant Flow. We strongly recommend use [Authorization Code Grant Flow](http://devcenter.kinvey.com/rest/guides/mobile-identity-connect#authorization-grant) instead of [Automated Authorization Grant Flow](http://devcenter.kinvey.com/rest/guides/mobile-identity-connect#automated-authorization-grant) for security reasons.
     */
    @discardableResult
    open class func login<U: User>(
        username: String,
        password: String,
        provider: AuthProvider,
        options: Options? = nil,
        completionHandler: ((Result<U, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<U, Swift.Error>> {
        switch provider {
        case .kinvey:
            return login(
                username: username,
                password: password,
                options: options,
                completionHandler: completionHandler
            )
        case .mic:
            return MIC.login(
                username: username,
                password: password,
                options: options,
                completionHandler: completionHandler
            )
        }
    }

#if os(iOS)
    
    static let MICSafariViewControllerSuccessNotificationName = NSNotification.Name("Kinvey.User.MICSafariViewController.Success")
    static let MICSafariViewControllerFailureNotificationName = NSNotification.Name("Kinvey.User.MICSafariViewController.Failure")
    
    private static var MICSafariViewControllerSuccessNotificationObserver: Any? = nil {
        willSet {
            if let token = MICSafariViewControllerSuccessNotificationObserver {
                NotificationCenter.default.removeObserver(token, name: MICSafariViewControllerSuccessNotificationName, object: nil)
                NotificationCenter.default.removeObserver(token, name: MICSafariViewControllerFailureNotificationName, object: nil)
            }
        }
    }
    
    private static var MICSafariViewControllerFailureNotificationObserver: Any? = nil {
        willSet {
            if let token = MICSafariViewControllerFailureNotificationObserver {
                NotificationCenter.default.removeObserver(token, name: MICSafariViewControllerSuccessNotificationName, object: nil)
                NotificationCenter.default.removeObserver(token, name: MICSafariViewControllerFailureNotificationName, object: nil)
            }
        }
    }
    
    /// Performs a login using the MIC Redirect URL that contains a temporary token.
    @available(*, deprecated: 3.6.0, message: "Please use login(redirectURI:micURL:options:) instead")
    open class func login(
        redirectURI: URL,
        micURL: URL,
        authServiceId: String? = nil,
        client: Client = sharedClient
    ) -> Bool {
        return login(
            redirectURI: redirectURI,
            micURL: micURL,
            options: Options(
                client: client,
                authServiceId: authServiceId
            )
        )
    }
    
    /// Performs a login using the MIC Redirect URL that contains a temporary token.
    open class func login(
        redirectURI: URL,
        micURL: URL,
        options: Options? = nil
    ) -> Bool {
        if let code = MIC.parseCode(redirectURI: redirectURI, url: micURL) {
            MIC.login(
                redirectURI: redirectURI,
                code: code,
                options: options
            ) { result in
                switch result {
                case .success(let user):
                    NotificationCenter.default.post(
                        name: MICSafariViewControllerSuccessNotificationName,
                        object: user
                    )
                case .failure(let error):
                    NotificationCenter.default.post(
                        name: MICSafariViewControllerFailureNotificationName,
                        object: error
                    )
                }
            }
            return true
        }
        return false
    }

    /// Presents the MIC View Controller to sign in a user using MIC (Mobile Identity Connect).
    @available(*, deprecated: 3.3.2, message: "Please use the method presentMICViewController(micUserInterface:) instead")
    open class func presentMICViewController(
        redirectURI: URL,
        timeout: TimeInterval = 0,
        forceUIWebView: Bool,
        authServiceId: String? = nil,
        client: Client = sharedClient,
        completionHandler: UserHandler<User>? = nil
    ) {
        presentMICViewController(
            redirectURI: redirectURI,
            timeout: timeout,
            micUserInterface: forceUIWebView ? .uiWebView : .wkWebView,
            authServiceId: authServiceId,
            client: client,
            completionHandler: completionHandler
        )
    }
    
    /// Presents the MIC View Controller to sign in a user using MIC (Mobile Identity Connect).
    open class func presentMICViewController<U: User>(
        redirectURI: URL,
        timeout: TimeInterval = 0,
        micUserInterface: MICUserInterface = MICUserInterface.default,
        currentViewController: UIViewController? = nil,
        authServiceId: String? = nil,
        client: Client = sharedClient,
        completionHandler: UserHandler<U>? = nil
    ) {
        presentMICViewController(
            redirectURI: redirectURI,
            timeout: timeout,
            micUserInterface: micUserInterface,
            currentViewController: currentViewController,
            authServiceId: authServiceId,
            client: client
        ) { (result: Result<U, Swift.Error>) in
            switch result {
            case .success(let user):
                completionHandler?(user, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /// Presents the MIC View Controller to sign in a user using MIC (Mobile Identity Connect).
    open class func presentMICViewController<U: User>(
        redirectURI: URL,
        timeout: TimeInterval = 0,
        micUserInterface: MICUserInterface = MICUserInterface.default,
        currentViewController: UIViewController? = nil,
        authServiceId: String? = nil,
        client: Client = sharedClient,
        completionHandler: ((Result<U, Swift.Error>) -> Void)? = nil
    ) {
        presentMICViewController(
            redirectURI: redirectURI,
            micUserInterface: micUserInterface,
            currentViewController: currentViewController,
            options: Options(
                client: client,
                authServiceId: authServiceId,
                timeout: timeout
            ),
            completionHandler: completionHandler
        )
    }
    
    /// Presents the MIC View Controller to sign in a user using MIC (Mobile Identity Connect).
    open class func presentMICViewController<U: User>(
        redirectURI: URL,
        micUserInterface: MICUserInterface = MICUserInterface.default,
        currentViewController: UIViewController? = nil,
        options: Options? = nil,
        completionHandler: ((Result<U, Swift.Error>) -> Void)? = nil
    ) {
        let client = options?.client ?? sharedClient
        if let error = client.validate() {
            DispatchQueue.main.async {
                completionHandler?(.failure(error))
            }
            return
        }
        
        Promise<U> { resolver in
            var micVC: UIViewController!
            
            let loginWithSafariViewController: (URL) -> Void = { url in
                micVC = SFSafariViewController(url: url)
                micVC.modalPresentationStyle = .overCurrentContext
                MICSafariViewControllerSuccessNotificationObserver = NotificationCenter.default.addObserver(
                    forName: MICSafariViewControllerSuccessNotificationName,
                    object: nil,
                    queue: OperationQueue.main)
                { notification in
                    micVC.dismiss(animated: true) {
                        MICSafariViewControllerSuccessNotificationObserver = nil
                        
                        if let user = notification.object as? U {
                            resolver.fulfill(user)
                        } else {
                            resolver.reject(Error.invalidResponse(httpResponse: nil, data: nil))
                        }
                    }
                }
                MICSafariViewControllerFailureNotificationObserver = NotificationCenter.default.addObserver(
                    forName: MICSafariViewControllerFailureNotificationName,
                    object: nil,
                    queue: OperationQueue.main)
                { notification in
                    micVC.dismiss(animated: true) {
                        MICSafariViewControllerFailureNotificationObserver = nil
                        
                        if let error = notification.object as? Swift.Error {
                            resolver.reject(error)
                        } else {
                            resolver.reject(Error.invalidResponse(httpResponse: nil, data: nil))
                        }
                    }
                }
            }
            
            switch micUserInterface {
            case .safari:
                let url = MIC.urlForLogin(
                    redirectURI: redirectURI,
                    options: options
                )
                loginWithSafariViewController(url)
            case .safariAuthenticationSession:
                let url = MIC.urlForLogin(
                    redirectURI: redirectURI,
                    options: options
                )
                if #available(iOS 11.0, *) {
                    var timer: Timer? = nil
                    var authSession: SFAuthenticationSession?
                    authSession = SFAuthenticationSession(
                        url: url,
                        callbackURLScheme: redirectURI.scheme
                    ) { (url, error) in
                        authSession = nil
                        timer?.invalidate()
                        timer = nil
                        if let url = url, let code = MIC.parseCode(redirectURI: redirectURI, url: url) {
                            MIC.login(
                                redirectURI: redirectURI,
                                code: code,
                                options: options
                            ) { (result: Result<U, Swift.Error>) in
                                switch result {
                                case .success(let user):
                                    resolver.fulfill(user)
                                case .failure(let error):
                                    resolver.reject(error)
                                }
                            }
                        } else {
                            resolver.reject(buildError(nil, nil, error, client))
                        }
                    }
                    if let authSession = authSession, authSession.start() {
                        if let timeout = options?.timeout, timeout > 0 {
                            timer = Timer.scheduledTimer(
                                withTimeInterval: timeout,
                                repeats: false
                            ) { (timer) in
                                authSession.cancel()
                                timer.invalidate()
                            }
                        }
                    } else {
                        resolver.reject(buildError(nil, nil, nil, client))
                    }
                    return
                } else {
                    log.warning("SFAuthenticationSession only available for iOS 11 and above. Using SFSafariViewController instead.")
                    loginWithSafariViewController(url)
                }
            default:
                let forceUIWebView = micUserInterface == .uiWebView
                let micLoginVC = MICLoginViewController(
                    redirectURI: redirectURI,
                    userType: client.userType,
                    forceUIWebView: forceUIWebView,
                    options: options
                ) { (result) in
                    switch result {
                    case .success(let user):
                        resolver.fulfill(user as! U)
                    case .failure(let error):
                        resolver.reject(error)
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
        }.done { user -> Void in
            completionHandler?(.success(user))
        }.catch { error in
            completionHandler?(.failure(error))
        }
    }
#endif

}

extension User /* Hashable */ {

    open override var hashValue: Int {
        return userId.hashValue
    }
    
    // Obj-C
    open override var hash: Int {
        return hashValue
    }

}

extension User /* Equatable */ {

    open static func == (lhs: User, rhs: User) -> Bool {
        return lhs.userId == rhs.userId
    }

    // Obj-C
    open override func isEqual(_ object: Any?) -> Bool {
        guard let otherUser = object as? User else {
            return false
        }
        return self == otherUser
    }

}

/// Holds the Social Identities attached to a specific User
public struct UserSocialIdentity : StaticMappable {
    
    /// Facebook social identity
    public var facebook: [String : Any]?
    
    /// Twitter social identity
    public var twitter: [String : Any]?
    
    /// Google+ social identity
    public var googlePlus: [String : Any]?
    
    /// LinkedIn social identity
    public var linkedIn: [String : Any]?
    
    /// Kinvey MIC social identity
    public var kinvey: [String : Any]?
    
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

public enum AuthProvider {
    
    case kinvey
    case mic
    
}
