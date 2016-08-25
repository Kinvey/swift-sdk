//
//  CountOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-08-24.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

class CountOperation<T: Persistable where T: NSObject>: ReadOperation<T> {
    
    let query: Query?
    
    init(query: Query? = nil, readPolicy: ReadPolicy, cache: Cache<T>?, client: Client) {
        self.query = query
        super.init(readPolicy: readPolicy, cache: cache, client: client)
    }
    
    override func executeLocal(completionHandler: CompletionHandler? = nil) -> Request {
        let request = LocalRequest()
        request.execute { () -> Void in
            if let cache = self.cache {
                let count = cache.count(query)
                completionHandler?(count, nil)
            } else {
                completionHandler?(0, nil)
            }
        }
        return request
    }
    
    override func executeNetwork(completionHandler: CompletionHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildAppDataCountByQuery(collectionName: T.collectionName(), query: query)
        request.execute() { data, response, error in
            if let response = response where response.isOK,
                let data = data,
                let json = try? NSJSONSerialization.JSONObjectWithData(data, options: []),
                let result = json as? [String : Int],
                let count = result["count"]
            {
                completionHandler?(count, nil)
            } else {
                completionHandler?(nil, buildError(data, response, error, self.client))
            }
        }
        return request
    }
    
}
