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
    case MethodNotAllowed(debug: String, description: String)
    
    /// Error when a Data Link endpoint is not found, usually when you are using a Data Link Connector (DLC).
    case DataLinkEntityNotFound(debug: String, description: String)
    
    /// Error when the type is unknow.
    case UnknownError(error: String)
    
    /// Error when the type is unknow.
    case UnknownJsonError(json: [String : AnyObject])
    
    /// Error when a Invalid Response coming from the backend.
    case InvalidResponse
    
    /// Error when a Unauthorized Response coming from the backend.
    case Unauthorized(error: String, description: String)
    
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
        get {
            return self as NSError
        }
    }
    
    /// Error localized description.
    public var localizedDescription: String {
        get {
            let bundle = NSBundle(forClass: Client.self)
            switch self {
            case .Unauthorized(_, let description):
                return description
            case .InvalidOperation(let description):
                return description
            default:
                return NSLocalizedString("Error.\(self)", bundle: bundle, comment: "")
            }
        }
    }
    
    static func buildUnknownError(error: String) -> Error {
        return UnknownError(error: error)
    }
    
    static func buildUnknownJsonError(json: [String : AnyObject]) -> Error {
        return UnknownJsonError(json: json)
    }
    
    static func buildDataLinkEntityNotFound(json: [String : String]) -> Error {
        return DataLinkEntityNotFound(debug: json["debug"]!, description: json["description"]!)
    }
    
    static func buildMethodNotAllowed(json: [String : String]) -> Error {
        return MethodNotAllowed(debug: json["debug"]!, description: json["description"]!)
    }
    
    static func buildUnauthorized(json: [String : String]) -> Error {
        return Unauthorized(error: json["error"]!, description: json["description"]!)
    }
    
}