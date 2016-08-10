//
//  RemoveOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-26.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

class RemoveOperation<T: Persistable where T: NSObject>: WriteOperation<T, UInt?> {
    
    let query: Query
    lazy var request: HttpRequest = self.buildRequest()
    
    init(query: Query, writePolicy: WritePolicy, sync: Sync<T>? = nil, cache: Cache<T>? = nil, client: Client) {
        self.query = query
        super.init(writePolicy: writePolicy, sync: sync, cache: cache, client: client)
    }
    
    func buildRequest() -> HttpRequest {
        preconditionFailure("Method needs to be implemented")
    }
    
    override func executeLocal(completionHandler: CompletionHandler? = nil) -> Request {
        let request = LocalRequest()
        request.execute { () -> Void in
            var count: UInt?
            if let cache = self.cache {
                let realmObjects = cache.findEntityByQuery(self.query)
                count = UInt(realmObjects.count)
                let detachedObjects = cache.detach(realmObjects)
                if cache.removeEntities(realmObjects) {
                    let idKey = T.entityIdProperty()
                    for object in detachedObjects {
                        if let objectId = object[idKey] as? String, let sync = self.sync {
                            if objectId.hasPrefix(ObjectIdTmpPrefix) {
                                sync.removeAllPendingOperations(objectId)
                            } else {
                                sync.savePendingOperation(sync.createPendingOperation(self.request.request, objectId: objectId))
                            }
                        }
                    }
                } else {
                    count = 0
                }
            }
            completionHandler?(count, nil)
        }
        return request
    }
    
    override func executeNetwork(completionHandler: CompletionHandler? = nil) -> Request {
        request.execute() { data, response, error in
            if let response = response where response.isOK,
                let results = self.client.responseParser.parse(data),
                let count = results["count"] as? UInt
            {
                self.cache?.removeEntitiesByQuery(self.query)
                completionHandler?(count, nil)
            } else {
                completionHandler?(nil, buildError(data, response, error, self.client))
            }
        }
        return request
    }
    
}
