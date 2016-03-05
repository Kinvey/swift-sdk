//
//  PullOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import PromiseKit

class PullOperation: WriteOperation {
    
    let query: Query
    
    init(query: Query, writePolicy: WritePolicy, sync: Sync, persistableType: Persistable.Type, cache: Cache, client: Client) {
        self.query = query
        super.init(writePolicy: writePolicy, sync: sync, persistableType: persistableType, cache: cache, client: client)
    }
    
    override func execute(completionHandler: CompletionHandler?) -> Request {
        let request = client.networkRequestFactory.buildAppDataFindByQuery(collectionName: self.persistableType.kinveyCollectionName(), query: query)
        Promise { fulfill, reject in
            request.execute { (data, response, error) -> Void in
                var array: [Persistable]? = nil
                if let response = response where response.isResponseOK, let jsonArray = self.client.responseParser.parseArray(data) {
                    array = self.persistableType.fromJson(jsonArray)
                    
                    if let array = array where array.count > 0 {
                        var results = self.toJson(array)
                        for i in 0...array.count - 1 {
                            let json = jsonArray[i]
                            results[i] = self.merge(array[i], json: json)
                        }
                        self.cache.removeEntitiesByQuery(self.query)
                        self.cache.saveEntities(results)
                    }
                }
                if let array = array {
                    fulfill(array)
                } else if let error = error {
                    reject(error)
                } else {
                    reject(Error.InvalidResponse)
                }
            }
        }.then { results in
            completionHandler?(results, nil)
        }.error { error in
            completionHandler?(nil, error)
        }
        return request
    }
    
}
