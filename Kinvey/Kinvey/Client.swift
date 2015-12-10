//
//  Client.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

public class Client: NSObject {
    
    internal var _activeUser: User?
    
    public var activeUser: User? {
        get {
            return _activeUser
        }
    }
    
    internal let urlSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
    
    internal var appKey: String?
    internal var appSecret: String?
    internal var apiHostName: NSURL?
    
    public var networkTransport: NetworkTransport!
    public var responseParser: ResponseParser!
    
    public var userType = User.self
    
    public override init() {
        super.init()
        networkTransport = HttpNetworkTransport(client: self)
        responseParser = JsonResponseParser(client: self)
    }
    
    public convenience init(appKey: String, appSecret: String) {
        self.init()
        initialize(appKey: appKey, appSecret: appSecret)
    }
    
    public convenience init(apiHostName: String, appKey: String, appSecret: String) {
        self.init()
        initialize(apiHostName: apiHostName, appKey: appKey, appSecret: appSecret)
    }
    
    public func initialize(appKey appKey: String, appSecret: String) -> Client {
        return initialize(apiHostName: "https://baas.kinvey.com/", appKey: appKey, appSecret: appSecret)
    }
    
    public func initialize(apiHostName apiHostName: String, appKey: String, appSecret: String) -> Client {
        self.apiHostName = NSURL(string: apiHostName)
        self.appKey = appKey
        self.appSecret = appSecret
        return self
    }
    
    enum Endpoint {
        
        case User(Client)
        case UserById(Client, String)
        
        func url() -> NSURL? {
            switch self {
            case .User(let client):
                return client.apiHostName?.URLByAppendingPathComponent("/user/\(client.appKey!)")
            case .UserById(let client, let userId):
                return client.apiHostName?.URLByAppendingPathComponent("/user/\(client.appKey!)/\(userId)")
            }
        }
        
    }

}
