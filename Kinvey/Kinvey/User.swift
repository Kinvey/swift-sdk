//
//  User.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import PromiseKit

#if os(iOS) || os(OSX)
    import SafariServices
#endif

/// Class that represents an `User`.
open class User: NSObject, Credential {
    
    /// Username Key.
    @available(*, deprecated: 3.17.0, message: "Please use User.CodingKeys.username instead")
    open static let PersistableUsernameKey = "username"
    
    @available(*, deprecated: 3.17.0, message: "Please use Result<U, Swift.Error> instead")
    public typealias UserHandler<U: User> = (U?, Swift.Error?) -> Void
    
    @available(*, deprecated: 3.17.0, message: "Please use Result<[U], Swift.Error> instead")
    public typealias UsersHandler<U: User> = ([U]?, Swift.Error?) -> Void
    
    @available(*, deprecated: 3.17.0, message: "Please use Result<Void, Swift.Error> instead")
    public typealias VoidHandler = (Swift.Error?) -> Void
    
    @available(*, deprecated: 3.17.0, message: "Please use Result<Bool, Swift.Error> instead")
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
    
    var socialIdentityDictionary: [String : Any]? {
        get {
            guard let socialIdentity = socialIdentity else {
                return nil
            }
            var socialIdentityDictionary = [String : Any]()
            if let facebook = socialIdentity.facebook {
                socialIdentityDictionary[UserSocialIdentity.CodingKeys.facebook] = facebook
            }
            if let twitter = socialIdentity.twitter {
                socialIdentityDictionary[UserSocialIdentity.CodingKeys.twitter] = twitter
            }
            if let googlePlus = socialIdentity.googlePlus {
                socialIdentityDictionary[UserSocialIdentity.CodingKeys.googlePlus] = googlePlus
            }
            if let linkedIn = socialIdentity.linkedIn {
                socialIdentityDictionary[UserSocialIdentity.CodingKeys.linkedIn] = linkedIn
            }
            if let kinvey = socialIdentity.kinvey {
                socialIdentityDictionary[UserSocialIdentity.CodingKeys.kinvey] = kinvey
            }
            return socialIdentityDictionary
        }
        set {
            guard let newValue = newValue else {
                self.socialIdentity = nil
                return
            }
            var socialIdentity = UserSocialIdentity()
            socialIdentity.facebook = newValue[UserSocialIdentity.CodingKeys.facebook] as? [String : Any]
            socialIdentity.twitter = newValue[UserSocialIdentity.CodingKeys.twitter] as? [String : Any]
            socialIdentity.googlePlus = newValue[UserSocialIdentity.CodingKeys.googlePlus] as? [String : Any]
            socialIdentity.linkedIn = newValue[UserSocialIdentity.CodingKeys.linkedIn] as? [String : Any]
            socialIdentity.kinvey = newValue[UserSocialIdentity.CodingKeys.kinvey] as? [String : Any]
            self.socialIdentity = socialIdentity
        }
    }
    
    /// `username` property of the user.
    open var username: String?
    
    /// `email` property of the user.
    open var email: String?
    
    internal var client: Client
    
    internal var realtimeRouter: RealtimeRouter?
    
