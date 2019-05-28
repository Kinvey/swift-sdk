//
//  Kinvey.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import SwiftyBeaver

#if canImport(os)
import os
#endif

enum SignpostType {
    
    case event
    case begin
    case end
    
    @available(iOS 12.0, OSX 10.14, tvOS 12.0, watchOS 5.0, *)
    var osSignpostType: OSSignpostType {
        switch self {
        case .event:
            return .event
        case .begin:
            return .begin
        case .end:
            return .end
        }
    }
}

@inline(__always)
func signpost(_ type: SignpostType, dso: UnsafeRawPointer = #dsohandle, log: OSLog, name: StaticString) {
    if #available(iOS 12.0, OSX 10.14, tvOS 12.0, watchOS 5.0, *) {
        os_signpost(type.osSignpostType, log: log, name: name)
    }
}

@inline(__always)
func signpost(_ type: SignpostType, dso: UnsafeRawPointer = #dsohandle, log: OSLog, name: StaticString, _ format: StaticString, _ arguments: CVarArg...) {
    if #available(iOS 12.0, OSX 10.14, tvOS 12.0, watchOS 5.0, *) {
        os_signpost(type.osSignpostType, log: log, name: name, format, arguments)
    }
}

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
        var deviceId = keychain[.deviceId]
        if deviceId == nil {
            deviceId = UUID().uuidString
            keychain[.deviceId] = deviceId
        }
        return deviceId!
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
    
    #if DEBUG
    static let defaultLevel: LogLevel = .debug
    #else
    static let defaultLevel: LogLevel = .warning
    #endif
    
    internal var outputLevel: SwiftyBeaver.Level {
        switch self {
        case .verbose: return .verbose
        case .debug: return .debug
        case .info: return .info
        case .warning: return .warning
        case .error: return .error
        }
    }
    
}

extension SwiftyBeaver.Level {
    
    internal var logLevel: LogLevel {
        switch self {
        case .verbose: return .verbose
        case .debug: return .debug
        case .info: return .info
        case .warning: return .warning
        case .error: return .error
        }
    }
    
    internal var osLogType: OSLogType {
        switch self {
        case .verbose: return .default
        case .debug: return .debug
        case .info: return .info
        case .warning: return .info
        case .error: return .error
        }
    }
    
}

#if canImport(os)

internal let osLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? ProcessInfo.processInfo.processName, category: "Kinvey")

final class OSLogDestination : BaseDestination {
    
    override func send(
        _ level: SwiftyBeaver.Level,
        msg: String,
        thread: String,
        file: String,
        function: String,
        line: Int,
        context: Any?
    ) -> String? {
        if level.rawValue >= minLevel.rawValue {
            os_log(
                "%@.%@:%i - \n%@",
                log: osLog,
                type: level.osLogType,
                file,
                function,
                line,
                msg
            )
        }
        
        return super.send(
            level,
            msg: msg,
            thread: thread,
            file: file,
            function: function,
            line: line
        )
    }
    
}

#endif

let log: SwiftyBeaver.Type = {
    let logLevel = LogLevel.defaultLevel.outputLevel
    
    let console = ConsoleDestination()
    console.asynchronously = false
    console.levelColor.verbose  = "⚪️ "
    console.levelColor.debug    = "☑️ "
    console.levelColor.info     = "🔵 "
    console.levelColor.warning  = "🔶 "
    console.levelColor.error    = "🔴 "
    console.minLevel = logLevel
    SwiftyBeaver.addDestination(console)
    
    #if canImport(os)
    let osLog = OSLogDestination()
    osLog.asynchronously = false
    osLog.minLevel = logLevel
    SwiftyBeaver.addDestination(osLog)
    #endif
    
    return SwiftyBeaver.self
}()

func fatalError(_ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) -> Never  {
    let message = message()
    log.error(message)
    Swift.fatalError(message, file: file, line: line)
}

/// Level of logging used to log messages inside the Kinvey library
public var logLevel: LogLevel = LogLevel.defaultLevel {
    didSet {
        for destination in log.destinations {
            destination.minLevel = logLevel.outputLevel
        }
    }
}

public var jsonDecoder: JSONDecoder = {
    let jsonDecoder = JSONDecoder()
    jsonDecoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
        let dateString = try decoder.singleValueContainer().decode(String.self)
        guard let date = dateString.toDate() else {
            throw Error.invalidOperation(description: "\(dateString) is not date")
        }
        return date
    })
    return jsonDecoder
}()

public var jsonEncoder: JSONEncoder = {
    let jsonEncoder = JSONEncoder()
    jsonEncoder.dateEncodingStrategy = .custom({ (date, encoder) in
        var container = encoder.singleValueContainer()
        try container.encode(date.toISO8601())
    })
    return jsonEncoder
}()

public let defaultTag = "kinvey"
let groupId = "_group_"

#if swift(>=6)
    let swiftVersion = "6 or above"
#elseif swift(>=5.0)
    let swiftVersion = "5.0"
#elseif swift(>=4.2.4)
    let swiftVersion = "4.2.4"
#elseif swift(>=4.2.3)
    let swiftVersion = "4.2.3"
#elseif swift(>=4.2.2)
    let swiftVersion = "4.2.2"
#elseif swift(>=4.2.1)
    let swiftVersion = "4.2.1"
#elseif swift(>=4.2)
    let swiftVersion = "4.2"
