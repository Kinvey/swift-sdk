//
//  Result.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-04-11.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import Foundation
import PromiseKit

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
extension Swift.Result {

    /// Returns the `SuccessType` if the result is a `.success`, otherwise throws the `.failure` error
    @available(*, deprecated, message: "Deprecated in version 3.25.0. Please use get() instead")
    public func value() throws -> Success {
        return try get()
    }

}

extension Swift.Result where Failure == Swift.Error {
    
    init(_ result: PromiseKit.Result<Success>) {
        switch result {
        case .fulfilled(let result):
            self = .success(result)
        case .rejected(let error):
            self = .failure(error)
        }
    }
    
}

extension PromiseKit.Result {
    
    init(_ result: Swift.Result<T, Swift.Error>) {
        switch result {
        case .success(let result):
            self = .fulfilled(result)
        case .failure(let error):
            self = .rejected(error)
        }
    }
    
}

extension Resolver {

    func resolve(_ result: Swift.Result<T, Swift.Error>) {
        resolve(PromiseKit.Result(result))
    }
    
    func completionHandler() -> (Swift.Result<T, Swift.Error>) -> Void {
        return {
            self.resolve($0)
        }
    }
    
}
