//
//  HttpRequest.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

#if os(iOS) || os(tvOS)
    import UIKit
#elseif os(watchOS)
    import WatchKit
#endif

enum Header: String {
    
    case requestId = "X-Kinvey-Request-Id"
    case clientAppVersion = "X-Kinvey-Client-App-Version"
    
}

extension URLRequest {
    
    mutating func setValue(_ value: String?, forHTTPHeaderField field: Header) {
        setValue(value, forHTTPHeaderField: field.rawValue)
    }
    
    func value(forHTTPHeaderField field: Header) -> String? {
        return value(forHTTPHeaderField: field.rawValue)
    }
    
}

enum HttpMethod {
    
    case get, post, put, delete
    
    var stringValue: String {
        get {
            switch self {
            case .post:
                return "POST"
            case .put:
                return "PUT"
            case .delete:
                return "DELETE"
            case .get:
                fallthrough
            default:
                return "GET"
            }
        }
    }
    
    static func parse(_ httpMethod: String) -> HttpMethod {
        switch httpMethod {
        case "POST":
            return .post
        case "PUT":
            return .put
        case "DELETE":
            return .delete
        case "GET":
            fallthrough
        default:
            return .get
        }
    }
    
    var requestType: RequestType {
        get {
            switch self {
            case .post:
                return .create
            case .put:
                return .update
            case .delete:
                return .delete
            case .get:
                fallthrough
            default:
                return .read
            }
        }
    }
    
}

enum HttpHeader {
    
    case authorization(credential: Credential?)
    case apiVersion(version: Int)
    case requestId(requestId: String)
    case userAgent
    case deviceInfo
    
    var name: String {
        get {
            switch self {
            case .authorization:
                return "Authorization"
            case .apiVersion:
                return "X-Kinvey-API-Version"
            case .requestId:
                return Header.requestId.rawValue
            case .userAgent:
                return "User-Agent"
            case .deviceInfo:
                return "X-Kinvey-Device-Information"
            }
        }
    }
    
    var value: String? {
        get {
            switch self {
            case .authorization(let credential):
                return credential?.authorizationHeader
            case .apiVersion(let version):
                return String(version)
            case .requestId(let requestId):
                return requestId
            case .userAgent:
                return "Kinvey SDK \(Bundle(for: Client.self).infoDictionary!["CFBundleShortVersionString"]!)"
            case .deviceInfo:
                #if os(iOS) || os(tvOS)
                    let device = UIDevice.current
                    return "\(device.model) \(device.systemName) \(device.systemVersion)"
                #elseif os(OSX)
                    let operatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion
                    return "OSX \(operatingSystemVersion.majorVersion).\(operatingSystemVersion.minorVersion).\(operatingSystemVersion.patchVersion)"
                #elseif os(watchOS)
                    let device = WKInterfaceDevice.current()
                    return "\(device.model) \(device.systemName) \(device.systemVersion)"
                #endif
            }
        }
    }
    
}

extension RequestType {
    
    var httpMethod: HttpMethod {
        get {
            switch self {
            case .create:
                return .post
            case .read:
                return .get
            case .update:
                return .put
            case .delete:
                return .delete
            }
        }
    }
    
}

internal typealias DataResponseCompletionHandler = (Data?, Response?, Swift.Error?) -> Void
internal typealias PathResponseCompletionHandler = (URL?, Response?, Swift.Error?) -> Void

extension URLRequest {
    
    /// Description for the NSURLRequest including url, headers and the body content
    public var description: String {
        var description = "\(httpMethod ?? "GET") \(url?.absoluteString ?? "")"
        if let headers = allHTTPHeaderFields {
            for keyPair in headers {
                description += "\n\(keyPair.0): \(keyPair.1)"
            }
        }
        if let body = httpBody, let bodyString = String(data: body, encoding: String.Encoding.utf8) {
            description += "\n\n\(bodyString)"
        }
        return description
    }
    
}

extension HTTPURLResponse {
    
    /// Description for the NSHTTPURLResponse including url and headers
    open override var description: String {
        var description = "\(statusCode) \(HTTPURLResponse.localizedString(forStatusCode: statusCode))"
        for keyPair in allHeaderFields {
            description += "\n\(keyPair.0): \(keyPair.1)"
        }
        return description
    }
    
    /// Description for the NSHTTPURLResponse including url, headers and the body content
    public func description(_ body: Data?) -> String {
        var description = self.description
        if let body = body, let bodyString = String(data: body, encoding: String.Encoding.utf8) {
            description += "\n\n\(bodyString)"
        }
        description += "\n"
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
        HttpHeader.apiVersion(version: restApiVersion),
        HttpHeader.userAgent,
        HttpHeader.deviceInfo
    ]
    
    var headers: [HttpHeader] = []
    
    var request: URLRequest
    let credential: Credential?
    let client: Client
    
    internal var executing: Bool {
        get {
            return task?.state == .running
        }
    }
    
    internal var cancelled: Bool {
        get {
            return task?.state == .canceling || (task?.error as? NSError)?.code == NSURLErrorCancelled
        }
    }
    
    init(request: URLRequest, timeout: TimeInterval? = nil, client: Client = sharedClient) {
        self.httpMethod = HttpMethod.parse(request.httpMethod!)
        self.endpoint = Endpoint.URL(url: request.url!)
        self.client = client
        
        if let authorization = request.value(forHTTPHeaderField: HttpHeader.authorization(credential: nil).name) {
            self.credential = HttpHeaderCredential(authorization)
        } else {
            self.credential = client.activeUser ?? client
        }
        self.request = request
        if let timeout = timeout {
            self.request.timeoutInterval = timeout
        }
        self.request.setValue(UUID().uuidString, forHTTPHeaderField: .requestId)
    }
    
    init(httpMethod: HttpMethod = .get, endpoint: Endpoint, credential: Credential? = nil, timeout: TimeInterval? = nil, client: Client = sharedClient) {
        self.httpMethod = httpMethod
        self.endpoint = endpoint
        self.client = client
        self.credential = credential ?? client
        
        let url = endpoint.url()
        request = URLRequest(url: url)
        request.httpMethod = httpMethod.stringValue
        if let timeout = timeout {
            request.timeoutInterval = timeout
        }
        self.request.setValue(UUID().uuidString, forHTTPHeaderField: .requestId)
    }
    
    func prepareRequest() {
        for header in defaultHeaders {
            request.setValue(header.value, forHTTPHeaderField: header.name)
        }
        if let credential = credential {
            let header = HttpHeader.authorization(credential: credential)
            request.setValue(header.value, forHTTPHeaderField: header.name)
        }
        for header in headers {
            request.setValue(header.value, forHTTPHeaderField: header.name)
        }
        if let clientAppVersion = client.clientAppVersion {
            request.setValue(clientAppVersion, forHTTPHeaderField: .clientAppVersion)
        }
    }
    
    func execute(_ completionHandler: DataResponseCompletionHandler? = nil) {
        guard !cancelled else {
            completionHandler?(nil, nil, Error.requestCancelled)
            return
        }
        
        prepareRequest()
        
        if client.logNetworkEnabled {
            do {
                log.debug("\(self.request.description)")
            }
        }
        
        task = client.urlSession.dataTask(with: request) { (data, response, error) -> Void in
            if self.client.logNetworkEnabled, let response = response as? HTTPURLResponse {
                do {
                    log.debug("\(response.description(data))")
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
            return "curl -X \(request.httpMethod) \(headers) \(request.url!)"
        }
    }

}
