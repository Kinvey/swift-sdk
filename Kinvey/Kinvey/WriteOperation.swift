//
//  WriteOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class WriteOperation<T: Persistable, R where T: NSObject>: Operation<T> {
    
    typealias CompletionHandler = (R, ErrorType?) -> Void
    
    let writePolicy: WritePolicy
    let sync: Sync?
    
    init(writePolicy: WritePolicy, sync: Sync? = nil, cache: Cache<T>? = nil, client: Client) {
        self.writePolicy = writePolicy
        self.sync = sync
        super.init(cache: cache, client: client)
    }
    
    func execute(completionHandler: CompletionHandler?) -> Request {
        switch writePolicy {
        case .ForceLocal:
            return executeLocal(completionHandler)
        case .LocalThenNetwork:
            executeLocal(completionHandler)
            fallthrough
        case .ForceNetwork:
            return executeNetwork(completionHandler)
        }
    }
    
    func executeLocal(completionHandler: CompletionHandler?) -> Request {
        preconditionFailure("Method needs to be implemented")
    }
    
    func executeNetwork(completionHandler: CompletionHandler?) -> Request {
        preconditionFailure("Method needs to be implemented")
    }
    
}
