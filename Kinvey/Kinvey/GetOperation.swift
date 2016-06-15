//
//  GetOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class GetOperation<T: Persistable>: ReadOperation<T> {
    
    let id: String
    
    init(id: String, readPolicy: ReadPolicy, cache: Cache<T>, client: Client) {
        self.id = id
        super.init(readPolicy: readPolicy, cache: cache, client: client)
    }
    
    override func executeLocal(completionHandler: CompletionHandler?) -> Request {
        let request = LocalRequest()
        request.execute { () -> Void in
            let json = self.cache?.findEntity(self.id)
            if let json = json {
                let persistable = self.fromJson(json)
                completionHandler?(persistable, nil)
            } else {
                completionHandler?(nil, nil)
            }
        }
        return request
    }
    
    override func executeNetwork(completionHandler: CompletionHandler?) -> Request {
        let request = client.networkRequestFactory.buildAppDataGetById(collectionName: self.persistableType.kinveyCollectionName(), id: id)
        request.execute() { data, response, error in
            if let response = response where response.isResponseOK, let json = self.client.responseParser.parse(data) {
                let obj = self.persistableType.fromJson(json)
                if let cache = self.cache {
                    let persistableJson = self.merge(obj, json: json)
                    cache.saveEntity(persistableJson)
                }
                completionHandler?(obj, nil)
            } else if let error = error {
                completionHandler?(nil, error)
            } else {
                completionHandler?(nil, Error.InvalidResponse)
            }
        }
        return request
    }
    
}
