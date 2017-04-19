//
//  WriteOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class WriteOperation<T: Persistable, R>: Operation<T> where T: NSObject {
    
    typealias CompletionHandler = (R, Swift.Error?) -> Void
    
    let writePolicy: WritePolicy
    let sync: AnySync?
    
    init(writePolicy: WritePolicy, sync: AnySync? = nil, cache: AnyCache<T>? = nil, client: Client) {
        self.writePolicy = writePolicy
        self.sync = sync
        super.init(cache: cache, client: client)
    }
    
    @discardableResult
    func execute(_ completionHandler: CompletionHandler?) -> Request {
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
    
    @discardableResult
    func executeLocal(_ completionHandler: CompletionHandler?) -> Request {
        let message = "Method \(#function) must be overridden"
        log.severe(message)
        fatalError(message)
    }
    
    @discardableResult
    func executeNetwork(_ completionHandler: CompletionHandler?) -> Request {
        let message = "Method \(#function) must be overridden"
        log.severe(message)
        fatalError(message)
    }
    
}
