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

enum KinveyHeaderField: String {
    
    case requestId = "X-Kinvey-Request-Id"
    case clientAppVersion = "X-Kinvey-Client-App-Version"
    case customRequestProperties = "X-Kinvey-Custom-Request-Properties"
    case apiVersion = "X-Kinvey-API-Version"
    case deviceInfo = "X-Kinvey-Device-Info"
    
}

extension Dictionary where Key == AnyHashable {
    
    subscript<K: RawRepresentable>(key: K) -> Value? where K.RawValue: Hashable {
        return self[key.rawValue]
    }
    
}

enum HttpMethod {
    
    case get, post, put, delete
    
    var stringValue: String {
        switch self {
        case .post:
            return "POST"
        case .put:
            return "PUT"
        case .delete:
            return "DELETE"
        default:
            return "GET"
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
        default:
            return .get
        }
    }
    
    var requestType: RequestType {
        switch self {
        case .post:
            return .create
        case .put:
            return .update
        case .delete:
            return .delete
        default:
            return .read
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
        switch self {
        case .authorization:
            return HttpHeaderKey.authorization.rawValue
        case .apiVersion:
            return KinveyHeaderField.apiVersion.rawValue
        case .requestId:
            return KinveyHeaderField.requestId.rawValue
        case .userAgent:
            return HeaderField.userAgent
        case .deviceInfo:
            return KinveyHeaderField.deviceInfo.rawValue
        }
    }
    
    var value: String? {
        switch self {
        case .authorization(let credential):
            return credential?.authorizationHeader
        case .apiVersion(let version):
            return String(version)
        case .requestId(let requestId):
            return requestId
        case .userAgent:
            return "Kinvey SDK \(Bundle(for: Client.self).infoDictionary!["CFBundleShortVersionString"]!) (Swift \(swiftVersion))"
        case .deviceInfo:
            let data = try! jsonEncoder.encode(DeviceInfo())
            return String(data: data, encoding: .utf8)
        }
    }
    
}

extension RequestType {
    
    var httpMethod: HttpMethod {
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
    
    mutating func setValue<Header: RawRepresentable>(_ value: String?, forHTTPHeaderField header: Header) where Header.RawValue == String {
        setValue(value, forHTTPHeaderField: header.rawValue)
    }
    
    mutating func addValue<Header: RawRepresentable>(_ value: String, forHTTPHeaderField header: Header) where Header.RawValue == String {
        addValue(value, forHTTPHeaderField: header.rawValue)
    }
    
    func value<Header: RawRepresentable>(forHTTPHeaderField header: Header) -> String? where Header.RawValue == String {
        return value(forHTTPHeaderField: header.rawValue)
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
        for match in regex.matches(in: body, range: NSRange(location: 0, length: body.count)) where match.numberOfRanges == 3 {
            let key = nsbody.substring(with: match.range(at: 1))
            let value = nsbody.substring(with: match.range(at: 2))
            params[key] = value
        }
        return .formUrlEncoded(params: params)
    }
    
}

internal class HttpRequest<Result>: TaskProgressRequest, Request {
    
    typealias ResultType = Result
    
    var result: Result?
    
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
        return task?.state == .running
    }
    
    internal var cancelled: Bool {
        return task?.state == .canceling || (task?.error as NSError?)?.code == NSURLErrorCancelled
    }
    
    init(
        request: URLRequest,
        options: Options?
    ) {
        self.httpMethod = HttpMethod.parse(request.httpMethod!)
        self.endpoint = URLEndpoint(url: request.url!)
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
        if let timeout = options?.timeout ?? client.options?.timeout {
            request.timeoutInterval = timeout
        }
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
        execute(retry: true, urlSession: urlSession, completionHandler)
    }
    
