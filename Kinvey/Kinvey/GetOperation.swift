//
//  GetOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

@objc(__KNVGetOperation)
public class GetOperation: ReadOperation {
    
    let id: String
    
    public convenience init(id: String, readPolicy: ReadPolicy, persistableClass: AnyClass, cache: Cache, client: Client) {
        self.init(id: id, readPolicy: readPolicy, persistableType: persistableClass as! Persistable.Type, cache: cache, client: client)
    }
    
    init(id: String, readPolicy: ReadPolicy, persistableType: Persistable.Type, cache: Cache, client: Client) {
        self.id = id
        super.init(readPolicy: readPolicy, persistableType: persistableType, cache: cache, client: client)
    }
    
    override func executeLocal(completionHandler: CompletionHandler?) -> Request {
        let request = LocalRequest()
        request.execute { () -> Void in
            let json = self.cache.findEntity(self.id)
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
                self.cache.saveEntity(obj.toJson())
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
