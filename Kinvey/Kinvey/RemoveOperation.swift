//
//  RemoveOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-26.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

class RemoveOperation<T: Persistable>: WriteOperation<T, Int>, WriteOperationType where T: NSObject {
    
    let query: Query
    private let httpRequest: () -> HttpRequest
    lazy var request: HttpRequest = self.httpRequest()
    
    init(
        query: Query,
        httpRequest: @autoclosure @escaping () -> HttpRequest,
        writePolicy: WritePolicy,
        sync: AnySync? = nil,
        cache: AnyCache<T>? = nil,
        options: Options?
    ) {
        self.query = query
        self.httpRequest = httpRequest
        super.init(
            writePolicy: writePolicy,
            sync: sync,
            cache: cache,
            options: options
        )
    }
    
    func executeLocal(_ completionHandler: CompletionHandler? = nil) -> Request {
        let request = LocalRequest()
        request.execute { () -> Void in
            var count = 0
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
                }
            }
            completionHandler?(.success(count))
        }
        return request
    }
    
    func executeNetwork(_ completionHandler: CompletionHandler? = nil) -> Request {
        request.execute() { data, response, error in
            if let response = response, response.isOK,
                let results = self.client.responseParser.parse(data),
                let count = results["count"] as? Int
            {
                self.cache?.remove(byQuery: self.query)
                completionHandler?(.success(count))
            } else {
                completionHandler?(.failure(buildError(data, response, error, self.client)))
            }
        }
        return request
    }
    
}
