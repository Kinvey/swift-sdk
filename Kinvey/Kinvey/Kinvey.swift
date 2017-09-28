//
//  Kinvey.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import XCGLogger

let ObjectIdTmpPrefix = "tmp_"

/**
 Shared client instance for simplicity. All methods that use a client will
 default to this instance. If you intend to use multiple backend apps or
 environments, you should override this default by providing a separate Client
 instance.
 */
public let sharedClient = Client.sharedClient

/// A once-per-installation value generated to give an ID for the running device
public let deviceId = Keychain().deviceId

fileprivate extension Keychain {
    
    var deviceId: String {
        get {
            guard let deviceId = keychain[.deviceId] else {
                let uuid = UUID().uuidString
                self.deviceId = uuid
                return uuid
            }
            return deviceId
        }
        set {
            keychain[.deviceId] = newValue
        }
    }
    
}

/**
 Define how detailed operations should be logged. Here's the ascending order
 (from the less detailed to the most detailed level): none, severe, error,
 warning, info, debug, verbose
 */
public enum LogLevel {
    
    /**
     Log operations that are useful if you are debugging giving aditional
     information. Most detailed level
     */
    case verbose
    
    /// Log operations that are useful if you are debugging
    case debug
    
    /// Log operations giving aditional information for basic operations
    case info
    
    /// Only log warning messages when needed
    case warning
    
    /// Only log error messages when needed
    case error
    
    /// Only log severe error messages when needed
    case severe
    
    /// Log is turned off
    case none
    
    internal var outputLevel: XCGLogger.Level {
        switch self {
        case .verbose: return .verbose
        case .debug: return .debug
        case .info: return .info
        case .warning: return .warning
        case .error: return .error
        case .severe: return .severe
        case .none: return .none
        }
    }
    
}

extension XCGLogger.Level {
    internal var logLevel: LogLevel {
        switch self {
        case .verbose: return .verbose
        case .debug: return .debug
        case .info: return .info
        case .warning: return .warning
        case .error: return .error
        case .severe: return .severe
        case .none: return .none
        }
    }
}

let log = XCGLogger.default

func fatalError(_ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) -> Never  {
    let message = message()
    log.severe(message)
    Swift.fatalError(message, file: file, line: line)
}

/// Level of logging used to log messages inside the Kinvey library
public var logLevel: LogLevel = log.outputLevel.logLevel {
    didSet {
        log.outputLevel = logLevel.outputLevel
    }
}

public let defaultTag = "kinvey"
let groupId = "_group_"

#if os(macOS)
    let cacheBasePath = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!).appendingPathComponent(Bundle.main.bundleIdentifier!).path
#else
    let cacheBasePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
#endif

func buildError(_ data: Data?, _ response: Response?, _ error: Swift.Error?, _ client: Client) -> Swift.Error {
    return buildError(data: data, response: response, error: error, client: client)
}

func buildError(client: Client) -> Swift.Error {
    return buildError(data: nil, response: nil, error: nil, client: client)
}

func buildError(
    data: Data?,
    response: Response?,
    error: Swift.Error?,
    client: Client
) -> Swift.Error {
    if let error = error {
        return error
    }
    
    let json = client.responseParser.parse(data) as? [String : String]
    if let response = response,
        response.isUnauthorized,
        let json = json,
        let error = json["error"],
        let debug = json["debug"],
        let description = json["description"]
    {
        return Error.unauthorized(
            httpResponse: response.httpResponse,
            data: data,
            error: error,
            debug: debug,
            description: description
        )
    } else if let response = response,
        response.isMethodNotAllowed,
        let json = json,
        let error = json["error"],
        error == "MethodNotAllowed",
        let debug = json["debug"],
        let description = json["description"]
    {
        return Error.methodNotAllowed(
            httpResponse: response.httpResponse,
            data: data,
            debug: debug,
            description: description
        )
    } else if let response = response,
        response.isNotFound,
        let json = json,
        json["error"] == "DataLinkEntityNotFound",
        let debug = json["debug"],
        let description = json["description"]
    {
        return Error.dataLinkEntityNotFound(
            httpResponse: response.httpResponse,
            data: data,
            debug: debug,
            description: description
        )
    } else if let response = response,
        response.isForbidden,
        let json = json,
        let error = json["error"],
        error == "MissingConfiguration",
        let debug = json["debug"],
        let description = json["description"]
    {
        return Error.missingConfiguration(
            httpResponse: response.httpResponse,
            data: data,
            debug: debug,
            description: description
        )
    } else if let response = response,
        response.isNotFound,
        let json = json,
        json["error"] == "AppNotFound",
        let description = json["description"]
    {
        return Error.appNotFound(description: description)
    } else if let response = response,
        response.isOK,
        let json = client.responseParser.parse(data),
        json[Entity.Key.entityId] == nil
    {
        return Error.objectIdMissing
    } else if let response = response,
        response.isBadRequest,
        let json = json,
        json["error"] == Error.ResultSetSizeExceeded,
        let debug = json["debug"],
        let description = json["description"]
    {
        return Error.resultSetSizeExceeded(debug: debug, description: description)
    } else if let response = response,
        let json = client.responseParser.parse(data)
    {
        return Error.unknownJsonError(
            httpResponse: response.httpResponse,
            data: data,
            json: json
        )
    }
    return Error.invalidResponse(
        httpResponse: response?.httpResponse,
        data: data
    )
}
