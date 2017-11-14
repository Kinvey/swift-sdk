//
//  WriteOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class WriteOperation<T: Persistable, R>: Operation<T> where T: NSObject {
    
    typealias CompletionHandler = (Result<R, Swift.Error>) -> Void
    
    let writePolicy: WritePolicy
    let sync: AnySync?
    
    init(
        writePolicy: WritePolicy,
        sync: AnySync? = nil,
        cache: AnyCache<T>? = nil,
        options: Options?
    ) {
        self.writePolicy = writePolicy
        self.sync = sync
        super.init(
            cache: cache,
            options: options
        )
    }
    
}

protocol WriteOperationType {
    
    associatedtype SuccessType
    associatedtype FailureType
    typealias CompletionHandler = (Result<SuccessType, FailureType>) -> Void
    
    var writePolicy: WritePolicy { get }
    
    @discardableResult
    func executeLocal(_ completionHandler: CompletionHandler?) -> BaseRequest
    
    @discardableResult
    func executeNetwork(_ completionHandler: CompletionHandler?) -> BaseRequest
    
}

extension WriteOperationType {
    
    @discardableResult
    func execute(_ completionHandler: CompletionHandler?) -> BaseRequest {
        switch writePolicy {
        case .forceLocal:
            return executeLocal(completionHandler)
        case .localThenNetwork:
            executeLocal(completionHandler)
            fallthrough
        case .forceNetwork:
            return executeNetwork(completionHandler)
        }
    }
    
}