    /// Creates a new `User` taking (optionally) a username and password. If no `username` or `password` was provided, random values will be generated automatically.
    @discardableResult
    @available(*, deprecated: 3.17.0, message: "Please use User.signup(username:password:user:options:completionHandler:) instead")
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
    @available(*, deprecated: 3.17.0, message: "Please use User.signup(username:password:user:options:completionHandler:) instead")
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
            options: try! Options(client: client),
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
                    let data = data,
                    let user = try? client.jsonParser.parseUser(U.self, from: data)
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
        do {
            try client.validate()
        } catch {
            return errorRequest(error: error, completionHandler: completionHandler)
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
    @available(*, deprecated: 3.17.0, message: "Please use User.login(authSource:_:createIfNotExists:options:completionHandler:) instead")
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
    @available(*, deprecated: 3.17.0, message: "Please use User.login(authSource:_:createIfNotExists:options:completionHandler:) instead")
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
            options: try! Options(
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
        do {
            try client.validate()
        } catch {
            return errorRequest(error: error, completionHandler: completionHandler)
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
                    let data = data,
                    let user = try? client.jsonParser.parseUser(U.self, from: data)
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
                            let data = data,
                            let user = try? client.jsonParser.parseUser(U.self, from: data)
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
    @available(*, deprecated: 3.17.0, message: "Please use User.login(username:password:provider:options:completionHandler:) instead")
    open class func login<U: User>(
        username: String,
        password: String,
        client: Client = sharedClient,
        completionHandler: UserHandler<U>? = nil
    ) -> AnyRequest<Result<U, Swift.Error>> {
        return login(
            username: username,
            password: password,
            options: try! Options(client: client)
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
     Sends a request to confirm email address to the specified user.
     
     The user must have a valid email set in its `email` field, on the server, for this to work. The user will receive an email with a time-bound link to a verification web page.
     
     - parameter username: Username of the user that needs to send the email confirmation
     - parameter client: define the `Client` to be used for all the requests for the `DataStore` that will be returned. Default value: `Kinvey.sharedClient`
     - parameter completionHandler: Completion handler to be called once the response returns from the server
     */
    @discardableResult
    @available(*, deprecated: 3.17.0, message: "Please use User.sendEmailConfirmation(forUsername:options:completionHandler:) instead")
    open class func sendEmailConfirmation(
        forUsername username: String,
        client: Client = sharedClient,
        completionHandler: ((Result<Void, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<Void, Swift.Error>> {
        return sendEmailConfirmation(
            forUsername: username,
            options: try! Options(client: client),
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
            return errorRequest(error: Error.invalidOperation(description: "Email is required to send the email confirmation"), completionHandler: completionHandler)
        }
        
        return User.sendEmailConfirmation(
            forUsername: username!,
            options: options,
            completionHandler: completionHandler
        )
    }
    
    /// Sends an email to the user with a link to reset the password
    @discardableResult
    @available(*, deprecated: 3.17.0, message: "Please use User.resetPassword(usernameOrEmail:options:completionHandler:) instead")
    open class func resetPassword(
        usernameOrEmail: String,
        client: Client = sharedClient,
        completionHandler: ((Result<Void, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<Void, Swift.Error>> {
        return resetPassword(
            usernameOrEmail: usernameOrEmail,
            options: try! Options(client: client),
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
        }
        return errorRequest(error: Error.userWithoutEmailOrUsername, completionHandler: completionHandler)
    }
    
    /**
     Changes the password for the current user and automatically updates the session with a new valid session.
     - parameter newPassword: A new password for the user
     - parameter client: Define the `Client` to be used for all the requests for the `DataStore` that will be returned. Default value: `Kinvey.sharedClient`
     - parameter completionHandler: Completion handler to be called once the response returns from the server
     */
    @discardableResult
    @available(*, deprecated: 3.17.0, message: "Please use User.changePassword(newPassword:options:completionHandler:) instead")
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
    @available(*, deprecated: 3.17.0, message: "Please use User.changePassword(newPassword:options:completionHandler:) instead")
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
    @available(*, deprecated: 3.17.0, message: "Please use User.forgotUsername(email:options:completionHandler:) instead")
    open class func forgotUsername(
        email: String,
        client: Client = sharedClient,
        completionHandler: ((Result<Void, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<Void, Swift.Error>> {
        return forgotUsername(
            email: email,
            options: try! Options(client: client),
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
    @available(*, deprecated: 3.17.0, message: "Please use User.exists(username:options:completionHandler:) instead")
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
    @available(*, deprecated: 3.17.0, message: "Please use User.exists(username:options:completionHandler:) instead")
    open class func exists(
        username: String,
        client: Client = sharedClient,
        completionHandler: ((Result<Bool, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<Bool, Swift.Error>> {
        return exists(
            username: username,
            options: try! Options(client: client),
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
                    let data = data,
                    let json = try? client.jsonParser.parseDictionary(from: data),
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
    @available(*, deprecated: 3.17.0, message: "Please use User.get(userId:options:completionHandler:) instead")
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
    @available(*, deprecated: 3.17.0, message: "Please use User.get(userId:options:completionHandler:) instead")
    open class func get<U: User>(
        userId: String,
        client: Client = sharedClient,
        completionHandler: ((Result<U, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<U, Swift.Error>> {
        return get(
            userId: userId,
            options: try! Options(
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
                    let data = data,
                    let user = try? client.jsonParser.parseUser(U.self, from: data)
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
                    let data = data,
                    let user = try? client.jsonParser.parseUsers(U.self, from: data)
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
                    let data = data,
                    let user = try? self.client.jsonParser.parseUser(type(of: self), from: data)
                {
                    self.refresh(anotherUser: user)
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
    @available(*, deprecated: 3.18.0, message: "Please use Swift.Codable instead")
    public required init?(map: Map) {
        var userId: String?
        var acl: Acl?
        var metadata: UserMetadata?
        
        client = map.context as? Client ?? sharedClient
        userId <- ("userId", map[Entity.EntityCodingKeys.entityId])
        guard let _ = userId else {
            return nil
        }
        
        acl <- ("acl", map[Entity.EntityCodingKeys.acl])
        metadata <- ("metadata", map[Entity.EntityCodingKeys.metadata])
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        client = decoder.userInfo[CodingUserInfoKey(rawValue: "client")!] as? Client ?? sharedClient
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _userId = try container.decode(String.self, forKey: .userId)
        acl = try container.decodeIfPresent(Acl.self, forKey: .acl)
        metadata = try container.decodeIfPresent(UserMetadata.self, forKey: .metadata)
        username = try container.decodeIfPresent(String.self, forKey: .username)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        super.init()
    }
    
    open func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(_userId, forKey: .userId)
        try container.encodeIfPresent(acl, forKey: .acl)
        try container.encodeIfPresent(metadata, forKey: .metadata)
        try container.encodeIfPresent(username, forKey: .username)
        try container.encodeIfPresent(email, forKey: .email)
    }
    
    open func refresh<UserType: User>(anotherUser: UserType) {
        _userId = anotherUser.userId
        acl = anotherUser.acl
        if let authtoken = metadata?.authtoken,
            let metadata = anotherUser.metadata
        {
            metadata.authtoken = authtoken
        }
        metadata = anotherUser.metadata
        if let refreshToken = socialIdentity?.kinvey?["refresh_token"] as? String,
            var kinvey = anotherUser.socialIdentity?.kinvey
        {
            kinvey["refresh_token"] = refreshToken
            anotherUser.socialIdentity?.kinvey = kinvey
        }
        socialIdentity = anotherUser.socialIdentity
        username = anotherUser.username
        email = anotherUser.email
    }
    
    /// This function is where all variable mappings should occur. It is executed by Mapper during the mapping (serialization and deserialization) process.
    @available(*, deprecated: 3.18.0, message: "Please use Swift.Codable instead")
    open func mapping(map: Map) {
        _userId <- ("_userId", map[Entity.EntityCodingKeys.entityId])
        acl <- ("acl", map[Entity.EntityCodingKeys.acl])
        metadata <- ("metadata", map[Entity.EntityCodingKeys.metadata])
        socialIdentity <- ("socialIdentity", map["_socialIdentity"])
        username <- ("username", map["username"])
        email <- ("email", map["email"])
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
    @available(*, deprecated: 3.17.0, message: "Please use User.save(newPassword:options:completionHandler:) instead")
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
                    let data = data,
                    let user = try? client.jsonParser.parseUser(U.self, from: data)
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
    @available(*, deprecated: 3.17.0, message: "Please use User.lookup(_:options:completionHandler:) instead")
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
                    let data = data,
                    let users = try? client.jsonParser.parseUsers(U.self, from: data)
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
                    let json = try? self.client.jsonParser.parseDictionary(from: data),
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
            options: try! Options(
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
        provider: AuthProvider = .kinvey,
        options: Options? = nil,
        completionHandler: ((Result<U, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<U, Swift.Error>> {
        switch provider {
        case .kinvey:
            let client = options?.client ?? sharedClient
            do {
                try client.validate()
            } catch {
                return errorRequest(error: error, completionHandler: completionHandler)
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
    open class func login(
        redirectURI: URL,
        micURL: URL,
        options: Options? = nil
    ) -> Bool {
        switch MIC.parseCode(redirectURI: redirectURI, url: micURL) {
        case .success(let code):
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
        case .failure(let error):
            NotificationCenter.default.post(
                name: MICSafariViewControllerFailureNotificationName,
                object: error ?? buildError(nil, nil, error, options?.client ?? sharedClient)
            )
            return false
        }
    }
    
    /// Presents the MIC View Controller to sign in a user using MIC (Mobile Identity Connect).
    @available(*, deprecated: 3.17.0, message: "Please use User.presentMICViewController(redirectURI:micUserInterface:currentViewController:options:completionHandler:) instead")
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
    @available(*, deprecated: 3.17.0, message: "Please use User.presentMICViewController(redirectURI:micUserInterface:currentViewController:options:completionHandler:) instead")
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
            options: try! Options(
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
        do {
            try client.validate()
        } catch {
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
                        if let url = url {
                            switch MIC.parseCode(redirectURI: redirectURI, url: url) {
                            case .success(let code):
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
                            case .failure(let error):
                                resolver.reject(error ?? buildError(nil, nil, error, client))
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

extension User {
    
    public enum CodingKeys: String, CodingKey {
        
        case userId = "_id"
        case acl = "_acl"
        case metadata = "_kmd"
        case socialIdentity = "_socialIdentity"
        case username
        case email
        
    }
    
}

extension User: JSONDecodable {
    
    public class func decode<T>(from data: Data) throws -> T where T : JSONDecodable {
        return try decodeJSONDecodable(from: data)
    }
    
    public class func decodeArray<T>(from data: Data) throws -> [T] where T : JSONDecodable {
        return try decodeArrayJSONDecodable(from: data)
    }
    
    public class func decode<T>(from dictionary: [String : Any]) throws -> T where T : JSONDecodable {
        return try decodeJSONDecodable(from: dictionary)
    }
    
    public func refresh(from dictionary: [String : Any]) throws {
        var _self = self
        try _self.refreshJSONDecodable(from: dictionary)
    }
    
}

extension User : JSONEncodable {
    
    public func encode() throws -> [String : Any] {
        return try encodeJSONEncodable()
    }
    
}

@available(*, deprecated: 3.18.0, message: "Please use Swift.Codable instead")
extension User: Mappable {
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
public struct UserSocialIdentity {
    
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
    
    enum CodingKeys: String, CodingKey {
        
        case facebook
        case twitter
        case googlePlus = "google"
        case linkedIn
        case kinvey = "kinveyAuth"
        
    }
    
}

@available(*, deprecated: 3.18.0, message: "Please use Swift.Codable instead")
extension UserSocialIdentity : StaticMappable {
    
    public static func objectForMapping(map: Map) -> BaseMappable? {
        return UserSocialIdentity()
    }
    
    public mutating func mapping(map: Map) {
        facebook <- ("facebook", map[AuthSource.facebook])
        twitter <- ("twitter", map[AuthSource.twitter])
        googlePlus <- ("googlePlus", map[AuthSource.googlePlus])
        linkedIn <- ("linkedIn", map[AuthSource.linkedIn])
        kinvey <- ("kinvey", map[AuthSource.kinvey])
    }
    
}

/// Specify an authentication provider
public enum AuthProvider {
    
    /// Kinvey's User collection
    case kinvey
    
    /// Mobile Identity Connect
    case mic
    
}
