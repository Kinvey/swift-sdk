//
//  Error.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

/// Enum that contains all error types in the library.
public enum Error: ErrorType {
    
    /// Constant for 401 responses where the credentials are not enough to complete the request.
    public static let InsufficientCredentials = "InsufficientCredentials"
    
    /// Constant for 401 responses where the credentials are not valid to complete the request.
    public static let InvalidCredentials = "InvalidCredentials"
    
    /// Error where Object ID is required.
    case ObjectIdMissing
    
    /// Error when a method is not allowed, usually when you are using a Data Link Connector (DLC).
    case MethodNotAllowed(httpResponse: NSHTTPURLResponse?, data: NSData?, debug: String, description: String)
    
    /// Error when a Data Link endpoint is not found, usually when you are using a Data Link Connector (DLC).
    case DataLinkEntityNotFound(httpResponse: NSHTTPURLResponse?, data: NSData?, debug: String, description: String)
    
    /// Error when the type is unknow.
    case UnknownError(httpResponse: NSHTTPURLResponse?, data: NSData?, error: String)
    
    /// Error when the type is unknow.
    case UnknownJsonError(httpResponse: NSHTTPURLResponse?, data: NSData?, json: [String : AnyObject])
    
    /// Error when a Invalid Response coming from the backend.
    case InvalidResponse(httpResponse: NSHTTPURLResponse?, data: NSData?)
    
    /// Error when a Unauthorized Response coming from the backend.
    case Unauthorized(httpResponse: NSHTTPURLResponse?, data: NSData?, error: String, description: String)
    
    /// Error when calls a method that requires an active user.
    case NoActiveUser
    
    /// Error when a request was cancelled.
    case RequestCancelled
    
    /// Error when a request reached a timeout.
    case RequestTimeout
    
    /// Error when calls a method not available for a specific data store type.
    case InvalidDataStoreType
    
    /// Invalid operation
    case InvalidOperation(description: String)
    
    /// Error when a `User` doen't have an email or username.
    case UserWithoutEmailOrUsername
    
    var error: NSError {
        return self as NSError
    }
    
    /// Error localized description.
    public var localizedDescription: String {
        let bundle = NSBundle(forClass: Client.self)
        switch self {
        case .Unauthorized(_, _, _, let description):
            return description
        case .InvalidOperation(let description):
            return description
        case .InvalidResponse(_, _):
            return NSLocalizedString("Error.InvalidResponse", bundle: bundle, comment: "")
        default:
            return NSLocalizedString("Error.\(self)", bundle: bundle, comment: "")
        }
    }
    
    /// Response object contains status code, headers, etc.
    public var httpResponse: NSHTTPURLResponse? {
        switch self {
        case .UnknownError(let httpResponse, _, _):
            return httpResponse
        case .UnknownJsonError(let httpResponse, _, _):
            return httpResponse
        case .DataLinkEntityNotFound(let httpResponse, _, _, _):
            return httpResponse
        case .MethodNotAllowed(let httpResponse, _, _, _):
            return httpResponse
        case .Unauthorized(let httpResponse, _, _, _):
            return httpResponse
        case .InvalidResponse(let httpResponse, _):
            return httpResponse
        default:
            return nil
        }
    }
    
    /// Response Header `X-Kinvey-Request-Id`
    public var requestId: String? {
        return httpResponse?.allHeaderFields[RequestIdHeaderKey] as? String
    }
    
    /// Response Data Body object.
    public var responseDataBody: NSData? {
        switch self {
        case .UnknownError(_, let data, _):
            return data
        case .UnknownJsonError(_, let data, _):
            return data
        case .DataLinkEntityNotFound(_, let data, _, _):
            return data
        case .MethodNotAllowed(_, let data, _, _):
            return data
        case .Unauthorized(_, let data, _, _):
            return data
        case .InvalidResponse(_, let data):
            return data
        default:
            return nil
        }
    }
    
    /// Response Body as a String value.
    public var responseStringBody: String? {
        if let data = responseDataBody, let responseStringBody = String(data: data, encoding: NSUTF8StringEncoding) {
            return responseStringBody
        }
        return nil
    }
    
    static func buildUnknownError(httpResponse httpResponse: NSHTTPURLResponse?, data: NSData?, error: String) -> Error {
        return UnknownError(httpResponse: httpResponse, data: data, error: error)
    }
    
    static func buildUnknownJsonError(httpResponse httpResponse: NSHTTPURLResponse?, data: NSData?, json: [String : AnyObject]) -> Error {
        return UnknownJsonError(httpResponse: httpResponse, data: data, json: json)
    }
    
    static func buildDataLinkEntityNotFound(httpResponse httpResponse: NSHTTPURLResponse?, data: NSData?, json: [String : String]) -> Error {
        return DataLinkEntityNotFound(httpResponse: httpResponse, data: data, debug: json["debug"]!, description: json["description"]!)
    }
    
    static func buildMethodNotAllowed(httpResponse httpResponse: NSHTTPURLResponse?, data: NSData?, json: [String : String]) -> Error {
        return MethodNotAllowed(httpResponse: httpResponse, data: data, debug: json["debug"]!, description: json["description"]!)
    }
    
    static func buildUnauthorized(httpResponse httpResponse: NSHTTPURLResponse?, data: NSData?, json: [String : String]) -> Error {
        return Unauthorized(httpResponse: httpResponse, data: data, error: json["error"]!, description: json["description"]!)
    }
    
}
