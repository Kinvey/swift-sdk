//
//  Kinvey.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import XCGLogger

/// Key to map the `_id` column in your Persistable implementation class.
public let PersistableIdKey = "_id"

/// Key to map the `_acl` column in your Persistable implementation class.
public let PersistableAclKey = "_acl"

/// Key to map the `_kmd` column in your Persistable implementation class.
public let PersistableMetadataKey = "_kmd"

let PersistableMetadataLastRetrievedTimeKey = "lrt"
let ObjectIdTmpPrefix = "tmp_"

/// Shared client instance for simplicity. Use this instance if *you don't need* to handle with multiple Kinvey environments.
public let sharedClient = Client.sharedClient

public enum LogLevel {
    
    case verbose, debug, info, warning, error, severe, none
    
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

/// Level of logging used to log messages inside the Kinvey library
public var logLevel: LogLevel = .warning {
    didSet {
        log.outputLevel = logLevel.outputLevel
    }
}

let defaultTag = "kinvey"

let userDocumentDirectory: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!

func buildError(_ data: Data?, _ response: URLResponse?, _ error: Swift.Error?, _ client: Client) -> Swift.Error {
    return buildError(data: data, urlResponse: response, error: error, client: client)
}

func buildError(data: Data?, urlResponse: URLResponse?, error: Swift.Error?, client: Client) -> Swift.Error {
    return buildError(data: data, response: HttpResponse(response: urlResponse), error: error, client: client)
}

func buildError(_ data: Data?, _ response: Response?, _ error: Swift.Error?, _ client: Client) -> Swift.Error {
    return buildError(data: data, response: response, error: error, client: client)
}

func buildError(client: Client) -> Swift.Error {
    return buildError(data: nil, response: nil, error: nil, client: client)
}

func buildError(data: Data?, response: Response?, error: Swift.Error?, client: Client) -> Swift.Error {
    if let error = error {
        return error
    } else if let response = response , response.isUnauthorized,
        let json = client.responseParser.parse(data) as? [String : String]
    {
        return Error.buildUnauthorized(httpResponse: response.httpResponse, data: data, json: json)
    } else if let response = response, response.isMethodNotAllowed, let json = client.responseParser.parse(data) as? [String : String] , json["error"] == "MethodNotAllowed" {
        return Error.buildMethodNotAllowed(httpResponse: response.httpResponse, data: data, json: json)
    } else if let response = response, response.isNotFound, let json = client.responseParser.parse(data) as? [String : String] , json["error"] == "DataLinkEntityNotFound" {
        return Error.buildDataLinkEntityNotFound(httpResponse: response.httpResponse, data: data, json: json)
    } else if let response = response,
        response.isForbidden,
        let json = client.responseParser.parse(data) as? [String : String],
        let error = json["error"],
        error == "MissingConfiguration",
        let debug = json["debug"],
        let description = json["description"]
    {
        return Error.missingConfiguration(httpResponse: response.httpResponse, data: data, debug: debug, description: description)
    } else if let response = response,
        response.isNotFound,
        let json = client.responseParser.parse(data) as? [String : String],
        json["error"] == "AppNotFound",
        let description = json["description"]
    {
        return Error.appNotFound(description: description)
    } else if let response = response, let json = client.responseParser.parse(data) {
        return Error.buildUnknownJsonError(httpResponse: response.httpResponse, data: data, json: json)
    } else {
        return Error.invalidResponse(httpResponse: response?.httpResponse, data: data)
    }
}
