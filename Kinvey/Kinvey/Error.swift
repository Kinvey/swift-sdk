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
        
        /// Constant for 400 response where the paremeter value is out of range
        case parameterValueOutOfRange = "ParameterValueOutOfRange"
        
        /// Constant for 400 response where the parameter value is a BL runtime error
        case blRuntimeError = "BLRuntimeError"
        
        /// Constant for 400 response where the feature is not available
        case featureUnavailable = "FeatureUnavailable"
        
        /// Constant for 500 response where an internal error happened and another request should be made to retry
        case kinveyInternalErrorRetry = "KinveyInternalErrorRetry"
        
    }
    
    /// Error where Object ID is required.
    case objectIdMissing
    
    /// Error when a method is not allowed, usually when you are using a Data Link Connector (DLC).
    case methodNotAllowed(httpResponse: HTTPURLResponse?, data: Data?, debug: String, description: String)
    
    /// Error when a Data Link endpoint is not found, usually when you are using a Data Link Connector (DLC).
    case dataLinkEntityNotFound(httpResponse: HTTPURLResponse?, data: Data?, debug: String, description: String)
    
    /// Error when there's a missing configuration in the backend.
    case missingConfiguration(httpResponse: HTTPURLResponse?, data: Data?, debug: String, description: String)
    
    /// Error when a request parameter is missing
    case missingRequestParameter(httpResponse: HTTPURLResponse?, data: Data?, debug: String, description: String)
    
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
    
    /// Error when an entity was not found using the entity id provided
    case entityNotFound(debug: String, description: String)
    
    /// Error when the value prodived for a parameter is out of range
    case parameterValueOutOfRange(debug: String, description: String)
    
    case invalidCredentials(httpResponse: HTTPURLResponse?, data: Data?, debug: String, description: String)
    case insufficientCredentials(httpResponse: HTTPURLResponse?, data: Data?, debug: String, description: String)
    
    case badRequest(httpResponse: HTTPURLResponse?, data: Data?, description: String)
    
    /// Error handling OAuth errors in redirect uri responses
    case micAuth(error: String, description: String)
    
    /// Error when a BL (Business Logic) Runtime Error occurs
    case blRuntime(debug: String, description: String, stack: String)
    
    /// Error when a feature is not available
    case featureUnavailable(debug: String, description: String)
    
    case kinveyInternalErrorRetry(debug: String, description: String)
    
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
             .missingRequestParameter(_, _, _, let description),
             .appNotFound(let description),
             .forbidden(let description),
             .resultSetSizeExceeded(_, let description),
             .entityNotFound(_, let description),
             .parameterValueOutOfRange(_, let description),
             .invalidCredentials(_, _, _, let description),
             .insufficientCredentials(_, _, _, let description),
             .micAuth(_, let description),
             .blRuntime(_, let description, _),
             .featureUnavailable(_, let description),
             .kinveyInternalErrorRetry(_, let description),
             .badRequest(_, _, let description):
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
             .missingRequestParameter(_, _, let debug, _),
             .unauthorized(_, _, _, let debug, _),
             .resultSetSizeExceeded(let debug, _),
             .entityNotFound(let debug, _),
             .parameterValueOutOfRange(let debug, _),
             .invalidCredentials(_, _, let debug, _),
             .insufficientCredentials(_, _, let debug, _),
             .blRuntime(let debug, _, _),
             .featureUnavailable(let debug, _),
             .kinveyInternalErrorRetry(let debug, _):
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
             .invalidResponse(let httpResponse, _),
             .invalidCredentials(let httpResponse, _, _, _),
             .insufficientCredentials(let httpResponse, _, _, _),
             .missingConfiguration(let httpResponse, _, _, _),
             .missingRequestParameter(let httpResponse, _, _, _),
             .badRequest(let httpResponse, _, _):
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
             .missingConfiguration(_, let data, _, _),
             .missingRequestParameter(_, let data, _, _),
             .invalidCredentials(_, let data, _, _),
             .insufficientCredentials(_, let data, _, _),
             .badRequest(_, let data, _):
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

