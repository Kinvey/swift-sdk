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
                if var kmd = json[PersistableMetadataKey] as? [String : AnyObject] {
                    kmd.removeValueForKey(Metadata.AuthTokenKey)
                    json[PersistableMetadataKey] = kmd
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
                KCSCacheManager.getInstance(appKey!).cache(nil).removeAllEntities()
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
    
    public var networkRequestFactory: RequestFactory!
    public var responseParser: ResponseParser!
    public private(set) var cacheManager: CacheManager!
    public private(set) var syncManager: SyncManager!
    
    public var userType = User.self
    
    public override init() {
        apiHostName = Client.defaultApiHostName
        authHostName = Client.defaultAuthHostName
        
        super.init()
        
        networkRequestFactory = HttpRequestFactory(client: self)
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
        cacheManager = CacheManager(persistenceId: appKey)
        syncManager = SyncManager (persistenceId: appKey)
        
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
