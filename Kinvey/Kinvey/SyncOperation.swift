//
//  SyncOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-07.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class SyncOperation<T: Persistable, R, E>: Operation<T> where T: NSObject {
    
    internal typealias CompletionHandler = (R, E) -> Void
    
    let sync: AnySync?
    
    internal init(sync: AnySync?, cache: AnyCache<T>?, client: Client) {
        self.sync = sync
        super.init(cache: cache, client: client)
    }
    
}
