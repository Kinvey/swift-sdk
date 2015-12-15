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
    
    internal var _appKey: String?
    internal var _appSecret: String?
    internal var _apiHostName: NSURL
    internal var _authHostName: NSURL
    
    public var appKey: String? {
        get {
            return _appKey
        }
    }
    
    public var appSecret: String? {
        get {
            return _appSecret
        }
    }
    
    public var apiHostName: NSURL {
        get {
            return _apiHostName
        }
    }
    
    public var authHostName: NSURL {
        get {
            return _authHostName
        }
    }
    
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
        _apiHostName = Client.defaultApiHostName
        _authHostName = Client.defaultAuthHostName
        
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
        _apiHostName = apiHostName
        _authHostName = authHostName
        _appKey = appKey
        _appSecret = appSecret
        if let userId = NSUserDefaults.standardUserDefaults().objectForKey(appKey) as? String, let authtoken = KCSKeychain2.kinveyTokenForUserId(userId, appKey: appKey) {
            //FIXME: lmt and act
            _activeUser = User(userId: userId, acl: nil, metadata: Metadata(lmt: "", ect: "", authtoken: authtoken))
        }
        return self
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
