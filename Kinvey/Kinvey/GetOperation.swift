//
//  GetOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

class GetOperation<T: Persistable where T: NSObject>: Operation<T> {
    
    let id: String
    
    init(id: String, client: Client, cache: Cache, readPolicy: ReadPolicy) {
        self.id = id
        super.init(client: client, cache: cache, readPolicy: readPolicy)
    }
    
    func execute(completionHandler: ObjectCompletionHandler? = nil) -> Request {
        switch readPolicy! {
        case .ForceLocal:
            let request = LocalRequest()
            request.execute({ (_, _, _) -> Void in
                self.executeLocal(completionHandler)
            })
            return request
        case .ForceNetwork:
            return executeNetwork(completionHandler)
        case .PreferLocal:
            let request = RequestDecorator()
            executeLocal() { obj, error in
                if let obj = obj {
                    completionHandler?(obj, nil)
                } else {
                    request.request = self.executeNetwork(completionHandler)
                }
            }
            return request
        case .PreferNetwork:
            return executeNetwork({ (obj, error) -> Void in
                if let obj = obj {
                    completionHandler?(obj, nil)
                } else {
                    self.executeLocal(completionHandler)
                }
            })
        }
    }
    
    private func executeLocal(completionHandler: ObjectCompletionHandler?) {
        let json = cache.findEntity(id)
        if let json = json {
            let persistable = fromJson(json)
            completionHandler?(persistable, nil)
        } else {
            completionHandler?(nil, nil)
        }
    }
    
    private func executeNetwork(completionHandler: ObjectCompletionHandler?) -> Request {
        let request = client.networkRequestFactory.buildAppDataGetById(collectionName: T.kinveyCollectionName(), id: id)
        request.execute() { data, response, error in
            if let response = response where response.isResponseOK, let obj = self.client.responseParser.parse(data, type: T.self) {
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
