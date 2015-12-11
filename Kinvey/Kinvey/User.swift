//
//  User.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

public class User: NSObject, JsonObject {
    
    public typealias UserHandler = (user: User?, error: NSError?) -> Void
    public typealias VoidHandler = (error: NSError?) -> Void
    
    public let userId: String
    public let acl: Acl?
    public let metadata: Metadata?
    
    public var username: String?
    public var email: String?
    
    internal var client: Client?
    
    public class func signup(completionHandler: UserHandler?) {
        signup(Kinvey.sharedClient(), completionHandler: completionHandler)
    }
    
    public class func signup(client: Client, completionHandler: UserHandler?) {
        signup(username: nil, password: nil, client: client, completionHandler: completionHandler)
    }
    
    public class func signup(username username: String, password: String, completionHandler: UserHandler?) {
        signup(username: username, password: password, client: Kinvey.sharedClient(), completionHandler: completionHandler)
    }
    
    public class func signup(username username: String, password: String, client: Client, completionHandler: UserHandler?) {
        signup(username: username as String?, password: password as String?, client: client, completionHandler: completionHandler)
    }
    
    private class func signup(username username: String?, password: String?, client: Client, completionHandler: UserHandler?) {
        _signup(username: username, password: password, client: client, completionHandler: dispatchAsyncTo(completionHandler))
    }
    
    internal class func _signup(username username: String?, password: String?, client: Client, completionHandler: UserHandler?) {
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
        client.networkTransport.execute(request) { (data, response, error) -> Void in
            if client.responseParser.isResponseOk(response) {
                client._activeUser = client.responseParser.parse(data, type: client.userType)
            }
            if let completionHandler = completionHandler {
                completionHandler(user: client._activeUser, error: error)
            }
        }
    }
    
    //TODO: review the method name for delete a user
    public func destroy(completionHandler: VoidHandler?) {
        destroy(hard: true, client: Kinvey.sharedClient(), completionHandler: completionHandler)
    }
    
    public func destroy(client client: Client, completionHandler: VoidHandler?) {
        destroy(hard: true, client: client, completionHandler: completionHandler)
    }
    
    public func destroy(hard hard: Bool, completionHandler: VoidHandler?) {
        destroy(hard: hard, client: Kinvey.sharedClient(), completionHandler: completionHandler)
    }
    
    public func destroy(hard hard: Bool, client: Client, completionHandler: VoidHandler?) {
        self.dynamicType.destroy(userId: userId, hard: hard, client: client, completionHandler: completionHandler)
    }
    
    public class func destroy(userId userId: String, completionHandler: VoidHandler?) {
        destroy(userId: userId, hard: true, client: Kinvey.sharedClient(), completionHandler: completionHandler)
    }
    
    public class func destroy(userId userId: String, hard: Bool, completionHandler: VoidHandler?) {
        destroy(userId: userId, hard: hard, client: Kinvey.sharedClient(), completionHandler: completionHandler)
    }
    
    public class func destroy(userId userId: String, client: Client, completionHandler: VoidHandler?) {
        destroy(userId: userId, hard: true, client: client, completionHandler: completionHandler)
    }
    
    public class func destroy(userId userId: String, hard: Bool, client: Client, completionHandler: VoidHandler?) {
        _destroy(userId: userId, hard: hard, client: client, completionHandler: dispatchAsyncTo(completionHandler))
    }
    
    internal class func _destroy(userId userId: String, hard: Bool, client: Client, completionHandler: VoidHandler?) {
        let url = Client.Endpoint.UserById(client, userId).url()
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "DELETE"
        
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
    
    public class func login(username username: String, password: String) {
        login(username: username, password: password, client: Kinvey.sharedClient())
    }
    
    public class func login(username username: String, password: String, client: Client) {
    }
    
    public class func resetPassword(username username: String) {
        resetPassword(username: username, client: Kinvey.sharedClient())
    }
    
    public class func resetPassword(username username: String, client: Client) {
    }
    
    public class func forgotUsername(email email: String) {
        forgotUsername(email: email, client: Kinvey.sharedClient())
    }
    
    public class func forgotUsername(email email: String, client: Client) {
    }
    
    public class func exists(username username: String) {
        exists(username: username, client: Kinvey.sharedClient())
    }
    
    public class func exists(username username: String, client: Client) {
    }
    
    public class func get(userId userId: String, completionHandler: UserHandler?) {
        get(userId: userId, client: Kinvey.sharedClient(), completionHandler: completionHandler)
    }
    
    public class func get(userId userId: String, client: Client, completionHandler: UserHandler?) {
        _get(userId: userId, client: client, completionHandler: dispatchAsyncTo(completionHandler))
    }
    
    internal class func _get(userId userId: String, client: Client, completionHandler: UserHandler?) {
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
    
    public init(userId: String, acl: Acl?, metadata: Metadata?) {
        self.userId = userId
        self.acl = acl
        self.metadata = metadata
    }
    
    public required init(json: [String : AnyObject]) {
        userId = json[Kinvey.PersistableIdKey] as! String
        
        if let acl = json[Kinvey.PersistableAclKey] as? [String : String] {
            self.acl = Acl(json: acl)
        } else {
            acl = nil
        }
        
        if let kmd = json[Kinvey.PersistableMetadataKey] as? [String : String] {
            metadata = Metadata(json: kmd)
        } else {
            metadata = nil
        }
        
        super.init()
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
        
    }
    
    public func save(completionHandler: UserHandler?) {
        save(client: Kinvey.sharedClient(), completionHandler: completionHandler)
    }
    
    public func save(client client: Client, completionHandler: UserHandler?) {
        _save(client: client, completionHandler: self.dynamicType.dispatchAsyncTo(completionHandler))
    }
    
    internal func _save(client client: Client, completionHandler: UserHandler?) {
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
    
    //MARK: - Dispatch Async To
    
    private class func dispatchAsyncTo(completionHandler: UserHandler?) -> UserHandler? {
        return dispatchAsyncTo(queue: dispatch_get_main_queue(), completionHandler: completionHandler)
    }
    
    private class func dispatchAsyncTo(queue queue: dispatch_queue_t, completionHandler: UserHandler?) -> UserHandler? {
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
    
    private class func dispatchAsyncTo(completionHandler: VoidHandler?) -> VoidHandler? {
        return dispatchAsyncTo(queue: dispatch_get_main_queue(), completionHandler: completionHandler)
    }
    
    private class func dispatchAsyncTo(queue queue: dispatch_queue_t, completionHandler: VoidHandler?) -> VoidHandler? {
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

}
