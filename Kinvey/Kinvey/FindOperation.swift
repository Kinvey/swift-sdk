//
//  FindOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

class FindOperation<T: Persistable where T: NSObject>: ReadOperation<T, [T]> {
    
    let query: Query
    
    init(query: Query, readPolicy: ReadPolicy, client: Client, cache: Cache) {
        self.query = query
        super.init(readPolicy: readPolicy, client: client, cache: cache)
    }
    
    override func executeLocal(completionHandler: CompletionHandler? = nil) -> Request {
        let request = LocalRequest()
        request.execute { (_, _, _) -> Void in
            let json = self.cache.findEntityByQuery(self.query)
            let array: [T] = T.fromJson(json)
            completionHandler?(array, nil)
        }
        return request
    }
    
    override func executeNetwork(completionHandler: CompletionHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildAppDataFindByQuery(collectionName: T.kinveyCollectionName(), query: query)
        request.execute() { data, response, error in
            if let response = response where response.isResponseOK, let array = self.client.responseParser.parseArray(data, type: T.self) {
                self.cache.saveEntities(self.toJson(array))
                completionHandler?(array, nil)
            } else if let error = error {
                completionHandler?(nil, error)
            } else {
                completionHandler?(nil, Error.InvalidResponse)
            }
        }
        return request
    }
    
}
