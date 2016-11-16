//
//  ObjC.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-04.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

@objc(__KNVError)
internal class KinveyError: NSObject {
    
    internal static let ObjectIdMissing = Error.objectIdMissing.error
    internal static let NoActiveUser = Error.noActiveUser.error
    internal static let RequestCancelled = Error.requestCancelled.error
    internal static let InvalidDataStoreType = Error.invalidDataStoreType.error
    
    fileprivate override init() {
    }
    
    internal static func buildUnknownError(httpResponse: HTTPURLResponse?, data: Data?, error: String) -> NSError {
        return Error.buildUnknownError(httpResponse: httpResponse, data: data, error: error).error
    }
    
    internal static func buildUnknownJsonError(httpResponse: HTTPURLResponse?, data: Data?, json: [String : Any]) -> NSError {
        return Error.buildUnknownJsonError(httpResponse: httpResponse, data: data, json: json).error
    }
    
    internal static func buildInvalidResponse(httpResponse: HTTPURLResponse?, data: Data?) -> NSError {
        return Error.invalidResponse(httpResponse: httpResponse, data: data).error
    }
    
}
