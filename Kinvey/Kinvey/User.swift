//
//  User.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import KinveyKit

public class User: NSObject, Credential {
    
    public static let PersistableUsernameKey = "username"
    
    public typealias UserHandler = (user: User?, error: NSError?) -> Void
    public typealias VoidHandler = (error: NSError?) -> Void
    public typealias ExistsHandler = (exists: Bool, error: NSError?) -> Void
    
    private var _userId: String
    public var userId: String {
        get {
            return _userId
        }
    }
    
    private var _acl: Acl?
    public var acl: Acl? {
        get {
            return _acl
        }
    }
    
    private var _metadata: Metadata?
    public var metadata: Metadata? {
        get {
            return _metadata
        }
    }
    
    public var username: String?
    public var email: String?
    
    internal let client: Client
    
    public class func signup(username username: String? = nil, password: String? = nil, client: Client = Kinvey.sharedClient(), completionHandler: UserHandler? = nil) {
        _signup(username: username, password: password, client: client, completionHandler: dispatchAsyncTo(completionHandler))
    }
    
    internal class func _signup(username username: String? = nil, password: String? = nil, client: Client = Kinvey.sharedClient(), completionHandler: UserHandler? = nil) {
        let url = Client.Endpoint.User(client).url()
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "POST"
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var bodyObject: [String : String] = [:]
        if let username = username {
            bodyObject["username"] = username
        }
        if let password = password {
            bodyObject["password"] = password
        }
        request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(bodyObject, options: [])
        client.networkTransport.execute(request, forceBasicAuthentication: true) { (data, response, error) -> Void in
            if client.responseParser.isResponseOk(response) {
                client._activeUser = client.responseParser.parse(data, type: client.userType)
            }
            if let completionHandler = completionHandler {
                completionHandler(user: client._activeUser, error: error)
            }
        }
    }
    
    //TODO: review the method name for delete a user
    
    public class func destroy(userId userId: String, hard: Bool = true, client: Client = Kinvey.sharedClient(), completionHandler: VoidHandler? = nil) {
        _destroy(userId: userId, hard: hard, client: client, completionHandler: dispatchAsyncTo(completionHandler))
    }
    
    public func destroy(hard hard: Bool = true, client: Client = Kinvey.sharedClient(), completionHandler: VoidHandler? = nil) {
        User._destroy(userId: userId, hard: hard, client: client, completionHandler: User.dispatchAsyncTo(completionHandler))
    }
    
    internal class func _destroy(userId userId: String, hard: Bool, client: Client = Kinvey.sharedClient(), completionHandler: VoidHandler? = nil) {
        let url = Client.Endpoint.UserById(client, userId).url()
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "DELETE"
        
        //FIXME: make it configurable 
        request.addValue("2", forHTTPHeaderField: "X-Kinvey-API-Version")
        
        var bodyObject: [String : Bool] = [:]
        if hard {
            bodyObject["hard"] = true
        }
        request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(bodyObject, options: [])
        client.networkTransport.execute(request) { (data, response, error) -> Void in
            if client.responseParser.isResponseOk(response) {
                client._activeUser = nil
            }
            if let completionHandler = completionHandler {
                completionHandler(error: error)
            }
        }
    }
    
    public class func login(username username: String, password: String, client: Client = Kinvey.sharedClient(), completionHandler: UserHandler? = nil) {
        _login(username: username, password: password, client: client, completionHandler: dispatchAsyncTo(completionHandler))
    }
    
    internal class func _login(username username: String, password: String, client: Client = Kinvey.sharedClient(), completionHandler: UserHandler? = nil) {
        let url = Client.Endpoint.UserLogin(client).url()
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "POST"
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let bodyObject = [
            "username" : username,
            "password" : password
        ]
        request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(bodyObject, options: [])
        client.networkTransport.execute(request) { (data, response, error) -> Void in
            if client.responseParser.isResponseOk(response) {
                client._activeUser = client.responseParser.parse(data, type: client.userType)
            }
            if let completionHandler = completionHandler {
                completionHandler(user: client._activeUser, error: error)
            }
        }
    }
    
    public class func resetPassword(username username: String, client: Client = Kinvey.sharedClient()) {
    }
    
