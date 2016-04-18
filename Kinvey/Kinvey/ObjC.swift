//
//  ObjC.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-04.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

extension User {
    
    public typealias ExistsHandlerObjC = (Bool, NSError?) -> Void
    public typealias UserHandlerObjC = (User?, NSError?) -> Void
    public typealias VoidHandlerObjC = (NSError?) -> Void
    
    /// Checks if a `username` already exists or not.
    public class func exists(username username: String, client: Client = Kinvey.sharedClient, completionHandler: ExistsHandlerObjC? = nil) -> Request {
        return exists(username: username, client: client, completionHandler: { (exists, error) -> Void in
            completionHandler?(exists, error as? NSError)
        })
    }
    
    /// Sign in a user and set as a current active user.
    public class func login(username username: String, password: String, client: Client = Kinvey.sharedClient, completionHandler: UserHandlerObjC? = nil) -> Request {
        return login(username: username, password: password, client: client, completionHandler: { (user, error) -> Void in
            completionHandler?(user, error as? NSError)
        })
    }
    
    /// Creates a new `User` taking (optionally) a username and password. If no `username` or `password` was provided, random values will be generated automatically.
    public class func signup(username username: String? = nil, password: String? = nil, client: Client = Kinvey.sharedClient, completionHandler: UserHandlerObjC? = nil) -> Request {
        return signup(username: username, password: password, client: client, completionHandler: { (user, error) -> Void in
            completionHandler?(user, error as? NSError)
        })
    }
    
    /// Deletes a `User` by the `userId` property.
    public class func destroy(userId userId: String, hard: Bool = true, client: Client = Kinvey.sharedClient, completionHandler: VoidHandlerObjC? = nil) -> Request {
        return destroy(userId: userId, hard: hard, client: client, completionHandler: { (error) -> Void in
            completionHandler?(error as? NSError)
        })
    }
    
    /// Deletes the `User`.
    public func destroy(hard hard: Bool = true, client: Client = Kinvey.sharedClient, completionHandler: VoidHandlerObjC? = nil) -> Request {
        return destroy(hard: hard, client: client, completionHandler: { (error) -> Void in
            completionHandler?(error as? NSError)
        })
    }
    
    /// Gets a `User` instance using the `userId` property.
    public class func get(userId userId: String, client: Client = Kinvey.sharedClient, completionHandler: UserHandlerObjC? = nil) -> Request {
        return get(userId: userId, client: client, completionHandler: { (user, error) -> Void in
            completionHandler?(user, error as? NSError)
        })
    }
    
    /// Creates or updates a `User`.
    public func save(client client: Client = Kinvey.sharedClient, completionHandler: UserHandlerObjC? = nil) -> Request {
        return save(client: client, completionHandler: { (user, error) -> Void in
            completionHandler?(user, error as? NSError)
        })
    }
    
    /// Presents the MIC View Controller to sign in a user using MIC (Mobile Identity Connect).
    public class func presentMICViewController(redirectURI redirectURI: NSURL, timeout: NSTimeInterval = 0, client: Client = Kinvey.sharedClient, completionHandler: UserHandlerObjC? = nil) {
        presentMICViewController(redirectURI: redirectURI, timeout: timeout, forceUIWebView: false, client: client) { (user: User?, error: ErrorType?) -> Void in
            completionHandler?(user, error as? NSError)
        }
    }
    
    /// Presents the MIC View Controller to sign in a user using MIC (Mobile Identity Connect).
    public class func presentMICViewController(redirectURI redirectURI: NSURL, timeout: NSTimeInterval = 0, forceUIWebView: Bool = false, client: Client = Kinvey.sharedClient, completionHandler: UserHandlerObjC? = nil) {
        presentMICViewController(redirectURI: redirectURI, timeout: timeout, forceUIWebView: forceUIWebView, client: client) { (user: User?, error: ErrorType?) -> Void in
            completionHandler?(user, error as? NSError)
        }
    }
    
}

extension ReadOperation {
    
    internal typealias CompletionHandlerObjC = (AnyObject?, NSError?) -> Void
    
