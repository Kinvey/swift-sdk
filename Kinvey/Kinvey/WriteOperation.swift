//
//  WriteOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

@objc(__KNVWriteOperation)
public class WriteOperation: Operation {
    
    typealias CompletionHandler = (AnyObject?, ErrorType?) -> Void
    
    let writePolicy: WritePolicy
    let sync: Sync
    
    init(writePolicy: WritePolicy, sync: Sync, persistableType: Persistable.Type, cache: Cache, client: Client) {
        self.writePolicy = writePolicy
        self.sync = sync
        super.init(persistableType: persistableType, cache: cache, client: client)
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
