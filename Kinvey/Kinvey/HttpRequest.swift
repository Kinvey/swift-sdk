//
//  HttpRequest.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import MongoDBPredicateAdaptor

enum HttpMethod {
    
    case Get, Post, Put, Delete
    
    var stringValue: String {
        get {
            switch self {
            case .Post:
                return "POST"
            case .Put:
                return "PUT"
            case .Delete:
                return "DELETE"
            case .Get:
                fallthrough
            default:
                return "GET"
            }
        }
    }
    
    static func parse(httpMethod: String) -> HttpMethod {
        switch httpMethod {
        case "POST":
            return .Post
        case "PUT":
            return .Put
        case "DELETE":
            return .Delete
        case "GET":
            fallthrough
        default:
            return .Get
        }
    }
    
    var requestType: RequestType {
        get {
            switch self {
            case .Post:
                return .Create
            case .Put:
                return .Update
            case .Delete:
                return .Delete
            case .Get:
                fallthrough
            default:
                return .Read
            }
        }
    }
    
}

enum HttpHeader {
    
    case Authorization(credential: Credential?)
    case APIVersion(version: Int)
    
    var name: String {
        get {
            switch self {
            case .Authorization:
                return "Authorization"
            case .APIVersion:
                return "X-Kinvey-API-Version"
            }
        }
    }
    
    var value: String? {
        get {
            switch self {
            case .Authorization(let credential):
                return credential?.authorizationHeader
            case .APIVersion(let version):
                return String(version)
            }
        }
    }
    
}

extension RequestType {
    
    var httpMethod: HttpMethod {
        get {
            switch self {
            case .Create:
                return .Post
            case .Read:
                return .Get
            case .Update:
                return .Put
            case .Delete:
                return .Delete
            }
        }
    }
    
}

class HttpRequest: Request {
    
    let httpMethod: HttpMethod
    let endpoint: Endpoint
    let defaultHeaders = [
        HttpHeader.APIVersion(version: 3)
    ]
    
    var headers: [HttpHeader] = []
    
    let request: NSMutableURLRequest
    let credential: Credential?
    let client: Client
    
    var task: NSURLSessionTask?
    
    var executing: Bool {
        get {
            return task?.state == .Running
        }
    }
    
    var canceled: Bool {
        get {
            return task?.state == .Canceling || task?.error?.code == NSURLErrorCancelled
        }
    }
    
    init(request: NSURLRequest, client: Client = sharedClient) {
        self.httpMethod = HttpMethod.parse(request.HTTPMethod!)
        self.endpoint = Endpoint.URL(url: request.URL!)
        self.client = client
        
        if let authorization = request.valueForHTTPHeaderField(HttpHeader.Authorization(credential: nil).name) {
            self.credential = HttpHeaderCredential(authorization)
        } else {
            self.credential = client.activeUser ?? client
        }
        self.request = request.mutableCopy() as! NSMutableURLRequest
    }
    
    init(httpMethod: HttpMethod = .Get, endpoint: Endpoint, credential: Credential? = nil, client: Client = sharedClient) {
        self.httpMethod = httpMethod
        self.endpoint = endpoint
        self.client = client
        self.credential = credential ?? client
        
        let url = endpoint.url()
        request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = httpMethod.stringValue
    }
    
    func execute(completionHandler: DataResponseCompletionHandler? = nil) {
        for header in defaultHeaders {
            request.setValue(header.value, forHTTPHeaderField: header.name)
        }
        if let credential = credential {
            let header = HttpHeader.Authorization(credential: credential)
            request.setValue(header.value, forHTTPHeaderField: header.name)
        }
        for header in headers {
            request.setValue(header.value, forHTTPHeaderField: header.name)
        }
        
        task = client.urlSession.dataTaskWithRequest(request) { (data, response, error) -> Void in
            completionHandler?(data, HttpResponse(response: response as! NSHTTPURLResponse), error)
        }
        task!.resume()
    }
    
    func cancel() {
        task?.cancel()
    }

}

extension Endpoint {
    
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
