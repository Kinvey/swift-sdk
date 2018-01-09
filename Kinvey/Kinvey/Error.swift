//
//  Error.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

/// Enum that contains all error types in the library.
public enum Error: Swift.Error, LocalizedError, CustomStringConvertible, CustomDebugStringConvertible {
    
    public enum Keys: String {
        
        /// Constant for 401 responses where the credentials are not enough to complete the request.
        case insufficientCredentials = "InsufficientCredentials"
        
        /// Constant for 401 responses where the credentials are not valid to complete the request.
        case invalidCredentials = "InvalidCredentials"
        
        /// Constant for 400 response where the number of results exceeded the limit.
        case resultSetSizeExceeded = "ResultSetSizeExceeded"
        
        /// Constant for 404 response where the entity was not found in the collection
        case entityNotFound = "EntityNotFound"
        
    }
    
    /// Error where Object ID is required.
    case objectIdMissing
    
    /// Error when a method is not allowed, usually when you are using a Data Link Connector (DLC).
    case methodNotAllowed(httpResponse: HTTPURLResponse?, data: Data?, debug: String, description: String)
    
    /// Error when a Data Link endpoint is not found, usually when you are using a Data Link Connector (DLC).
    case dataLinkEntityNotFound(httpResponse: HTTPURLResponse?, data: Data?, debug: String, description: String)
    
    /// Error when there's a missing configuration in the backend.
    case missingConfiguration(httpResponse: HTTPURLResponse?, data: Data?, debug: String, description: String)
    
    /// Error when the type is unknow.
    case unknownError(httpResponse: HTTPURLResponse?, data: Data?, error: String)
    
    /// Error when the type is unknow.
    case unknownJsonError(httpResponse: HTTPURLResponse?, data: Data?, json: [String : Any])
    
    /// Error when a Invalid Response coming from the backend.
    case invalidResponse(httpResponse: HTTPURLResponse?, data: Data?)
    
    /// Error when a Unauthorized Response coming from the backend.
    case unauthorized(httpResponse: HTTPURLResponse?, data: Data?, error: String, debug: String, description: String)
    
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
    
    /// Error when the `appKey` and `appSecret` does not match with any Kinvey environment.
    case appNotFound(description: String)
    
    /// Error when any operation is called but the client was not initiliazed yet.
    case clientNotInitialized
    
    /// Error forbidden
    case forbidden(description: String)
    
    /// Error when the number of results exceeded the limit
    case resultSetSizeExceeded(debug: String, description: String)
    
    case entityNotFound(debug: String, description: String)
    
    /// Error localized description.
    public var description: String {
        let bundle = Bundle(for: Client.self)
        switch self {
        case .methodNotAllowed(_, _, _, let description),
             .dataLinkEntityNotFound(_, _, _, let description),
             .unknownError(_, _, let description),
             .unauthorized(_, _, _, _, let description),
             .invalidOperation(let description),
             .missingConfiguration(_, _, _, let description),
             .appNotFound(let description),
             .forbidden(let description),
             .resultSetSizeExceeded(_, let description),
             .entityNotFound(_, let description):
            return description
        case .objectIdMissing:
            return NSLocalizedString("Error.objectIdMissing", bundle: bundle, comment: "")
        case .unknownJsonError:
            return NSLocalizedString("Error.unknownJsonError", bundle: bundle, comment: "")
        case .invalidResponse(_, _):
            return NSLocalizedString("Error.invalidResponse", bundle: bundle, comment: "")
        case .noActiveUser:
            return NSLocalizedString("Error.noActiveUser", bundle: bundle, comment: "")
        case .requestCancelled:
            return NSLocalizedString("Error.requestCancelled", bundle: bundle, comment: "")
        case .requestTimeout:
            return NSLocalizedString("Error.requestTimeout", bundle: bundle, comment: "")
        case .invalidDataStoreType:
            return NSLocalizedString("Error.invalidDataStoreType", bundle: bundle, comment: "")
        case .userWithoutEmailOrUsername:
            return NSLocalizedString("Error.userWithoutEmailOrUsername", bundle: bundle, comment: "")
        case .clientNotInitialized:
            return NSLocalizedString("Error.clientNotInitialized", bundle: bundle, comment: "")
        }
    }
    
    public var errorDescription: String? {
        return description
    }
    
    public var failureReason: String? {
        return description
    }
    
    public var debugDescription: String {
        switch self {
        case .methodNotAllowed(_, _, let debug, _),
             .dataLinkEntityNotFound(_, _, let debug, _),
             .missingConfiguration(_, _, let debug, _),
             .unauthorized(_, _, _, let debug, _),
             .resultSetSizeExceeded(let debug, _),
             .entityNotFound(let debug, _):
            return debug
        default:
            return description
        }
    }
    
    /// Response object contains status code, headers, etc.
    public var httpResponse: HTTPURLResponse? {
        switch self {
        case .unknownError(let httpResponse, _, _),
             .unknownJsonError(let httpResponse, _, _),
             .dataLinkEntityNotFound(let httpResponse, _, _, _),
             .methodNotAllowed(let httpResponse, _, _, _),
             .unauthorized(let httpResponse, _, _, _, _),
             .invalidResponse(let httpResponse, _):
            return httpResponse
        default:
            return nil
        }
    }
    
    /// Response Header `X-Kinvey-Request-Id`
    public var requestId: String? {
        return httpResponse?.allHeaderFields[KinveyHeaderField.requestId] as? String
    }
    
    /// Response Data Body object.
    public var responseDataBody: Data? {
        switch self {
        case .unknownError(_, let data, _),
             .unknownJsonError(_, let data, _),
             .dataLinkEntityNotFound(_, let data, _, _),
             .methodNotAllowed(_, let data, _, _),
             .unauthorized(_, let data, _, _, _),
             .invalidResponse(_, let data),
             .missingConfiguration(_, let data, _, _):
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
    
    internal var responseBodyJsonDictionary: JsonDictionary? {
        if let data = responseDataBody,
            let jsonObject = try? JSONSerialization.jsonObject(with: data)
        {
            return jsonObject as? JsonDictionary
        }
        return nil
    }
    
}

/// Wrapper able to hold an array of `Swift.Error` objects.
public struct MultipleErrors: Swift.Error {
    
    public let errors: [Swift.Error]
    
}
