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
    
}
