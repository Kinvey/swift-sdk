//
//  User.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

public class User: NSObject, Persistable {
    
    public typealias UserHandler = (user: User?, error: NSError?) -> Void
    
    public let userId: String?
    public let acl: Acl?
    public let metadata: Metadata?
    
    public var username: String?
    public var email: String?
    
    internal var authtoken: String?
    
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
        let url = client.buildURL("/user/\(client.appKey!)/")
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
            client._activeUser = client.responseParser.parse(data, response: response, error: error, type: User.self)
            if let completionHandler = completionHandler {
                completionHandler(user: client._activeUser, error: error)
            }
        }
    }
    
    public func loadFrom(json: [String : AnyObject]) {
        
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
    
    public override init() {
        userId = nil
        acl = nil
        metadata = nil
    }
    
    public func logout() {
        
    }
    
    public func save() {
    }

}
