//
//  User.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import KinveyKit
import PromiseKit

public class User: NSObject, Credential {
    
    public static let PersistableUsernameKey = "username"
    
    public typealias UserHandler = (user: User?, error: ErrorType?) -> Void
    public typealias VoidHandler = (error: ErrorType?) -> Void
    public typealias ExistsHandler = (exists: Bool, error: ErrorType?) -> Void
    
    public private(set) var userId: String
    public private(set) var acl: Acl?
    public private(set) var metadata: Metadata?
    
    public var username: String?
    public var email: String?
    
    internal let client: Client
    
    public class func signup(username username: String? = nil, password: String? = nil, client: Client = Kinvey.sharedClient, completionHandler: UserHandler? = nil) -> Request {
        return _signup(username: username, password: password, client: client, completionHandler: dispatchAsyncTo(completionHandler))
    }
    
    internal class func _signup(username username: String? = nil, password: String? = nil, client: Client = Kinvey.sharedClient, completionHandler: UserHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildUserSignUp(username: username, password: password)
        request.execute() { (data, response, error) in
            if let response = response where response.isResponseOK {
                client.activeUser = client.responseParser.parse(data, type: client.userType)
            }
            completionHandler?(user: client.activeUser, error: error)
        }
        return request
    }
    
    //TODO: review the method name for delete a user
    
    public class func destroy(userId userId: String, hard: Bool = true, client: Client = Kinvey.sharedClient, completionHandler: VoidHandler? = nil) -> Request {
        return _destroy(userId: userId, hard: hard, client: client, completionHandler: dispatchAsyncTo(completionHandler))
    }
    
    public func destroy(hard hard: Bool = true, client: Client = Kinvey.sharedClient, completionHandler: VoidHandler? = nil) -> Request {
        return User._destroy(userId: userId, hard: hard, client: client, completionHandler: User.dispatchAsyncTo(completionHandler))
    }
    
    internal class func _destroy(userId userId: String, hard: Bool, client: Client = Kinvey.sharedClient, completionHandler: VoidHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildUserDelete(userId: userId, hard: hard)
        request.execute() { (data, response, error) in
            if let response = response where response.isResponseOK {
                client.activeUser = nil
            }
            completionHandler?(error: error)
        }
        return request
    }
    
    public class func login(username username: String, password: String, client: Client = Kinvey.sharedClient, completionHandler: UserHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildUserLogin(username: username, password: password)
        Promise<User> { fulfill, reject in
            request.execute() { (data, response, error) in
                if let response = response where response.isResponseOK {
                    let user = client.responseParser.parse(data, type: client.userType)
                    if let user = user {
                        client.activeUser = user
                        fulfill(user)
                    } else {
                        reject(Error.InvalidResponse)
                    }
                } else if let error = error {
                    reject(error)
                } else {
                    abort()
                }
            }
        }.then { user in
            completionHandler?(user: client.activeUser, error: nil)
        }.error { error in
            completionHandler?(user: nil, error: error)
        }
        return request
    }
    
    public class func resetPassword(username username: String, client: Client = Kinvey.sharedClient) {
    }
    
    public class func forgotUsername(email email: String, client: Client = Kinvey.sharedClient) {
    }
    
    public class func exists(username username: String, client: Client = Kinvey.sharedClient, completionHandler: ExistsHandler? = nil) -> Request {
        return _exists(username: username, client: client, completionHandler: dispatchAsyncTo(completionHandler))
    }
    
    internal class func _exists(username username: String, client: Client = Kinvey.sharedClient, completionHandler: ExistsHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildUserExists(username: username)
        request.execute() { (data, response, error) in
            var usernameExists = false
            if let response = response where response.isResponseOK {
                if let json = client.responseParser.parse(data, type: [String : Bool].self), let _usernameExists = json["usernameExists"] {
                    usernameExists = _usernameExists
                }
            }
            completionHandler?(exists: usernameExists, error: error)
        }
        return request
    }
    
    public class func get(userId userId: String, client: Client = Kinvey.sharedClient, completionHandler: UserHandler? = nil) -> Request {
        return _get(userId: userId, client: client, completionHandler: dispatchAsyncTo(completionHandler))
    }
    
    internal class func _get(userId userId: String, client: Client = Kinvey.sharedClient, completionHandler: UserHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildUserGet(userId: userId)
        request.execute() { (data, response, error) in
            var user: User?
            if let response = response where response.isResponseOK {
                user = client.responseParser.parse(data, type: User.self)
            }
            completionHandler?(user: user, error: error)
        }
        return request
    }
    