    func execute(retry: Bool, urlSession: URLSession?, _ completionHandler: DataResponseCompletionHandler?) {
        guard !cancelled else {
            completionHandler?(nil, nil, Error.requestCancelled)
            return
        }
        
        prepareRequest()
        
        if client.logNetworkEnabled {
            do {
                log.debug("\(request.description)")
            }
        }
        
        let urlSession = urlSession ?? options?.urlSession ?? client.urlSession
        task = urlSession.dataTask(with: request) { (data, response, error) -> Void in
            self.handleResponse(
                retry: retry,
                urlSession: urlSession,
                data: data,
                response: response,
                error: error,
                completionHandler: completionHandler
            )
        }
        task!.resume()
    }
    
    private func handleResponse(
        retry: Bool,
        urlSession: URLSession,
        data: Data?,
        response: URLResponse?,
        error: Swift.Error?,
        completionHandler: DataResponseCompletionHandler?
    ) {
        if let response = response as? HTTPURLResponse {
            if client.logNetworkEnabled {
                do {
                    log.debug("\(response.description(data))")
                }
            }
            if response.statusCode == 401,
                retry,
                let user = credential as? User,
                let data = data,
                let json = try? client.jsonParser.parseDictionary(from: data) as? [String : String],
                json["error"] != Error.Keys.insufficientCredentials.rawValue
            {
                DispatchQueue.global(qos: .default).async {
                    self.refreshToken(
                        user: user,
                        urlSession: urlSession,
                        data: data,
                        response: response,
                        error: error,
                        completionHandler: completionHandler
                    )
                }
                return
            }
        }
        
        completionHandler?(data, HttpResponse(response: response), error)
    }
    
    private func refreshToken(
        user: User,
        urlSession: URLSession,
        data: Data?,
        response: URLResponse?,
        error: Swift.Error?,
        completionHandler: DataResponseCompletionHandler?
    ) {
        guard !client.refreshingToken else {
            log.debug("Waiting to refresh token. Request: \(request.url!)")
            client.refreshTokenDispatchGroup.wait()
            if let newUser = client.activeUser {
                log.debug("Retrying request after refresh token. Request: \(request.url!)")
                credential = newUser
                execute(retry: false, urlSession: urlSession, completionHandler)
            } else {
                log.debug("Refresh token failed. Logging out current user. Request: \(request.url!)")
                user.logout()
                completionHandler?(data, HttpResponse(response: response), error)
            }
            return
        }
        client.refreshingToken = true
        client.refreshTokenDispatchGroup.enter()
        guard let refreshToken = user.refreshToken else {
            log.debug("Refresh token not available. Logging out current user. Request: \(request.url!)")
            user.logout()
            completionHandler?(data, HttpResponse(response: response), error)
            self.client.refreshingToken = false
            client.refreshTokenDispatchGroup.leave()
            return
        }
        log.debug("Refreshing token. Request: \(request.url!)")
        let options = try! Options(self.options, authServiceId: client.clientId)
        MIC.login(refreshToken: refreshToken, options: options) {
            switch $0 {
            case .success(let user):
                self.credential = user
                log.debug("Retrying request after refresh token. Request: \(self.request.url!)")
                self.execute(retry: false, urlSession: urlSession, completionHandler)
            case .failure(let error):
                if let error = error as? Kinvey.Error {
                    switch error {
                    case .invalidCredentials:
                        if let user = self.credential as? User {
                            log.debug("Logging out current user. Request: \(self.request.url!)")
                            user.logout()
                        }
                    default:
                        break
                    }
                }
                log.debug("Refresh token failed. Request: \(self.request.url!)")
                completionHandler?(data, HttpResponse(response: response), error)
            }
            self.client.refreshingToken = false
            self.client.refreshTokenDispatchGroup.leave()
        }
    }
    
    internal func cancel() {
        task?.cancel()
    }
    
    var curlCommand: String {
        prepareRequest()
        
        var headers = ""
        if let allHTTPHeaderFields = request.allHTTPHeaderFields {
            for (headerField, value) in allHTTPHeaderFields {
                headers += "-H \"\(headerField): \(value)\" "
            }
        }
        return "curl -X \(String(describing: request.httpMethod)) \(headers) \(request.url!)"
    }
    
    func setBody(json: [String : Any]) {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try! JSONSerialization.data(withJSONObject: json)
    }

}
