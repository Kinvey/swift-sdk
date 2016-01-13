//
//  Client.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import KinveyKit
import MongoDBPredicateAdaptor

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
    
    public func getNetworkStore<T: Persistable>(type: T) -> BaseStore<T> {
        return NetworkStore<T>(client: self)
    }
    
    public func getCachedStore<T: Persistable>(type: T, expiration: CachedStoreExpiration) -> BaseStore<T> {
        
        return CachedStore<T>(expiration: expiration, client: self)
    }
    
    public func getSyncedStore<T: Persistable>(type: T) -> BaseStore<T> {
        return SyncedStore<T>(client: self)
    }
    
    public enum Endpoint {
        
        case User(Client)
        case UserById(Client, String)
        case UserExistsByUsername(Client)
        case UserLogin(Client)
        case OAuthAuth(Client, NSURL)
        case OAuthToken(Client)
        case AppData(Client, String)
        case AppDataById(Client, String, String)
        case AppDataByQuery(Client, String, Query)
        
        func url() -> NSURL? {
            switch self {
            case .User(let client):
                return client.apiHostName.URLByAppendingPathComponent("/user/\(client.appKey!)")
            case .UserById(let client, let userId):
                return client.apiHostName.URLByAppendingPathComponent("/user/\(client.appKey!)/\(userId)")
            case .UserExistsByUsername(let client):
                return client.apiHostName.URLByAppendingPathComponent("/rpc/\(client.appKey!)/check-username-exists")
            case .UserLogin(let client):
                return client.apiHostName.URLByAppendingPathComponent("/user/\(client.appKey!)/login")
            case .OAuthAuth(let client, let redirectURI):
                let characterSet = NSCharacterSet.URLQueryAllowedCharacterSet().mutableCopy() as! NSMutableCharacterSet
                characterSet.removeCharactersInString(":#[]@!$&'()*+,;=")
                let redirectURIEncoded = redirectURI.absoluteString.stringByAddingPercentEncodingWithAllowedCharacters(characterSet) ?? redirectURI.absoluteString
                let query = "?client_id=\(client.appKey!)&redirect_uri=\(redirectURIEncoded)&response_type=code"
                return NSURL(string: client.authHostName.URLByAppendingPathComponent("/oauth/auth").absoluteString + query)
            case .OAuthToken(let client):
                return client.authHostName.URLByAppendingPathComponent("/oauth/token")
            case AppData(let client, let collectionName):
                return client.apiHostName.URLByAppendingPathComponent("/appdata/\(client.appKey!)/\(collectionName)")
            case AppDataById(let client, let collectionName, let id):
                return client.apiHostName.URLByAppendingPathComponent("/appdata/\(client.appKey!)/\(collectionName)/\(id)")
            case AppDataByQuery(let client, let collectionName, let query):
                let queryObj = try! MongoDBPredicateAdaptor.queryDictFromPredicate(query.predicate)
                let data = try! NSJSONSerialization.dataWithJSONObject(queryObj, options: [])
                var queryStr = NSString(data: data, encoding: NSUTF8StringEncoding)
                queryStr = queryStr!.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())
                let url = client.apiHostName.URLByAppendingPathComponent("/appdata/\(client.appKey!)/\(collectionName)/").absoluteString
                let urlQuery = "?query=\(queryStr!)"
                return NSURL(string: url + urlQuery)
            }
        }
        
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
