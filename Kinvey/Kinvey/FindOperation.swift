//
//  FindOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

@objc(__KNVFindOperation)
public class FindOperation: ReadOperation {
    
    let query: Query
    
    public convenience init(query: Query, readPolicy: ReadPolicy, persistableClass: AnyClass, cache: Cache, client: Client) {
        self.init(query: query, readPolicy: readPolicy, persistableType: persistableClass as! Persistable.Type, cache: cache, client: client)
    }
    
    init(query: Query, readPolicy: ReadPolicy, persistableType: Persistable.Type, cache: Cache, client: Client) {
        self.query = query
        super.init(readPolicy: readPolicy, persistableType: persistableType, cache: cache, client: client)
    }
    
    override func executeLocal(completionHandler: CompletionHandler? = nil) -> Request {
        let request = LocalRequest()
        request.execute { () -> Void in
            let json = self.cache.findEntityByQuery(self.query)
            let array = self.fromJson(jsonArray: json)
            completionHandler?(array, nil)
        }
        return request
    }
    
    override func executeNetwork(completionHandler: CompletionHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildAppDataFindByQuery(collectionName: persistableType.kinveyCollectionName(), query: query)
        request.execute() { data, response, error in
            if let response = response where response.isResponseOK,
                let jsonArray = self.client.responseParser.parseArray(data)
            {
                let array = self.persistableType.fromJson(jsonArray)
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
