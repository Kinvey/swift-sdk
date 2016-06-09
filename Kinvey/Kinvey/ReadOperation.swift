//
//  ReadOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class ReadOperation<T: Persistable, R>: Operation<T> {
    
    typealias CompletionHandler = (R, ErrorType?) -> Void
    
    let readPolicy: ReadPolicy
    
    init(readPolicy: ReadPolicy, cache: Cache, client: Client) {
        self.readPolicy = readPolicy
        super.init(cache: cache, client: client)
    }
    
    func execute(completionHandler: CompletionHandler? = nil) -> Request {
        switch readPolicy {
        case .ForceLocal:
            return executeLocal(completionHandler)
        case .ForceNetwork:
            return executeNetwork(completionHandler)
        case .Both:
            let request = MultiRequest()
            executeLocal() { obj, error in
                completionHandler?(obj, nil)
                request.addRequest(self.executeNetwork(completionHandler))
            }
            return request
        }
    }
    
    func executeLocal(completionHandler: CompletionHandler?) -> Request {
        preconditionFailure("Method needs to be implemented")
    }
    
    func executeNetwork(completionHandler: CompletionHandler?) -> Request {
        preconditionFailure("Method needs to be implemented")
    }
    
}
