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
    public func save(client client: Client = Kinvey.sharedClient, completionHandler: UserHandlerObjC) -> Request {
        return save(newPassword: nil, client: client, completionHandler: { (user, error) -> Void in
            completionHandler(user, error as? NSError)
        })
    }
    
}

@objc(__KNVError)
internal class KinveyError: NSObject {
    
    internal static let ObjectIdMissing = Error.ObjectIdMissing.error
    internal static let InvalidResponse = Error.InvalidResponse.error
    internal static let NoActiveUser = Error.NoActiveUser.error
    internal static let RequestCancelled = Error.RequestCancelled.error
    internal static let InvalidDataStoreType = Error.InvalidDataStoreType.error
    
    private override init() {
    }
    
    internal static func buildUnknownError(error: String) -> NSError {
        return Error.buildUnknownError(error).error
    }
    
    internal static func buildUnknownJsonError(json: [String : AnyObject]) -> NSError {
        return Error.buildUnknownJsonError(json).error
    }
    
}
