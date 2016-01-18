//
//  Endpoint.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import MongoDBPredicateAdaptor

public enum Endpoint {
    
    case User(client: Client)
    case UserById(client: Client, userId: String)
    case UserExistsByUsername(client: Client)
    case UserLogin(client: Client)
    case OAuthAuth(client: Client, redirectURI: NSURL)
    case OAuthToken(client: Client)
    case AppData(client: Client, collectionName: String)
    case AppDataById(client: Client, collectionName: String, id: String)
    case AppDataByQuery(client: Client, collectionName: String, query: Query)
    case Blob(client: Client, tls: Bool)
    case URL(url: NSURL)
    
    func url() -> NSURL {
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
            return NSURL(string: client.authHostName.URLByAppendingPathComponent("/oauth/auth").absoluteString + query)!
        case .OAuthToken(let client):
            return client.authHostName.URLByAppendingPathComponent("/oauth/token")
        case AppData(let client, let collectionName):
            return client.apiHostName.URLByAppendingPathComponent("/appdata/\(client.appKey!)/\(collectionName)")
        case AppDataById(let client, let collectionName, let id):
            return client.apiHostName.URLByAppendingPathComponent("/appdata/\(client.appKey!)/\(collectionName)/\(id)")
        case AppDataByQuery(let client, let collectionName, let query):
            let queryObj: [NSObject : AnyObject]!
            do {
                queryObj = try MongoDBPredicateAdaptor.queryDictFromPredicate(query.predicate)
            } catch _ {
                queryObj = [:]
            }
            let data = try! NSJSONSerialization.dataWithJSONObject(queryObj, options: [])
            var queryStr = NSString(data: data, encoding: NSUTF8StringEncoding)
            queryStr = queryStr!.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())
            let url = client.apiHostName.URLByAppendingPathComponent("/appdata/\(client.appKey!)/\(collectionName)/").absoluteString
            let urlQuery = "?query=\(queryStr!)"
            return NSURL(string: url + urlQuery)!
        case Blob(let client, let tls):
            let url = client.apiHostName.URLByAppendingPathComponent("/blob/\(client.appKey!)/").absoluteString
            let urlQuery = tls ? "?tls=true" : ""
            return NSURL(string: url + urlQuery)!
        case URL(let url):
            return url
        }
    }
    
}
