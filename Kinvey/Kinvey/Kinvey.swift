//
//  Kinvey.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

/// Key to map the `_id` column in your Persistable implementation class.
public let PersistableIdKey = "_id"

/// Key to map the `_acl` column in your Persistable implementation class.
public let PersistableAclKey = "_acl"

/// Key to map the `_kmd` column in your Persistable implementation class.
public let PersistableMetadataKey = "_kmd"

let PersistableMetadataLastRetrievedTimeKey = "lrt"
let ObjectIdTmpPrefix = "tmp_"

typealias PendingOperationIMP = RealmPendingOperation

/// Shared client instance for simplicity. Use this instance if *you don't need* to handle with multiple Kinvey environments.
public let sharedClient = Client.sharedClient

let defaultTag = "kinvey"

let userDocumentDirectory: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!

func buildError(_ data: Data?, _ response: URLResponse?, _ error: Swift.Error?, _ client: Client) -> Swift.Error {
    return buildError(data, HttpResponse(response: response), error, client)
}

func buildError(_ data: Data?, _ response: Response?, _ error: Swift.Error?, _ client: Client) -> Swift.Error {
    if let error = error {
        return error
    } else if let response = response , response.isUnauthorized,
        let json = client.responseParser.parse(data) as? [String : String]
    {
        return Error.buildUnauthorized(httpResponse: response.httpResponse, data: data, json: json)
    } else if let response = response , response.isMethodNotAllowed, let json = client.responseParser.parse(data) as? [String : String] , json["error"] == "MethodNotAllowed" {
        return Error.buildMethodNotAllowed(httpResponse: response.httpResponse, data: data, json: json)
    } else if let response = response , response.isNotFound, let json = client.responseParser.parse(data) as? [String : String] , json["error"] == "DataLinkEntityNotFound" {
        return Error.buildDataLinkEntityNotFound(httpResponse: response.httpResponse, data: data, json: json)
    } else if let response = response, let json = client.responseParser.parse(data) {
        return Error.buildUnknownJsonError(httpResponse: response.httpResponse, data: data, json: json)
    } else {
        return Error.invalidResponse(httpResponse: response?.httpResponse, data: data)
    }
}
