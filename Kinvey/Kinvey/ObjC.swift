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
    
    public class func exists(username username: String, client: Client = Kinvey.sharedClient, completionHandler: ExistsHandlerObjC? = nil) -> Request {
        return exists(username: username, client: client, completionHandler: { (exists, error) -> Void in
            completionHandler?(exists, error as? NSError)
        })
    }
    
    public class func login(username username: String, password: String, client: Client = Kinvey.sharedClient, completionHandler: UserHandlerObjC? = nil) -> Request {
        return login(username: username, password: password, client: client, completionHandler: { (user, error) -> Void in
            completionHandler?(user, error as? NSError)
        })
    }
    
    public class func signup(username username: String? = nil, password: String? = nil, client: Client = Kinvey.sharedClient, completionHandler: UserHandlerObjC? = nil) -> Request {
        return signup(username: username, password: password, client: client, completionHandler: { (user, error) -> Void in
            completionHandler?(user, error as? NSError)
        })
    }
    
    public class func destroy(userId userId: String, hard: Bool = true, client: Client = Kinvey.sharedClient, completionHandler: VoidHandlerObjC? = nil) -> Request {
        return destroy(userId: userId, hard: hard, client: client, completionHandler: { (error) -> Void in
            completionHandler?(error as? NSError)
        })
    }
    
    public func destroy(hard hard: Bool = true, client: Client = Kinvey.sharedClient, completionHandler: VoidHandlerObjC? = nil) -> Request {
        return destroy(hard: hard, client: client, completionHandler: { (error) -> Void in
            completionHandler?(error as? NSError)
        })
    }
    
    public class func get(userId userId: String, client: Client = Kinvey.sharedClient, completionHandler: UserHandlerObjC? = nil) -> Request {
        return get(userId: userId, client: client, completionHandler: { (user, error) -> Void in
            completionHandler?(user, error as? NSError)
        })
    }
    
    public func save(client client: Client = Kinvey.sharedClient, completionHandler: UserHandlerObjC? = nil) -> Request {
        return save(client: client, completionHandler: { (user, error) -> Void in
            completionHandler?(user, error as? NSError)
        })
    }
    
    public class func presentMICViewController(redirectURI redirectURI: NSURL, timeout: NSTimeInterval = 0, client: Client = Kinvey.sharedClient, completionHandler: UserHandlerObjC? = nil) {
        presentMICViewController(redirectURI: redirectURI, timeout: timeout, client: client) { (user, error) -> Void in
            completionHandler?(user, error as? NSError)
        }
    }
    
}

extension ReadOperation {
    
    public typealias CompletionHandlerObjC = (AnyObject?, NSError?) -> Void
    
    @objc public func execute(completionHandler: CompletionHandlerObjC? = nil) -> Request {
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
    
    public typealias CompletionHandlerObjC = (AnyObject?, NSError?) -> Void
    
    @objc public func execute(completionHandler: CompletionHandlerObjC?) -> Request {
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
    
    public typealias UIntCompletionHandlerObjC = (UInt, NSError?) -> Void
    
    @objc public func executeUInt(completionHandler: UIntCompletionHandlerObjC?) -> Request {
        return execute { (obj, error) -> Void in
            completionHandler?(obj as? UInt ?? 0, error)
        }
    }
    
}

extension RemoveOperation {
    
    public typealias UIntCompletionHandlerObjC = (UInt, NSError?) -> Void
    
    @objc public func executeUInt(completionHandler: UIntCompletionHandlerObjC?) -> Request {
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
    
    public convenience init(query: Query, readPolicy: ReadPolicy, persistableClass: AnyClass, cache: Cache, client: Client) {
        self.init(query: query, readPolicy: readPolicy, persistableType: persistableClass as! Persistable.Type, cache: cache, client: client)
    }
    
}

extension GetOperation {
    
    public convenience init(id: String, readPolicy: ReadPolicy, persistableClass: AnyClass, cache: Cache, client: Client) {
        self.init(id: id, readPolicy: readPolicy, persistableType: persistableClass as! Persistable.Type, cache: cache, client: client)
    }
    
}
