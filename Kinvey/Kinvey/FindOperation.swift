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
    let deltaSet: Bool
    
    init(query: Query, deltaSet: Bool, readPolicy: ReadPolicy, persistableType: Persistable.Type, cache: Cache, client: Client) {
        self.query = query
        self.deltaSet = deltaSet
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
        let fields: Set<String>? = deltaSet ? [PersistableIdKey, "\(PersistableMetadataKey).\(Metadata.LmtKey)"] : nil
        let request = client.networkRequestFactory.buildAppDataFindByQuery(collectionName: persistableType.kinveyCollectionName(), query: query, fields: fields)
        request.execute() { data, response, error in
            if let response = response where response.isResponseOK,
                let jsonArray = self.client.responseParser.parseArray(data)
            {
                if self.deltaSet {
//                    self.computeDelta(self.query, jsonArray: jsonArray)
                } else {
                    let array = self.persistableType.fromJson(jsonArray)
                    self.cache.saveEntities(self.toJson(array))
                    completionHandler?(array, nil)
                }
            } else if let error = error {
                completionHandler?(nil, error)
            } else {
                completionHandler?(nil, Error.InvalidResponse)
            }
        }
        return request
    }
    
}
