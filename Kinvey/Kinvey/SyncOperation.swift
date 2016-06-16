//
//  SyncOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-07.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class SyncOperation<T: Persistable, R, E where T: NSObject>: Operation<T> {
    
    internal typealias CompletionHandler = (R, E) -> Void
    
    let sync: Sync
    
    internal init(sync: Sync, cache: Cache<T>, client: Client) {
        self.sync = sync
        super.init(cache: cache, client: client)
    }
    
    func execute(timeout timeout: NSTimeInterval? = nil, completionHandler: CompletionHandler?) -> Request {
        preconditionFailure("Method needs to be implemented")
    }
    
}
