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
        deltaSetCompletionHandler: ((AnyRandomAccessCollection<T>, AnyRandomAccessCollection<T>) -> Void)?,
        autoPagination: Bool,
        readPolicy: ReadPolicy,
        validationStrategy: ValidationStrategy?,
        cache: AnyCache<T>?,
        options: Options?,
        mustSetRequestResult: Bool = true,
        mustSaveQueryLastSync: Bool? = nil,
        resultsHandler: ResultsHandler? = nil
    ) {
        super.init(
            query: query,
            deltaSet: deltaSet,
            deltaSetCompletionHandler: deltaSetCompletionHandler,
            autoPagination: autoPagination,
            readPolicy: readPolicy,
            validationStrategy: validationStrategy,
            cache: cache,
            options: options,
            mustSetRequestResult: mustSetRequestResult,
            mustSaveQueryLastSync: mustSaveQueryLastSync,
            resultsHandler: resultsHandler
        )
    }
    
    override var mustRemoveCachedRecords: Bool {
        return true
    }
    
}
