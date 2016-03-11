//
//  SyncOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-07.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

@objc(__KNVSyncOperation)
public class SyncOperation: Operation {
    
    typealias CompletionHandler = (AnyObject?, ErrorType?) -> Void
    
    let sync: Sync
    
    public init(sync: Sync, persistableType: Persistable.Type, cache: Cache, client: Client) {
        self.sync = sync
        super.init(persistableType: persistableType, cache: cache, client: client)
    }
    
    func execute(completionHandler: CompletionHandler?) -> Request {
        preconditionFailure("Method needs to be implemented")
    }
    
}
