//
//  Result.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-04-11.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import Foundation

/**
 Swift.Result is a Enumeration that represents the result of an operation.
 Here's a sample code how to handle a `Result`
 ```
switch result {
case .success(let successObject):
    print("here you should handle the success case")
case .failure(let failureObject):
    print("here you should handle the failure case")
}
 ```
 */
extension Result {

    /// Returns the `SuccessType` if the result is a `.success`, otherwise throws the `.failure` error
    @available(*, deprecated, message: "Deprecated in version 3.25.0. Please use get() instead")
    public func value() throws -> Success {
        return try get()
    }

}
