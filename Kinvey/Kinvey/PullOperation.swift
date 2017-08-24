//
//  PullOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-08-11.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class PullOperation<T: Persistable>: FindOperation<T> where T: NSObject {
    
    override init(
        query: Query,
        deltaSet: Bool,
        deltaSetCompletionHandler: ((AnyRandomAccessCollection<T>) -> Void)?,
        autoPagination: Bool,
        readPolicy: ReadPolicy,
        cache: AnyCache<T>?,
        options: Options?,
        resultsHandler: ResultsHandler? = nil
    ) {
        super.init(
            query: query,
            deltaSet: deltaSet,
            deltaSetCompletionHandler: deltaSetCompletionHandler,
            autoPagination: autoPagination,
            readPolicy: readPolicy,
            cache: cache,
            options: options,
            resultsHandler: resultsHandler
        )
    }
    
    override var mustRemoveCachedRecords: Bool {
        return true
    }
    
}
