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
    case RequestId(requestId: String)
    
    var name: String {
        get {
            switch self {
            case .Authorization:
                return "Authorization"
            case .APIVersion:
                return "X-Kinvey-API-Version"
            case .RequestId:
                return RequestIdHeaderKey
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
            case .RequestId(let requestId):
                return requestId
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

internal typealias DataResponseCompletionHandler = (NSData?, Response?, ErrorType?) -> Void
internal typealias PathResponseCompletionHandler = (NSURL?, Response?, ErrorType?) -> Void

extension NSURLRequest {
    
    /// Description for the NSURLRequest including url, headers and the body content
    public override var description: String {
        var description = "\(HTTPMethod ?? "GET") \(URL?.absoluteString ?? "")"
        if let headers = allHTTPHeaderFields {
            for keyPair in headers {
                description += "\n\(keyPair.0): \(keyPair.1)"
            }
        }
        if let body = HTTPBody, let bodyString = String(data: body, encoding: NSUTF8StringEncoding) {
            description += "\n\n\(bodyString)"
        }
        return description
    }
    
}

extension NSHTTPURLResponse {
    
    /// Description for the NSHTTPURLResponse including url and headers
    public override var description: String {
        var description = "\(statusCode) \(NSHTTPURLResponse.localizedStringForStatusCode(statusCode))"
        for keyPair in allHeaderFields {
            description += "\n\(keyPair.0): \(keyPair.1)"
        }
        return description
    }
    
    /// Description for the NSHTTPURLResponse including url, headers and the body content
    public func description(body: NSData?) -> String {
        var description = self.description
        if let body = body, let bodyString = String(data: body, encoding: NSUTF8StringEncoding) {
            description += "\n\n\(bodyString)"
        }
        return description
    }
    
}

/// REST API Version used in the REST calls.
public let restApiVersion = 4

@objc(__KNVHttpRequest)
internal class HttpRequest: NSObject, Request {
    
    let httpMethod: HttpMethod
    let endpoint: Endpoint
    let defaultHeaders: [HttpHeader] = [
        HttpHeader.APIVersion(version: restApiVersion)
    ]
    
    var headers: [HttpHeader] = []
    
    var request: NSMutableURLRequest
    let credential: Credential?
    let client: Client
    
    private var task: NSURLSessionTask?
    
    internal var executing: Bool {
        get {
            return task?.state == .Running
        }
    }
    
    internal var cancelled: Bool {
        get {
            return task?.state == .Canceling || task?.error?.code == NSURLErrorCancelled
        }
    }
    
    init(request: NSURLRequest, timeout: NSTimeInterval? = nil, client: Client = sharedClient) {
        self.httpMethod = HttpMethod.parse(request.HTTPMethod!)
        self.endpoint = Endpoint.URL(url: request.URL!)
        self.client = client
        
        if let authorization = request.valueForHTTPHeaderField(HttpHeader.Authorization(credential: nil).name) {
            self.credential = HttpHeaderCredential(authorization)
        } else {
            self.credential = client.activeUser ?? client
        }
        self.request = request.mutableCopy() as! NSMutableURLRequest
        if let timeout = timeout {
            self.request.timeoutInterval = timeout
        }
        self.request.setValue(NSUUID().UUIDString, forHTTPHeaderField: RequestIdHeaderKey)
    }
    
    init(httpMethod: HttpMethod = .Get, endpoint: Endpoint, credential: Credential? = nil, timeout: NSTimeInterval? = nil, client: Client = sharedClient) {
        self.httpMethod = httpMethod
        self.endpoint = endpoint
        self.client = client
        self.credential = credential ?? client
        
        let url = endpoint.url()
        request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = httpMethod.stringValue
        if let timeout = timeout {
            request.timeoutInterval = timeout
        }
        self.request.setValue(NSUUID().UUIDString, forHTTPHeaderField: RequestIdHeaderKey)
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
        guard !cancelled else {
            completionHandler?(nil, nil, Error.RequestCancelled)
            return
        }
        
        prepareRequest()
        
        if client.logNetworkEnabled {
            do {
                print("\(request)")
            }
        }
        
        task = client.urlSession.dataTaskWithRequest(request) { (data, response, error) -> Void in
            if self.client.logNetworkEnabled, let response = response as? NSHTTPURLResponse {
                do {
                    print("\(response.description(data))")
                }
            }
            
            completionHandler?(data, HttpResponse(response: response), error)
        }
        task!.resume()
    }
    
    internal func cancel() {
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
            var keyPath = expression.keyPath
            var persistableType = self.persistableType
            if keyPath.containsString(".") {
                var keyPaths = [String]()
                for item in keyPath.componentsSeparatedByString(".") {
                    keyPaths.append(persistableType?.propertyMapping(item) ?? item)
                    if let persistableTypeTmp = persistableType {
                        persistableType = ObjCRuntime.typeForPropertyName(persistableTypeTmp as! AnyClass, propertyName: item) as? Persistable.Type
                    }
                }
                keyPath = keyPaths.joinWithSeparator(".")
            } else if let translatedKeyPath = persistableType?.propertyMapping(keyPath) {
                keyPath = translatedKeyPath
            }
            return NSExpression(forKeyPath: keyPath)
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
