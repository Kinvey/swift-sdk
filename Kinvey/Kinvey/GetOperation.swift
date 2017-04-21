//
//  GetOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class GetOperation<T: Persistable>: ReadOperation<T, T, Swift.Error>, ReadOperationType where T: NSObject {
    
    let id: String
    
    init(id: String, readPolicy: ReadPolicy, cache: AnyCache<T>?, client: Client) {
        self.id = id
        super.init(readPolicy: readPolicy, cache: cache, client: client)
    }
    
    func executeLocal(_ completionHandler: CompletionHandler?) -> Request {
        let request = LocalRequest()
        request.execute { () -> Void in
            if let persistable = self.cache?.find(byId: self.id) {
                completionHandler?(.success(persistable))
            } else {
                completionHandler?(.failure(buildError(client: self.client)))
            }
        }
        return request
    }
    
    func executeNetwork(_ completionHandler: CompletionHandler?) -> Request {
        let request = client.networkRequestFactory.buildAppDataGetById(collectionName: T.collectionName(), id: id)
        request.execute() { data, response, error in
            if let response = response,
                response.isOK,
                let json = self.client.responseParser.parse(data),
                let obj = T(JSON: json)
            {
                self.cache?.save(entity: obj)
                completionHandler?(.success(obj))
            } else {
                completionHandler?(.failure(buildError(data, response, error, self.client)))
            }
        }
        return request
    }
    
}
