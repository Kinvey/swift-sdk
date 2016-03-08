//
//  Error.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

@objc
public enum Error: UInt, ErrorType {
    
    case ObjectIdMissing, InvalidResponse, NoActiveUser, RequestCanceled, InvalidStoreType
    
    var error:NSError {
        get {
            return self as NSError
        }
    }
    
}

@objc
public class __KNVError: NSObject {
    
    public static let ObjectIdMissing = Error.ObjectIdMissing.error
    public static let InvalidResponse = Error.InvalidResponse.error
    public static let NoActiveUser = Error.NoActiveUser.error
    public static let RequestCanceled = Error.RequestCanceled.error
    public static let InvalidStoreType = Error.InvalidStoreType.error
    
}
