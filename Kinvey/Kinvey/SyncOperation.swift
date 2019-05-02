//
//  SyncOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-07.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class SyncOperation<T: Persistable, R, E>: Operation<T> where T: NSObject, E: Swift.Error {
    
    internal typealias CompletionHandler = (Result<R, E>) -> Void
    
    let sync: AnySync?
    
    internal init(
        sync: AnySync?,
        cache: AnyCache<T>?,
        options: Options?
    ) {
        self.sync = sync
        super.init(
            cache: cache,
            options: options
        )
    }
    
}