#elseif swift(>=4.1.3)
    let swiftVersion = "4.1.3"
#elseif swift(>=4.1.2)
    let swiftVersion = "4.1.2"
#elseif swift(>=4.1.1)
    let swiftVersion = "4.1.1"
#elseif swift(>=4.1)
    let swiftVersion = "4.1"
#elseif swift(>=4.0.3)
    let swiftVersion = "4.0.3"
#elseif swift(>=4.0.2)
    let swiftVersion = "4.0.2"
#elseif swift(>=4.0)
    let swiftVersion = "4.0"
#elseif swift(>=3.1.1)
    let swiftVersion = "3.1.1"
#elseif swift(>=3.1)
    let swiftVersion = "3.1"
#elseif swift(>=3.0.2)
    let swiftVersion = "3.0.2"
#elseif swift(>=3.0.1)
    let swiftVersion = "3.0.1"
#elseif swift(>=3.0)
    let swiftVersion = "3.0"
#elseif swift(>=2.2.1)
    let swiftVersion = "2.2.1"
#elseif swift(>=2.2)
    let swiftVersion = "2.2"
#endif

#if os(macOS)
    let cacheBasePath: String = {
        if let xcTestConfigurationFilePath = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] {
            return URL(fileURLWithPath: xcTestConfigurationFilePath).deletingLastPathComponent().path
        } else {
            return URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!).appendingPathComponent(Bundle.main.bundleIdentifier ?? ProcessInfo.processInfo.processName).path
        }
    }()
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
    
    let json: [String : String]?
    if let data = data, let dictionary = try? client.jsonParser.parseDictionary(from: data) as? [String : String] {
        json = dictionary
    } else {
        json = nil
    }
    if let response = response,
        response.isUnauthorized,
        let json = json,
        let error = json["error"],
        let debug = json["debug"],
        let description = json["description"]
    {
        let refreshToken = client.activeUser?.socialIdentity?.kinvey?["refresh_token"] as? String
        if refreshToken == nil {
            client.activeUser?.logout()
        }
        switch error {
        case Error.Keys.invalidCredentials.rawValue:
            return Error.invalidCredentials(
                httpResponse: response.httpResponse,
                data: data,
                debug: debug,
                description: description
            )
        default:
            return Error.unauthorized(
                httpResponse: response.httpResponse,
                data: data,
                error: error,
                debug: debug,
                description: description
            )
        }
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
        let data = data,
        let json = try? client.jsonParser.parseDictionary(from: data),
        json[Entity.EntityCodingKeys.entityId] == nil
    {
        return Error.objectIdMissing
    } else if let response = response,
        response.isBadRequest,
        let json = json,
        json["error"] == Error.Keys.resultSetSizeExceeded.rawValue,
        let debug = json["debug"],
        let description = json["description"]
    {
        return Error.resultSetSizeExceeded(debug: debug, description: description)
    } else if let response = response,
        response.isBadRequest,
        let json = json,
        json["error"] == Error.Keys.parameterValueOutOfRange.rawValue,
        let debug = json["debug"],
        let description = json["description"]
    {
        return Error.parameterValueOutOfRange(debug: debug, description: description)
    } else if let response = response,
        response.isBadRequest,
        let json = json,
        json["error"] == Error.Keys.blRuntimeError.rawValue,
        let debug = json["debug"],
        let description = json["description"],
        let stack = json["stack"]
    {
        return Error.blRuntime(
            debug: debug,
            description: description,
            stack: stack.replacingOccurrences(of: "\\n", with: "\n")
        )
    } else if let response = response,
        response.isBadRequest,
        let json = json,
        json["error"] == Error.Keys.featureUnavailable.rawValue,
        let debug = json["debug"],
        let description = json["description"]
    {
        return Error.featureUnavailable(
            debug: debug,
            description: description
        )
    } else if let response = response,
        response.isNotFound,
        let json = json,
        json["error"] == Error.Keys.entityNotFound.rawValue,
        let debug = json["debug"],
        let description = json["description"]
    {
        return Error.entityNotFound(debug: debug, description: description)
    } else if let response = response,
        response.isInternalServerError,
        let json = json,
        json["error"] == Error.Keys.kinveyInternalErrorRetry.rawValue,
        let debug = json["debug"],
        let description = json["description"]
    {
        return Error.kinveyInternalErrorRetry(debug: debug, description: description)
    } else if let response = response,
        let data = data,
        let json = try? client.jsonParser.parseDictionary(from: data)
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

extension Sequence {
    
    func forEachAutoreleasepool(_ block: (Element) throws -> Swift.Void) rethrows {
        try forEach { x in
            try autoreleasepool {
                try block(x)
            }
        }
    }
    
}

func whileAutoreleasepool(_ condition: @autoclosure () -> Bool, _ block: () throws -> Void) rethrows {
    while autoreleasepool(invoking: condition) {
        try autoreleasepool {
            try block()
        }
    }
}

func errorRequest<S>(error: Swift.Error, completionHandler: ((Result<S, Swift.Error>) -> Void)? = nil) -> AnyRequest<Result<S, Swift.Error>> {
    let result: Result<S, Swift.Error> = .failure(error)
    if let completionHandler = completionHandler {
        DispatchQueue.main.async {
            completionHandler(result)
        }
    }
    return AnyRequest(result)
}
