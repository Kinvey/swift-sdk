//
//  Client.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import KinveyKit

public class Client: NSObject {
    
    internal var _activeUser: User? {
        willSet (newActiveUser) {
            if let activeUser = newActiveUser {
                let userDefaults = NSUserDefaults.standardUserDefaults()
                userDefaults.setObject(activeUser.userId, forKey: appKey!)
                userDefaults.synchronize()
                
                KCSKeychain2.setKinveyToken(
                    activeUser.metadata?.authtoken,
                    user: activeUser.userId,
                    appKey: appKey,
                    accessible: KCSKeychain2.accessibleStringForDataProtectionLevel(KCSDataProtectionLevel.CompleteUntilFirstLogin) //TODO: using default value for now
                )
            } else {
                KCSKeychain2.deleteTokensForUser(
                    _activeUser?.userId,
                    appKey: appKey
                )
            }
        }
    }
    
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
        if let userId = NSUserDefaults.standardUserDefaults().objectForKey(appKey) as? String, let authtoken = KCSKeychain2.kinveyTokenForUserId(userId, appKey: appKey) {
            //FIXME: lmt and act
            _activeUser = User(userId: userId, acl: nil, metadata: Metadata(lmt: "", ect: "", authtoken: authtoken))
        }
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
