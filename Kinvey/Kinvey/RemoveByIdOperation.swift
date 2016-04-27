//
//  RemoveByIdOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-25.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

@objc(__KNVRemoveByIdOperation)
internal class RemoveByIdOperation: RemoveOperation {
    
    let objectId: String
    
    override func buildRequest() -> HttpRequest {
        return client.networkRequestFactory.buildAppDataRemoveById(collectionName: persistableType.kinveyCollectionName(), objectId: objectId)
    }
    
    internal init(objectId: String, writePolicy: WritePolicy, sync: Sync? = nil, persistableType: Persistable.Type, cache: Cache? = nil, client: Client) {
        self.objectId = objectId
        let query = Query(format: "\(persistableType.idKey) == %@", objectId)
        super.init(query: query, writePolicy: writePolicy, sync: sync, persistableType: persistableType, cache: cache, client: client)
    }
    
}