    public init(userId: String, acl: Acl? = nil, metadata: Metadata? = nil, client: Client = Kinvey.sharedClient) {
        self.userId = userId
        self.acl = acl
        self.metadata = metadata
        self.client = client
    }
    
    public required init(json: [String : AnyObject], client: Client = Kinvey.sharedClient) {
        userId = json[PersistableIdKey] as! String
        
        if let username = json["username"] as? String {
            self.username = username
        }
        
        if let email = json["email"] as? String {
            self.email = email
        }
        
        if let acl = json[PersistableAclKey] as? [String : String] {
            self.acl = Acl(json: acl)
        } else {
            self.acl = nil
        }
        
        if let kmd = json[PersistableMetadataKey] as? [String : AnyObject] {
            metadata = Metadata(json: kmd)
        } else {
            metadata = nil
        }
        
        self.client = client
    }
    
    public func toJson() -> [String : AnyObject] {
        var json: [String : AnyObject] = [:]
        
        json[Kinvey.PersistableIdKey] = userId
        
        if let acl = acl {
            json[Kinvey.PersistableAclKey] = acl.toJson()
        }
        
        if let metadata = metadata {
            json[Kinvey.PersistableMetadataKey] = metadata.toJson()
        }
        
        return json
    }
    
    public func logout() {
        if self == client.activeUser {
            client.activeUser = nil
        }
    }
    
    public func save(client client: Client = Kinvey.sharedClient, completionHandler: UserHandler? = nil) -> Request {
        return _save(client: client, completionHandler: self.dynamicType.dispatchAsyncTo(completionHandler))
    }
    
    internal func _save(client client: Client, completionHandler: UserHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildUserSave(user: self)
        request.execute() { (data, response, error) in
            if let response = response where response.isResponseOK {
                client.activeUser = client.responseParser.parse(data, type: client.userType)
            }
            completionHandler?(user: client.activeUser, error: error)
        }
        return request
    }
    
    public var authorizationHeader: String? {
        get {
            var authorization: String? = nil
            if let authtoken = metadata?.authtoken {
                authorization = "Kinvey \(authtoken)"
            }
            return authorization
        }
    }
    
    //MARK: MIC
    
    public class func presentMICViewController(redirectURI redirectURI: NSURL, timeout: NSTimeInterval = 0, client: Client = Kinvey.sharedClient, completionHandler: UserHandler? = nil) {
        let micVC = KCSMICLoginViewController(redirectURI: redirectURI.absoluteString, timeout: timeout) { (kcsUser, error, actionResult) -> Void in
            var user: User? = nil
            if let kcsUser = kcsUser {
                user = User(userId: kcsUser.userId, metadata: Metadata(authtoken: kcsUser.authString), client: client)
                user?.username = kcsUser.username
                user?.email = kcsUser.email
                client.activeUser = user
            }
            completionHandler?(user: user, error: error)
        }
        micVC.client = client
        let navigationVC = UINavigationController(rootViewController: micVC)
        
        var viewController = UIApplication.sharedApplication().keyWindow?.rootViewController
        if let presentedViewController =  viewController?.presentedViewController {
            viewController = presentedViewController;
        }
        viewController?.presentViewController(navigationVC, animated: true, completion: nil)
    }
    
    //MARK: - Dispatch Async To
    
    private class func dispatchAsyncTo(queue queue: dispatch_queue_t = dispatch_get_main_queue(), _ completionHandler: UserHandler? = nil) -> UserHandler? {
        var completionHandler = completionHandler
        if let originalCompletionHandler = completionHandler {
            completionHandler = { user, error in
                dispatch_async(queue, { () -> Void in
                    originalCompletionHandler(user: user, error: error)
                })
            }
        }
        return completionHandler
    }
    
    private class func dispatchAsyncTo(queue queue: dispatch_queue_t = dispatch_get_main_queue(), _ completionHandler: VoidHandler? = nil) -> VoidHandler? {
        var completionHandler = completionHandler
        if let originalCompletionHandler = completionHandler {
            completionHandler = { error in
                dispatch_async(queue, { () -> Void in
                    originalCompletionHandler(error: error)
                })
            }
        }
        return completionHandler
    }
    
    private class func dispatchAsyncTo(queue queue: dispatch_queue_t = dispatch_get_main_queue(), _ completionHandler: ExistsHandler? = nil) -> ExistsHandler? {
        var completionHandler = completionHandler
        if let originalCompletionHandler = completionHandler {
            completionHandler = { exists, error in
                dispatch_async(queue, { () -> Void in
                    originalCompletionHandler(exists: exists, error: error)
                })
            }
        }
        return completionHandler
    }

}
