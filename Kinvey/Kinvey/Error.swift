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
    
    /// Error when a Invalid Response coming from the backend.
    case InvalidResponse
    
    /// Error when a Unauthorized Response coming from the backend.
    case Unauthorized(error: String, description: String)
    
    /// Error when calls a method that requires an active user.
    case NoActiveUser
    
    /// Error when a request was cancelled.
    case RequestCanceled
    
    /// Error when calls a method not available for a specific data store type.
    case InvalidDataStoreType
    
    /// Error when a `User` doen't have an email or username.
    case UserWithoutEmailOrUsername
    
    var error: NSError {
        get {
            return self as NSError
        }
    }
    
    static func buildUnauthorized(json: [String : String]) -> Error {
        return Unauthorized(error: json["error"]!, description: json["description"]!)
    }
    
}
