//
//  GetOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

class GetOperation<T: Persistable where T: NSObject>: ReadOperation<T, T> {
    
    let id: String
    
    init(id: String, readPolicy: ReadPolicy, client: Client, cache: Cache) {
        self.id = id
        super.init(readPolicy: readPolicy, client: client, cache: cache)
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
        let request = client.networkRequestFactory.buildAppDataGetById(collectionName: T.kinveyCollectionName(), id: id)
        request.execute() { data, response, error in
            if let response = response where response.isResponseOK, let json = self.client.responseParser.parse(data, type: [String : AnyObject].self) {
                let obj: T = T.fromJson(json)
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
