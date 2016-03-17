//
//  HttpRequest.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

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

public typealias DataResponseCompletionHandler = (NSData?, Response?, ErrorType?) -> Void

@objc(__KNVHttpRequest)
public class HttpRequest: NSObject, Request {
    
    let httpMethod: HttpMethod
    let endpoint: Endpoint
    let defaultHeaders = [
        HttpHeader.APIVersion(version: 3)
    ]
    
    var headers: [HttpHeader] = []
    
    var request: NSMutableURLRequest
    let credential: Credential?
    let client: Client
    
    var task: NSURLSessionTask?
    
    public var executing: Bool {
        get {
            return task?.state == .Running
        }
    }
    
    public var canceled: Bool {
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
    
    func prepareRequest() {
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
    }
    
    func execute(completionHandler: DataResponseCompletionHandler? = nil) {
        guard !canceled else {
            completionHandler?(nil, nil, Error.RequestCanceled)
            return
        }
        
        prepareRequest()
        
//        print("\(curlCommand)")
        
        task = client.urlSession.dataTaskWithRequest(request) { (data, response, error) -> Void in
            completionHandler?(data, HttpResponse(response: response as? NSHTTPURLResponse), error)
        }
        task!.resume()
    }
    
    public func cancel() {
        task?.cancel()
    }
    
    var curlCommand: String {
        get {
            prepareRequest()
            
            var headers = ""
            if let allHTTPHeaderFields = request.allHTTPHeaderFields {
                for header in allHTTPHeaderFields {
                    headers += "-H \"\(header.0): \(header.1)\" "
                }
            }
            return "curl -X \(request.HTTPMethod) \(headers) \(request.URL!)"
        }
    }

}

extension Query {
    
    private func translateExpression(expression: NSExpression) -> NSExpression {
        switch expression.expressionType {
        case .KeyPathExpressionType:
            return NSExpression(forKeyPath: persistableType?.kinveyPropertyMapping()[expression.keyPath] ?? expression.keyPath)
        default:
            return expression
        }
    }
    
    private func translatePredicate(predicate: NSPredicate) -> NSPredicate {
        if let predicate = predicate as? NSComparisonPredicate {
            return NSComparisonPredicate(
                leftExpression: translateExpression(predicate.leftExpression),
                rightExpression: translateExpression(predicate.rightExpression),
                modifier: predicate.comparisonPredicateModifier,
                type: predicate.predicateOperatorType,
                options: predicate.options
            )
        } else if let predicate = predicate as? NSCompoundPredicate {
            var subpredicates = [NSPredicate]()
            for predicate in predicate.subpredicates as! [NSPredicate] {
                subpredicates.append(translatePredicate(predicate))
            }
            return NSCompoundPredicate(type: predicate.compoundPredicateType, subpredicates: subpredicates)
        }
        return predicate
    }
    
    func urlQueryStringEncoded() -> String {
        let queryObj: [NSObject : AnyObject]!
        if let predicate = predicate {
            let translatedPredicate = translatePredicate(predicate)
            queryObj = try! MongoDBPredicateAdaptor.queryDictFromPredicate(translatedPredicate)
        } else {
            queryObj = [:]
        }
        let data = try! NSJSONSerialization.dataWithJSONObject(queryObj, options: [])
        var queryStr = String(data: data, encoding: NSUTF8StringEncoding)!
        queryStr = queryStr.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())!
        return queryStr
    }
    
    func isEmpty() -> Bool {
        return self.predicate == nil && self.sortDescriptors == nil
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
        case .UserResetPassword(let usernameOrEmail, let client):
            return client.apiHostName.URLByAppendingPathComponent("/rpc/\(client.appKey!)/\(usernameOrEmail)/user-password-reset-initiate")
        case .UserForgotUsername(let client):
            return client.apiHostName.URLByAppendingPathComponent("/rpc/\(client.appKey!)/user-forgot-username")
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
        case AppDataByQuery(let client, let collectionName, let query, let fields):
            let url = client.apiHostName.URLByAppendingPathComponent("/appdata/\(client.appKey!)/\(collectionName)/").absoluteString
            if (query.isEmpty()){
                return NSURL(string: url)!
            }
            let queryStr = query.urlQueryStringEncoded()
            let urlQuery = "?query=\(queryStr)"
            var fieldsStr = ""
            if let fields = fields {
                fieldsStr = "&fields=\(fields.joinWithSeparator(",").stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())!)"
            }
            return NSURL(string: url + urlQuery + fieldsStr)!
        case .PushRegisterDevice(let client):
            return client.apiHostName.URLByAppendingPathComponent("/push/\(client.appKey!)/register-device")
        case .PushUnRegisterDevice(let client):
            return client.apiHostName.URLByAppendingPathComponent("/push/\(client.appKey!)/unregister-device")
        case .BlobById(let client, let fileId):
            return BlobDownload(client: client, fileId: fileId, query: nil, tls: false, ttlInSeconds: nil).url()
        case BlobUpload(let client, let fileId, let tls):
            return BlobDownload(client: client, fileId: fileId, query: nil, tls: tls, ttlInSeconds: nil).url()
        case BlobDownload(let client, let fileId, let query, let tls, let ttlInSeconds):
            let url = client.apiHostName.URLByAppendingPathComponent("/blob/\(client.appKey!)/\(fileId ?? "")").absoluteString
            
            var queryParams: [String : String] = [:]
            
            if let query = query {
                queryParams["query"] = query.urlQueryStringEncoded()
            }
            
            if tls {
                queryParams["tls"] = "true"
            }
            
            if let ttlInSeconds = ttlInSeconds {
                queryParams["ttl_in_seconds"] = String(ttlInSeconds)
            }
            
            var urlQuery = queryParams.count > 0 ? "?" : ""
            for queryItem in queryParams {
                urlQuery += "\(queryItem.0)=\(queryItem.1)&"
            }
            if urlQuery.characters.count > 0 {
                urlQuery.removeAtIndex(urlQuery.endIndex.predecessor())
            }
            
            return NSURL(string: url + urlQuery)!
        case .BlobByQuery(let client, let query):
            return BlobDownload(client: client, fileId: nil, query: query, tls: true, ttlInSeconds: nil).url()
        case URL(let url):
            return url
        }
    }
    
}
