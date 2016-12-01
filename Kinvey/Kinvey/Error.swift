//
//  Error.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

/// Enum that contains all error types in the library.
public enum Error: Swift.Error {
    
    /// Constant for 401 responses where the credentials are not enough to complete the request.
    public static let InsufficientCredentials = "InsufficientCredentials"
    
    /// Constant for 401 responses where the credentials are not valid to complete the request.
    public static let InvalidCredentials = "InvalidCredentials"
    
    /// Error where Object ID is required.
    case objectIdMissing
    
    /// Error when a method is not allowed, usually when you are using a Data Link Connector (DLC).
    case methodNotAllowed(httpResponse: HTTPURLResponse?, data: Data?, debug: String, description: String)
    
    /// Error when a Data Link endpoint is not found, usually when you are using a Data Link Connector (DLC).
    case dataLinkEntityNotFound(httpResponse: HTTPURLResponse?, data: Data?, debug: String, description: String)
    
    /// Error when the type is unknow.
    case unknownError(httpResponse: HTTPURLResponse?, data: Data?, error: String)
    
    /// Error when the type is unknow.
    case unknownJsonError(httpResponse: HTTPURLResponse?, data: Data?, json: [String : Any])
    
    /// Error when a Invalid Response coming from the backend.
    case invalidResponse(httpResponse: HTTPURLResponse?, data: Data?)
    
    /// Error when a Unauthorized Response coming from the backend.
    case unauthorized(httpResponse: HTTPURLResponse?, data: Data?, error: String, description: String)
    
    /// Error when calls a method that requires an active user.
    case noActiveUser
    
    /// Error when a request was cancelled.
    case requestCancelled
    
    /// Error when a request reached a timeout.
    case requestTimeout
    
    /// Error when calls a method not available for a specific data store type.
    case invalidDataStoreType
    
    /// Invalid operation
    case invalidOperation(description: String)
    
    /// Error when a `User` doen't have an email or username.
    case userWithoutEmailOrUsername
    
    var error: NSError {
        return self as NSError
    }
    
    /// Error localized description.
    public var localizedDescription: String {
        let bundle = Bundle(for: Client.self)
        switch self {
        case .unauthorized(_, _, _, let description),
             .invalidOperation(let description):
            return description
        case .invalidResponse(_, _):
            return NSLocalizedString("Error.invalidResponse", bundle: bundle, comment: "")
        default:
            return NSLocalizedString("Error.\(self)", bundle: bundle, comment: "")
        }
    }
    
    /// Response object contains status code, headers, etc.
    public var httpResponse: HTTPURLResponse? {
        switch self {
        case .unknownError(let httpResponse, _, _),
             .unknownJsonError(let httpResponse, _, _),
             .dataLinkEntityNotFound(let httpResponse, _, _, _),
             .methodNotAllowed(let httpResponse, _, _, _),
             .unauthorized(let httpResponse, _, _, _),
             .invalidResponse(let httpResponse, _):
            return httpResponse
        default:
            return nil
        }
    }
    
    /// Response Header `X-Kinvey-Request-Id`
    public var requestId: String? {
        return httpResponse?.allHeaderFields[Header.requestId] as? String
    }
    
    /// Response Data Body object.
    public var responseDataBody: Data? {
        switch self {
        case .unknownError(_, let data, _),
             .unknownJsonError(_, let data, _),
             .dataLinkEntityNotFound(_, let data, _, _),
             .methodNotAllowed(_, let data, _, _),
             .unauthorized(_, let data, _, _),
             .invalidResponse(_, let data):
            return data
        default:
            return nil
        }
    }
    
    /// Response Body as a String value.
    public var responseStringBody: String? {
        if let data = responseDataBody, let responseStringBody = String(data: data, encoding: .utf8) {
            return responseStringBody
        }
        return nil
    }
    
    static func buildUnknownError(httpResponse: HTTPURLResponse?, data: Data?, error: String) -> Error {
        return unknownError(httpResponse: httpResponse, data: data, error: error)
    }
    
    static func buildUnknownJsonError(httpResponse: HTTPURLResponse?, data: Data?, json: [String : Any]) -> Error {
        return unknownJsonError(httpResponse: httpResponse, data: data, json: json)
    }
    
    static func buildDataLinkEntityNotFound(httpResponse: HTTPURLResponse?, data: Data?, json: [String : String]) -> Error {
        return dataLinkEntityNotFound(httpResponse: httpResponse, data: data, debug: json["debug"]!, description: json["description"]!)
    }
    
    static func buildMethodNotAllowed(httpResponse: HTTPURLResponse?, data: Data?, json: [String : String]) -> Error {
        return methodNotAllowed(httpResponse: httpResponse, data: data, debug: json["debug"]!, description: json["description"]!)
    }
    
    static func buildUnauthorized(httpResponse: HTTPURLResponse?, data: Data?, json: [String : String]) -> Error {
        return unauthorized(httpResponse: httpResponse, data: data, error: json["error"]!, description: json["description"]!)
    }
    
}
