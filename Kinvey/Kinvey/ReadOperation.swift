//
//  ReadOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class ReadOperation<T: Persistable, R, E>: Operation<T> where T: NSObject {
    
    typealias CompletionHandler = (Result<R, E>) -> Void
    
    let readPolicy: ReadPolicy
    let validationStrategy: ValidationStrategy?
    
    init(
        readPolicy: ReadPolicy,
        validationStrategy: ValidationStrategy?,
        cache: AnyCache<T>?,
        options: Options?
    ) {
        self.readPolicy = readPolicy
        self.validationStrategy = validationStrategy
        super.init(
            cache: cache,
            options: options
        )
    }
    
}

protocol ReadOperationType {
    
    associatedtype SuccessType
    associatedtype FailureType
    typealias CompletionHandler = (Result<SuccessType, FailureType>) -> Void
    
    var readPolicy: ReadPolicy { get }
    
    @discardableResult
    func executeLocal(_ completionHandler: CompletionHandler?) -> BasicRequest
    
    @discardableResult
    func executeNetwork(_ completionHandler: CompletionHandler?) -> BasicRequest
    
}

extension ReadOperationType {
    
    @discardableResult
    func execute(_ completionHandler: CompletionHandler? = nil) -> BasicRequest {
        switch readPolicy {
        case .forceLocal:
            return executeLocal(completionHandler)
        case .forceNetwork:
            return executeNetwork(completionHandler)
        case .both:
            let request = MultiRequest<Any>()
            executeLocal() { result in
                completionHandler?(result)
                request.addRequest(self.executeNetwork(completionHandler))
            }
            return request
        }
    }
    
}
