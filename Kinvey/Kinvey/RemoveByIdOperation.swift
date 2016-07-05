//
//  RemoveByIdOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-25.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class RemoveByIdOperation<T: Persistable where T: NSObject>: RemoveOperation<T> {
    
    let objectId: String
    
    override func buildRequest() -> HttpRequest {
        return client.networkRequestFactory.buildAppDataRemoveById(collectionName: T.collectionName(), objectId: objectId)
    }
    
    internal init(objectId: String, writePolicy: WritePolicy, sync: Sync<T>? = nil, cache: Cache<T>? = nil, client: Client) {
        self.objectId = objectId
        let entityIdProperty = T.entityIdProperty()
        let query = Query(format: "\(entityIdProperty!) == %@", objectId)
        super.init(query: query, writePolicy: writePolicy, sync: sync, cache: cache, client: client)
    }
    
}