    public class func forgotUsername(email email: String, client: Client = Kinvey.sharedClient()) {
    }
    
    public class func exists(username username: String, client: Client = Kinvey.sharedClient(), completionHandler: ExistsHandler? = nil) {
        _exists(username: username, client: client, completionHandler: dispatchAsyncTo(completionHandler))
    }
    
    internal class func _exists(username username: String, client: Client = Kinvey.sharedClient(), completionHandler: ExistsHandler? = nil) {
        let url = Client.Endpoint.UserExistsByUsername(client).url()
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "POST"
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let bodyObject = ["username" : username]
        request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(bodyObject, options: [])
        client.networkTransport.execute(request, forceBasicAuthentication: true) { (data, response, error) -> Void in
            var usernameExists = false
            if client.responseParser.isResponseOk(response) {
                if let json = client.responseParser.parse(data, type: [String : Bool].self), let _usernameExists = json["usernameExists"] {
                    usernameExists = _usernameExists
                }
            }
            if let completionHandler = completionHandler {
                completionHandler(exists: usernameExists, error: error)
            }
        }
    }
    
    public class func get(userId userId: String, client: Client = Kinvey.sharedClient(), completionHandler: UserHandler? = nil) {
        _get(userId: userId, client: client, completionHandler: dispatchAsyncTo(completionHandler))
    }
    
    internal class func _get(userId userId: String, client: Client = Kinvey.sharedClient(), completionHandler: UserHandler? = nil) {
        let url = Client.Endpoint.UserById(client, userId).url()
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "GET"
        
        client.networkTransport.execute(request) { (data, response, error) -> Void in
            var user: User?
            if client.responseParser.isResponseOk(response) {
                user = client.responseParser.parse(data, type: User.self)
            }
            if let completionHandler = completionHandler {
                completionHandler(user: user, error: error)
            }
        }
    }
    
    public init(userId: String, acl: Acl? = nil, metadata: Metadata? = nil, client: Client = Kinvey.sharedClient()) {
        _userId = userId
        _acl = acl
        _metadata = metadata
        self.client = client
    }
    
    public required init(json: [String : AnyObject], client: Client = Kinvey.sharedClient()) {
        _userId = json[Kinvey.PersistableIdKey] as! String
        
        if let username = json["username"] as? String {
            self.username = username
        }
        
        if let email = json["email"] as? String {
            self.email = email
        }
        
        if let acl = json[Kinvey.PersistableAclKey] as? [String : String] {
            _acl = Acl(json: acl)
        } else {
            _acl = nil
        }
        
        if let kmd = json[Kinvey.PersistableMetadataKey] as? [String : String] {
            _metadata = Metadata(json: kmd)
        } else {
            _metadata = nil
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
            client._activeUser = nil
        }
    }
    
    public func save(client client: Client = Kinvey.sharedClient(), completionHandler: UserHandler? = nil) {
        _save(client: client, completionHandler: self.dynamicType.dispatchAsyncTo(completionHandler))
    }
    
    internal func _save(client client: Client, completionHandler: UserHandler? = nil) {
        let url = Client.Endpoint.UserById(client, userId).url()
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "PUT"
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let bodyObject = toJson()
        request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(bodyObject, options: [])
        client.networkTransport.execute(request) { (data, response, error) -> Void in
            if client.responseParser.isResponseOk(response) {
                client._activeUser = client.responseParser.parse(data, type: client.userType)
            }
            if let completionHandler = completionHandler {
                completionHandler(user: client._activeUser, error: error)
            }
        }
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
    
    public class func presentMICViewController(redirectURI redirectURI: NSURL, timeout: NSTimeInterval = 0, client: Client = Kinvey.sharedClient(), completionHandler: UserHandler? = nil) {
        let micVC = KCSMICLoginViewController(redirectURI: redirectURI.absoluteString, timeout: timeout) { (kcsUser, error, actionResult) -> Void in
            var user: User? = nil
            if let kcsUser = kcsUser {
                user = User(userId: kcsUser.userId, metadata: Metadata(authtoken: kcsUser.authString), client: client)
                user?.username = kcsUser.username
                user?.email = kcsUser.email
                client._activeUser = user
            }
            if let completionHandler = completionHandler {
                completionHandler(user: user, error: error)
            }
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
