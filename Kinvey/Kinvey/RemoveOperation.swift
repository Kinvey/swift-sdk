//
//  RemoveOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-26.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

class RemoveOperation<T: Persistable>: WriteOperation<T, Int?> where T: NSObject {
    
    let query: Query
    lazy var request: HttpRequest = self.buildRequest()
    
    init(query: Query, writePolicy: WritePolicy, sync: AnySync? = nil, cache: AnyCache<T>? = nil, client: Client) {
        self.query = query
        super.init(writePolicy: writePolicy, sync: sync, cache: cache, client: client)
    }
    
    func buildRequest() -> HttpRequest {
        let message = "Method \(#function) must be overridden"
        log.severe(message)
        fatalError(message)
    }
    
    override func executeLocal(_ completionHandler: CompletionHandler? = nil) -> Request {
        let request = LocalRequest()
        request.execute { () -> Void in
            var count: Int?
            if let cache = self.cache {
                let realmObjects = cache.find(byQuery: self.query)
                count = realmObjects.count
                let detachedObjects = cache.detach(entities: realmObjects, query: self.query)
                if cache.remove(entities: realmObjects) {
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
    
    override func executeNetwork(_ completionHandler: CompletionHandler? = nil) -> Request {
        request.execute() { data, response, error in
            if let response = response , response.isOK,
                let results = self.client.responseParser.parse(data),
                let count = results["count"] as? Int
            {
                self.cache?.remove(byQuery: self.query)
                completionHandler?(count, nil)
            } else {
                completionHandler?(nil, buildError(data, response, error, self.client))
            }
        }
        return request
    }
    
}
