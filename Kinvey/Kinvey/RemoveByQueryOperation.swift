//
//  RemoveOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class RemoveByQueryOperation<T: Persistable>: RemoveOperation<T> where T: NSObject {
    
    init(query: Query, writePolicy: WritePolicy, sync: AnySync? = nil, cache: AnyCache<T>? = nil, client: Client) {
        let httpRequest = client.networkRequestFactory.buildAppDataRemoveByQuery(collectionName: T.collectionName(), query: query)
        super.init(query: query, httpRequest: httpRequest, writePolicy: writePolicy, sync: sync, cache: cache, client: client)
    }
    
}
