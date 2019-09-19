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

protocol SaveOperationType: WriteOperationType {
    
    var localSuccess: SuccessType { get }
    
}

extension SaveOperationType {
    
    func execute(_ completionHandler: CompletionHandler?) -> AnyRequest<Result<SuccessType, FailureType>> {
        switch writePolicy {
        case .silentLocalThenNetwork:
            executeLocal(nil)
            return executeNetwork {
                switch $0 {
                case .success(let success):
                    completionHandler?(.success(success))
                case .failure(let failure):
                    if let error = failure as? Kinvey.Error,
                        let httpResponse = error.httpResponse,
                        httpResponse.statusCode == 401
                    {
                        completionHandler?(.failure(failure))
                        return
                    }
                    log.error(failure)
                    completionHandler?(.success(self.localSuccess))
                }
            }
        default:
            return AnyWriteOperationType(self).execute(completionHandler)
        }
    }
    
}

protocol WriteOperationType {
    
    associatedtype SuccessType
    associatedtype FailureType: Swift.Error
    typealias CompletionHandler = (Result<SuccessType, FailureType>) -> Void
    
    var writePolicy: WritePolicy { get }
    
    @discardableResult
    func executeLocal(_ completionHandler: CompletionHandler?) -> AnyRequest<Result<SuccessType, FailureType>>
    
    @discardableResult
    func executeNetwork(_ completionHandler: CompletionHandler?) -> AnyRequest<Result<SuccessType, FailureType>>
    
}

extension WriteOperationType {
    
    @discardableResult
    func execute(_ completionHandler: CompletionHandler?) -> AnyRequest<Result<SuccessType, FailureType>> {
        switch writePolicy {
        case .forceLocal:
            return executeLocal(completionHandler)
        case .silentLocalThenNetwork:
            executeLocal(nil)
            return executeNetwork(completionHandler)
        case .localThenNetwork:
            executeLocal(completionHandler)
            fallthrough
        case .forceNetwork:
            return executeNetwork(completionHandler)
        }
    }
    
}

class AnyWriteOperationType<Success, Failure> : WriteOperationType where Failure: Swift.Error {
    
    typealias SuccessType = Success
    typealias FailureType = Failure
    
    var writePolicy: WritePolicy {
        return _getWritePolicy()
    }
    
    private let _getWritePolicy: () -> WritePolicy
    private let _executeLocal: (CompletionHandler?) -> AnyRequest<Result<Success, Failure>>
    private let _executeNetwork: (CompletionHandler?) -> AnyRequest<Result<Success, Failure>>
    
    init<T>(_ instance: T) where T: WriteOperationType, T.SuccessType == Success, T.FailureType == Failure {
        _getWritePolicy = { instance.writePolicy }
        _executeLocal = instance.executeLocal(_:)
        _executeNetwork = instance.executeNetwork(_:)
    }
    
    func executeLocal(_ completionHandler: CompletionHandler?) -> AnyRequest<Result<Success, Failure>> {
        return _executeLocal(completionHandler)
    }
    
    func executeNetwork(_ completionHandler: CompletionHandler?) -> AnyRequest<Result<Success, Failure>> {
        return _executeNetwork(completionHandler)
    }
    
}