    @objc
    internal func execute(completionHandler: CompletionHandlerObjC? = nil) -> Request {
        switch readPolicy {
        case .ForceLocal:
            return executeLocal({ (obj, error) -> Void in
                completionHandler?(obj, error as? NSError)
            })
        case .ForceNetwork:
            return executeNetwork({ (obj, error) -> Void in
                completionHandler?(obj, error as? NSError)
            })
        case .Both:
            let request = MultiRequest()
            executeLocal({ (obj, error) -> Void in
                completionHandler?(obj, error as? NSError)
                request.addRequest(self.executeNetwork({ (obj, error) -> Void in
                    completionHandler?(obj, error as? NSError)
                }))
            })
            return request
        }
    }
    
}

extension WriteOperation {
    
    internal typealias CompletionHandlerObjC = (AnyObject?, NSError?) -> Void
    
    @objc
    internal func execute(completionHandler: CompletionHandlerObjC?) -> Request {
        switch writePolicy {
        case .ForceLocal:
            return executeLocal({ (obj, error) -> Void in
                completionHandler?(obj, error as? NSError)
            })
        case .LocalThenNetwork:
            executeLocal({ (obj, error) -> Void in
                completionHandler?(obj, error as? NSError)
            })
            fallthrough
        case .ForceNetwork:
            return executeNetwork({ (obj, error) -> Void in
                completionHandler?(obj, error as? NSError)
            })
        }
    }
    
}

extension SyncOperation {
    
    internal typealias CompletionHandlerObjC = (AnyObject?, NSError?) -> Void
    internal typealias UIntCompletionHandlerObjC = (UInt, NSError?) -> Void
    
    @objc
    internal func execute(completionHandler: CompletionHandlerObjC?) -> Request {
        return execute(timeout: nil) { (objs, error) -> Void in
            completionHandler?(objs, error as? NSError)
        }
    }
    
    @objc
    internal func executeWithTimeout(timeout: NSTimeInterval, completionHandler: CompletionHandlerObjC?) -> Request {
        return execute(timeout: timeout) { (objs, error) -> Void in
            completionHandler?(objs, error as? NSError)
        }
    }
    
    @objc
    internal func executeUInt(completionHandler: UIntCompletionHandlerObjC?) -> Request {
        return execute { (obj, error) -> Void in
            completionHandler?(obj as? UInt ?? 0, error)
        }
    }
    
}

extension RemoveOperation {
    
    internal typealias UIntCompletionHandlerObjC = (UInt, NSError?) -> Void
    
    @objc
    internal func executeUInt(completionHandler: UIntCompletionHandlerObjC?) -> Request {
        switch writePolicy {
        case .ForceLocal:
            return executeLocal({ (obj, error) -> Void in
                completionHandler?(obj as! UInt, error as? NSError)
            })
        case .LocalThenNetwork:
            executeLocal({ (obj, error) -> Void in
                completionHandler?(obj as! UInt, error as? NSError)
            })
            fallthrough
        case .ForceNetwork:
            return executeNetwork({ (obj, error) -> Void in
                completionHandler?(obj as! UInt, error as? NSError)
            })
        }
    }
    
}

extension FindOperation {
    
    internal convenience init(query: Query, deltaSet: Bool, readPolicy: ReadPolicy, persistableClass: AnyClass, cache: Cache, client: Client) {
        self.init(query: query, deltaSet: deltaSet, readPolicy: readPolicy, persistableType: persistableClass as! Persistable.Type, cache: cache, client: client)
    }
    
}

@objc(__KNVError)
internal class KinveyError: NSObject {
    
    internal static let ObjectIdMissing = Error.ObjectIdMissing.error
    internal static let InvalidResponse = Error.InvalidResponse.error
    internal static let NoActiveUser = Error.NoActiveUser.error
    internal static let RequestCanceled = Error.RequestCanceled.error
    internal static let InvalidDataStoreType = Error.InvalidDataStoreType.error
    
    private override init() {
    }
    
}
