//
//  Result.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-04-11.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import Foundation

/// Enumeration that represents a result expected usually after an async call
public enum Result<SuccessType, FailureType> {
    
    /// Case when the result is a success result holding the succeed type value
    case success(SuccessType)
    
    /// Case when the result is a failure result holding the failure type value
    case failure(FailureType)
    
}
