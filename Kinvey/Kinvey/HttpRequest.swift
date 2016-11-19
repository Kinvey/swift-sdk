//
//  HttpRequest.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

enum Header: String {
    
    case RequestId = "X-Kinvey-Request-Id"
    case ClientAppVersion = "X-Kinvey-Client-App-Version"
    
}

extension NSMutableURLRequest {
    
    func setValue(value: String?, forHTTPHeaderField field: Header) {
        setValue(value, forHTTPHeaderField: field.rawValue)
    }
    
}

extension NSURLRequest {
    
    func valueForHTTPHeaderField(field: Header) -> String? {
        return valueForHTTPHeaderField(field.rawValue)
    }
    
}

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
    case UserAgent
    case DeviceInfo
    
    var name: String {
        get {
            switch self {
            case .Authorization:
                return "Authorization"
            case .APIVersion:
                return "X-Kinvey-API-Version"
            case .RequestId:
                return Header.RequestId.rawValue
            case .UserAgent:
                return "User-Agent"
            case .DeviceInfo:
                return "X-Kinvey-Device-Information"
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
            case .UserAgent:
                return "Kinvey SDK \(NSBundle(forClass: Client.self).infoDictionary!["CFBundleShortVersionString"]!)"
            case .DeviceInfo:
                return "\(UIDevice.currentDevice().model) \(UIDevice.currentDevice().systemName) \(UIDevice.currentDevice().systemVersion)"
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
internal class HttpRequest: TaskProgressRequest, Request {
    
    let httpMethod: HttpMethod
    let endpoint: Endpoint
    let defaultHeaders: [HttpHeader] = [
        HttpHeader.APIVersion(version: restApiVersion),
        HttpHeader.UserAgent,
        HttpHeader.DeviceInfo
    ]
    
    var headers: [HttpHeader] = []
    
    var request: NSMutableURLRequest
    let credential: Credential?
    let client: Client
    
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
        self.request.setValue(NSUUID().UUIDString, forHTTPHeaderField: .RequestId)
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
        self.request.setValue(NSUUID().UUIDString, forHTTPHeaderField: .RequestId)
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
        if let clientAppVersion = client.clientAppVersion {
            request.setValue(clientAppVersion, forHTTPHeaderField: .ClientAppVersion)
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
