//
//  Client.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import KinveyKit

public class Client: NSObject, Credential {
    
    public internal(set) var activeUser: User? {
        willSet (newActiveUser) {
            if let activeUser = newActiveUser {
                let userDefaults = NSUserDefaults.standardUserDefaults()
                var json = activeUser.toJson()
                if var kmd = json["_kmd"] as? [String : AnyObject] {
                    kmd.removeValueForKey("authtoken")
                    json["_kmd"] = kmd
                }
                userDefaults.setObject(json, forKey: appKey!)
                userDefaults.synchronize()
                
                KCSKeychain2.setKinveyToken(
                    activeUser.metadata?.authtoken,
                    user: activeUser.userId,
                    appKey: appKey,
                    accessible: KCSKeychain2.accessibleStringForDataProtectionLevel(KCSDataProtectionLevel.CompleteUntilFirstLogin) //TODO: using default value for now
                )
            } else {
                KCSKeychain2.deleteTokensForUser(
                    activeUser?.userId,
                    appKey: appKey
                )
                KCSRealmEntityPersistence.offlineManager().removeAllEntities()
            }
        }
    }
    
    internal let urlSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
    
    public private(set) var appKey: String?
    public private(set) var appSecret: String?
    public private(set) var apiHostName: NSURL
    public private(set) var authHostName: NSURL
    
    public var cachePolicy: NSURLRequestCachePolicy = .UseProtocolCachePolicy
    public var timeoutInterval: NSTimeInterval = 60
    public var clientAppVersion: String?
    public var customRequestProperties: [String : String] = [:]
    
    public static let defaultApiHostName = NSURL(string: "https://baas.kinvey.com/")!
    public static let defaultAuthHostName = NSURL(string: "https://auth.kinvey.com/")!
    
    public var networkTransport: NetworkTransport!
    public var responseParser: ResponseParser!
    
    public var userType = User.self
    
    public override init() {
        apiHostName = Client.defaultApiHostName
        authHostName = Client.defaultAuthHostName
        
        super.init()
        
        networkTransport = HttpNetworkTransport(client: self)
        responseParser = JsonResponseParser(client: self)
    }
    
    public override class func initialize () {
        KCSRealmEntityPersistence.initialize()
    }
    
    public convenience init(appKey: String, appSecret: String, apiHostName: NSURL = Client.defaultApiHostName, authHostName: NSURL = Client.defaultAuthHostName) {
        self.init()
        initialize(appKey: appKey, appSecret: appSecret, apiHostName: apiHostName, authHostName: authHostName)
    }
    
    public func initialize(appKey appKey: String, appSecret: String, apiHostName: NSURL = Client.defaultApiHostName, authHostName: NSURL = Client.defaultAuthHostName) -> Client {
        var apiHostName = apiHostName
        if let apiHostNameString = apiHostName.absoluteString as String? where apiHostNameString.characters.last == "/" {
            apiHostName = NSURL(string: apiHostNameString.substringToIndex(apiHostNameString.characters.endIndex.predecessor()))!
        }
        var authHostName = authHostName
        if let authHostNameString = authHostName.absoluteString as String? where authHostNameString.characters.last == "/" {
            authHostName = NSURL(string: authHostNameString.substringToIndex(authHostNameString.characters.endIndex.predecessor()))!
        }
        self.apiHostName = apiHostName
        self.authHostName = authHostName
        self.appKey = appKey
        self.appSecret = appSecret
        if let json = NSUserDefaults.standardUserDefaults().objectForKey(appKey) as? [String : AnyObject] {
            let user = User(json: json, client: self)
            if let metadata = user.metadata, let authtoken = KCSKeychain2.kinveyTokenForUserId(user.userId, appKey: appKey) {
                metadata.authtoken = authtoken
                activeUser = user
            }
        }
        return self
    }
    
    public func getNetworkStore<T: Persistable>(type: T.Type) -> Store<T> {
        return NetworkStore<T>(client: self)
    }
    
    public func getCachedStore<T: Persistable>(type: T.Type, expiration: CachedStoreExpiration) -> Store<T> {
        return CachedStore<T>(expiration: expiration, client: self)
    }
    
    public func getCachedStore<T: Persistable>(type: T.Type, expiration: Expiration) -> Store<T> {
        return CachedStore<T>(expiration: expiration, client: self)
    }
    
    public func getSyncedStore<T: Persistable>(type: T.Type) -> Store<T> {
        return SyncedStore<T>(client: self)
    }
    
    public var authorizationHeader: String? {
        get {
            var authorization: String? = nil
            if let appKey = appKey, let appSecret = appSecret {
                let appKeySecret = "\(appKey):\(appSecret)".dataUsingEncoding(NSUTF8StringEncoding)?.base64EncodedStringWithOptions([])
                if let appKeySecret = appKeySecret {
                    authorization = "Basic \(appKeySecret)"
                }
            }
            return authorization
        }
    }

}