protocol FailureError: Swift.Error {
    
    associatedtype Failure
    
    var failure: Failure { get }
    
}

/// Wrapper able to hold an array of `Swift.Error` objects.
public struct MultipleErrors {
    
    public let errors: [Swift.Error]
    
}

extension MultipleErrors: FailureError {
    
    typealias Failure = [Element]
    
    var failure: [Element] {
        return errors
    }
    
}

extension MultipleErrors: RandomAccessCollection {
    public typealias Element = Swift.Error
    
    public typealias Index = Array<Element>.Index
    
    public typealias Indices = Array<Element>.Indices
    
    public typealias SubSequence = Array<Element>.SubSequence
    
    public subscript(position: Index) -> Element {
        precondition(indices.contains(position), "out of bounds")
        return errors[position]
    }
    
    public subscript(bounds: Range<Int>) -> SubSequence {
         precondition(startIndex <= bounds.lowerBound &&
                      bounds.lowerBound <= bounds.upperBound &&
                      bounds.upperBound <= endIndex,
                      "indices out of bounds")
         return ArraySlice(errors[bounds])
     }
    
    public func index(after i: Index) -> Index {
      return errors.index(after: i)
    }
    
    public var startIndex: Index {
        return errors.startIndex
    }
    
    public var endIndex: Index {
        return errors.endIndex
    }
    
    public var indices: Array<Element>.Indices {
        return errors.indices
    }
}

extension MultipleErrors: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        return localizedDescription
    }
    
    public var debugDescription: String {
        return localizedDescription
    }
    
    public var localizedDescription: String {
        return errors.map { $0.localizedDescription }.joined(separator: "\n")
    }
    
}

struct NilError: FailureError {
    
    typealias Failure = Any?
    
    let failure: Any?
    
}

extension NSException {
    
    public convenience init(error: Swift.Error) {
        self.init(error: error as NSError)
    }
    
    public convenience init(error: NSError) {
        self.init(name: NSExceptionName(rawValue: error.domain), reason: error.localizedFailureReason, userInfo: error.userInfo)
    }
    
}

public struct MultiSaveError: Swift.Error, Codable, IndexableError {
    
    public let index: Int
    public let error: String
    public let serverDescription: String?
    public let serverDebug: String?

    enum CodingKeys: String, CodingKey {
        case index
        case error
        case serverDescription = "description"
        case serverDebug = "debug"
    }
    
    public var localizedDescription: String {
        return self.serverDescription != nil ? self.serverDescription! : error
    }
    
}

extension MultiSaveError: LocalizedError {
    
    public var errorDescription: String? {
        return localizedDescription
    }
    
    public var failureReason: String? {
        return localizedDescription
    }
    
    public var recoverySuggestion: String? {
        return localizedDescription
    }
    
    public var helpAnchor: String? {
        return localizedDescription
    }
    
}
    
extension MultiSaveError: CustomStringConvertible {
    
    public var description: String {
        return localizedDescription
    }
    
}
    
extension MultiSaveError: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return localizedDescription
    }
    
}

public struct IndexedError: Swift.Error, IndexableError {
    
    public let index: Int
    public let error: Swift.Error
    
    public var localizedDescription: String {
        return error.localizedDescription
    }
    
}

extension IndexedError: LocalizedError {
    
    private var localizedError: LocalizedError? {
        return error as? LocalizedError
    }
    
    public var errorDescription: String? {
        return localizedError?.errorDescription
    }
    
    public var failureReason: String? {
        return localizedError?.failureReason
    }
    
    public var recoverySuggestion: String? {
        return localizedError?.recoverySuggestion
    }
    
    public var helpAnchor: String? {
        return localizedError?.helpAnchor
    }
    
}

extension IndexedError: CustomStringConvertible {
    
    public var description: String {
        return (error as CustomStringConvertible).description
    }
    
}

extension IndexedError: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return (error as CustomDebugStringConvertible).debugDescription
    }
    
}

public protocol IndexableError: Swift.Error {
    
    var index: Int { get }
    
}
