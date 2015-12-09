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
    internal var apiHostName: String?
    
    public var networkTransport: NetworkTransport!
    public var responseParser: ResponseParser!
    
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
        self.apiHostName = apiHostName
        self.appKey = appKey
        self.appSecret = appSecret
        return self
    }
    
    internal func buildURL(endpoint: String) -> NSURL? {
        if let _apiHostName = apiHostName {
            var apiHostName = _apiHostName
            if (apiHostName.characters.last == "/") {
                apiHostName = apiHostName.substringToIndex(apiHostName.endIndex.predecessor())
            }
            var endpoint = endpoint
            if (endpoint.characters.first == "/") {
                endpoint = endpoint.substringFromIndex(endpoint.startIndex.successor())
            }
            return NSURL(string: "\(apiHostName)/\(endpoint)")
        }
        return nil
    }

}
