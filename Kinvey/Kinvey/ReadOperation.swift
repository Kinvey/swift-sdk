//
//  ReadOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class ReadOperation<T: Persistable, R, E>: Operation<T> where T: NSObject, E: Swift.Error {
    
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
    associatedtype FailureType: Swift.Error
    typealias CompletionHandler = (Result<SuccessType, FailureType>) -> Void
    
    var readPolicy: ReadPolicy { get }
    
    @discardableResult
    func executeLocal(_ completionHandler: CompletionHandler?) -> AnyRequest<Result<SuccessType, FailureType>>
    
    @discardableResult
    func executeNetwork(_ completionHandler: CompletionHandler?) -> AnyRequest<Result<SuccessType, FailureType>>
    
}

extension ReadOperationType {
    
    @discardableResult
    func execute(_ completionHandler: CompletionHandler? = nil) -> AnyRequest<Result<SuccessType, FailureType>> {
        switch readPolicy {
        case .forceLocal:
            return executeLocal(completionHandler)
        case .forceNetwork:
            return executeNetwork(completionHandler)
        case .both:
            let request = MultiRequest<Result<SuccessType, FailureType>>()
            executeLocal() { result in
                completionHandler?(result)
                request.addRequest(self.executeNetwork(completionHandler))
            }
            return AnyRequest(request)
        case .networkOtherwiseLocal:
            let requests = MultiRequest<Result<SuccessType, FailureType>>()
            let networkRequest = executeNetwork() {
                switch $0 {
                case .success:
                    completionHandler?($0)
                case .failure(let error):
                    guard let error = error as? Kinvey.Error else {
                        requests.addRequest(self.executeLocal(completionHandler))
                        return
                    }
                    switch error {
                    case .methodNotAllowed(let httpResponse, _, _, _),
                         .dataLinkEntityNotFound(let httpResponse, _, _, _),
                         .missingConfiguration(let httpResponse, _, _, _),
                         .missingRequestParameter(let httpResponse, _, _, _),
                         .unknownError(let httpResponse, _, _),
                         .unknownJsonError(let httpResponse, _, _),
                         .invalidResponse(let httpResponse, _),
                         .unauthorized(let httpResponse, _, _, _, _),
                         .invalidCredentials(let httpResponse, _, _, _):
                        guard let httpResponse = httpResponse else {
                            fallthrough
                        }
                        switch httpResponse.statusCode {
                        case 400 ..< 600:
                            completionHandler?($0)
                        default:
                            requests.addRequest(self.executeLocal(completionHandler))
                        }
                    default:
                        requests.addRequest(self.executeLocal(completionHandler))
                    }
                }
            }
            requests.addRequest(networkRequest)
            return AnyRequest(requests)
        }
    }
    
}
