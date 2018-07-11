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
    private let httpRequest: () -> HttpRequest<ResultType>
    lazy var request: HttpRequest = self.httpRequest()
    
    typealias ResultType = Result<Int, Swift.Error>
    
    init(
        query: Query,
        httpRequest: @autoclosure @escaping () -> HttpRequest<ResultType>,
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
    
    func executeLocal(_ completionHandler: CompletionHandler? = nil) -> AnyRequest<ResultType> {
        let request = LocalRequest<ResultType>()
        request.execute { () -> Void in
            var count = 0
            if let cache = self.cache {
                let realmObjects = cache.find(byQuery: self.query)
                count = Int(realmObjects.count)
                let idKey = try! T.entityIdProperty()
                let objectIds = cache.detach(entities: realmObjects, query: self.query).compactMap {
                    $0[idKey] as? String
                }
                if cache.remove(entities: realmObjects), let sync = self.sync {
                    objectIds.forEachAutoreleasepool { objectId in
                        if objectId.hasPrefix(ObjectIdTmpPrefix) {
                            sync.removeAllPendingOperations(objectId)
                        } else {
                            sync.savePendingOperation(sync.createPendingOperation(self.request.request, objectId: objectId))
                        }
                    }
                }
            }
            let result: ResultType = .success(count)
            request.result = result
            completionHandler?(result)
        }
        return AnyRequest(request)
    }
    
    func executeNetwork(_ completionHandler: CompletionHandler? = nil) -> AnyRequest<ResultType> {
        request.execute() { data, response, error in
            let result: ResultType
            if let response = response,
                response.isOK,
                let data = data,
                let results = try? self.client.jsonParser.parseDictionary(from: data),
                let count = results["count"] as? Int
            {
                self.cache?.remove(byQuery: self.query)
                result = .success(count)
            } else {
                result = .failure(buildError(data, response, error, self.client))
            }
            self.request.result = result
            completionHandler?(result)
        }
        return AnyRequest(request)
    }
    
}
