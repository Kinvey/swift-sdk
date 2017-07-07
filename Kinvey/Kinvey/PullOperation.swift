//
//  PullOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-08-11.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class PullOperation<T: Persistable>: FindOperation<T> where T: NSObject {
    
    override init(query: Query, deltaSet: Bool, deltaSetCompletionHandler: (([T]) -> Void)?, readPolicy: ReadPolicy, cache: AnyCache<T>?, client: Client, resultsHandler: ResultsHandler? = nil) {
        super.init(query: query, deltaSet: deltaSet, deltaSetCompletionHandler: deltaSetCompletionHandler, readPolicy: readPolicy, cache: cache, client: client, resultsHandler: resultsHandler)
    }
    
    override var mustRemoveCachedRecords: Bool {
        return true
    }
    
}
