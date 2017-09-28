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

struct HeaderField {
    
    static let userAgent = "User-Agent"
    
}

struct KinveyHeaderField {
    
    static let requestId = "X-Kinvey-Request-Id"
    static let clientAppVersion = "X-Kinvey-Client-App-Version"
    static let customRequestProperties = "X-Kinvey-Custom-Request-Properties"
    static let apiVersion = "X-Kinvey-API-Version"
    static let deviceInformation = "X-Kinvey-Device-Information"
    
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

enum HttpHeaderKey: String {
    
    case authorization = "Authorization"
    
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
                return HttpHeaderKey.authorization.rawValue
            case .apiVersion:
                return KinveyHeaderField.apiVersion
            case .requestId:
                return KinveyHeaderField.requestId
            case .userAgent:
                return HeaderField.userAgent
            case .deviceInfo:
                return KinveyHeaderField.deviceInformation
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
            for (headerField, value) in headers {
                description += "\n\(headerField): \(value)"
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
        for (headerField, value) in allHeaderFields {
            description += "\n\(headerField): \(value)"
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

extension String {
    
    internal func stringByAddingPercentEncodingForFormData(plusForSpace: Bool = false) -> String? {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "*-._")
        
        if plusForSpace {
            allowed.insert(charactersIn: " ")
        }
        
        var encoded = addingPercentEncoding(withAllowedCharacters: allowed)
        if plusForSpace {
            encoded = encoded?.replacingOccurrences(of: " ", with: "+")
        }
        return encoded
    }
    
}

/// REST API Version used in the REST calls.
public let restApiVersion = 4

enum Body {
    
    case json(json: JsonDictionary)
    case formUrlEncoded(params: [String : String])
    
    func attachTo(request: inout URLRequest) {
        switch self {
        case .json(let json):
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = try! JSONSerialization.data(withJSONObject: json)
        case .formUrlEncoded(let params):
            request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
            var paramsKeyValue = [String]()
            for (key, value) in params {
                if let key = key.stringByAddingPercentEncodingForFormData(),
                    let value = value.stringByAddingPercentEncodingForFormData()
                {
                    paramsKeyValue.append("\(key)=\(value)")
                }
            }
            let httpBody = paramsKeyValue.joined(separator: "&")
            request.httpBody = httpBody.data(using: .utf8)
        }
    }
    
    static func buildFormUrlEncoded(body: String) -> Body {
        let regex = try! NSRegularExpression(pattern: "([^&=]+)=([^&]*)")
        var params = [String : String]()
        let nsbody = body as NSString
        for match in regex.matches(in: body, range: NSMakeRange(0, body.characters.count)) {
            if match.numberOfRanges == 3 {
                let key = nsbody.substring(with: match.range(at: 1))
                let value = nsbody.substring(with: match.range(at: 2))
                params[key] = value
            }
        }
        return .formUrlEncoded(params: params)
    }
    
}

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
    var credential: Credential? {
        didSet {
            setAuthorization()
        }
    }
    let options: Options?
    let client: Client
    
    internal var executing: Bool {
        get {
            return task?.state == .running
        }
    }
    
    internal var cancelled: Bool {
        get {
            return task?.state == .canceling || (task?.error as NSError?)?.code == NSURLErrorCancelled
        }
    }
    
    init(
        request: URLRequest,
        options: Options?
    ) {
        self.httpMethod = HttpMethod.parse(request.httpMethod!)
        self.endpoint = Endpoint.url(url: request.url!)
        self.options = options
        let client = options?.client ?? sharedClient
        self.client = client
        
        if request.value(forHTTPHeaderField: HttpHeaderKey.authorization.rawValue) == nil {
            self.credential = client.activeUser ?? client
        }
        self.request = request
        if let timeout = options?.timeout {
            self.request.timeoutInterval = timeout
        }
        self.request.setValue(UUID().uuidString, forHTTPHeaderField: KinveyHeaderField.requestId)
    }
    
    init(
        httpMethod: HttpMethod = .get,
        endpoint: Endpoint,
        credential: Credential? = nil,
        body: Body? = nil,
        options: Options?
    ) {
        self.httpMethod = httpMethod
        self.endpoint = endpoint
        self.options = options
        let client = options?.client ?? sharedClient
        self.client = client
        self.credential = credential ?? client
        
        let url = endpoint.url
        request = URLRequest(url: url)
        request.httpMethod = httpMethod.stringValue
        request.timeoutInterval = options?.timeout ?? client.options?.timeout ?? client.timeoutInterval
        if let body = body {
            body.attachTo(request: &request)
        }
        self.request.setValue(UUID().uuidString, forHTTPHeaderField: KinveyHeaderField.requestId)
    }
    
    private func setAuthorization() {
        if let credential = credential {
            let header = HttpHeader.authorization(credential: credential)
            request.setValue(header.value, forHTTPHeaderField: header.name)
        }
    }
    
    func prepareRequest() {
        for header in defaultHeaders {
            request.setValue(header.value, forHTTPHeaderField: header.name)
        }
        setAuthorization()
        for header in headers {
            request.setValue(header.value, forHTTPHeaderField: header.name)
        }
        if let clientAppVersion = options?.clientAppVersion ?? client.options?.clientAppVersion {
            request.setValue(clientAppVersion, forHTTPHeaderField: KinveyHeaderField.clientAppVersion)
        }
        
        if let customRequestProperties = self.options?.customRequestProperties ?? client.options?.customRequestProperties,
            customRequestProperties.count > 0,
            let data = try? JSONSerialization.data(withJSONObject: customRequestProperties),
            let customRequestPropertiesString = String(data: data, encoding: .utf8)
        {
            request.setValue(customRequestPropertiesString, forHTTPHeaderField: KinveyHeaderField.customRequestProperties)
        }
        
        if let url = request.url,
            let query = url.query,
            query.contains("+"),
            let decodedQuery = query.removingPercentEncoding,
            let newQuery = decodedQuery.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "+"))),
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        {
            urlComponents.percentEncodedQuery = newQuery
            request.url = urlComponents.url
        }
    }
    
    func execute(urlSession: URLSession? = nil, _ completionHandler: DataResponseCompletionHandler? = nil) {
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
        
        let urlSession = urlSession ?? client.urlSession
        task = urlSession.dataTask(with: request) { (data, response, error) -> Void in
            if let response = response as? HTTPURLResponse {
                if self.client.logNetworkEnabled {
                    do {
                        log.debug("\(response.description(data))")
                    }
                }
                if response.statusCode == 401,
                    let user = self.credential as? User,
                    let socialIdentity = user.socialIdentity,
                    let kinveyAuthToken = socialIdentity.kinvey,
                    let refreshToken = kinveyAuthToken["refresh_token"] as? String
                {
                    MIC.login(refreshToken: refreshToken, authServiceId: self.client.clientId) { user, error in
                        if let user = user {
                            self.credential = user
                            self.execute(urlSession: urlSession, completionHandler)
                        } else {
                            completionHandler?(data, HttpResponse(response: response), error)
                        }
                    }
                    return
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
                for (headerField, value) in allHTTPHeaderFields {
                    headers += "-H \"\(headerField): \(value)\" "
                }
            }
            return "curl -X \(String(describing: request.httpMethod)) \(headers) \(request.url!)"
        }
    }
    
    func setBody(json: [String : Any]) {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try! JSONSerialization.data(withJSONObject: json)
    }

}
