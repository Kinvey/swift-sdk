//
//  SaveOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class SaveOperation<T: Persistable>: WriteOperation<T, T>, WriteOperationType where T: NSObject {
    
    var persistable: T
    
    init(persistable: inout T, writePolicy: WritePolicy, sync: AnySync? = nil, cache: AnyCache<T>? = nil, client: Client) {
        self.persistable = persistable
        super.init(writePolicy: writePolicy, sync: sync, cache: cache, client: client)
    }
    
    init(persistable: T, writePolicy: WritePolicy, sync: AnySync? = nil, cache: AnyCache<T>? = nil, client: Client) {
        self.persistable = persistable
        super.init(writePolicy: writePolicy, sync: sync, cache: cache, client: client)
    }
    
    func executeLocal(_ completionHandler: CompletionHandler?) -> Request {
        let request = LocalRequest()
        request.execute { () -> Void in
            let request = self.client.networkRequestFactory.buildAppDataSave(self.persistable)
            
            let persistable = self.fillObject(&self.persistable)
            if let cache = self.cache {
                cache.save(entity: persistable)
            }
            
            if let sync = self.sync {
                sync.savePendingOperation(sync.createPendingOperation(request.request, objectId: persistable.entityId))
            }
            completionHandler?(.success(self.persistable))
        }
        return request
    }
    
    func executeNetwork(_ completionHandler: CompletionHandler?) -> Request {
        let request = client.networkRequestFactory.buildAppDataSave(persistable)
        if checkRequirements(completionHandler) {
            request.execute() { data, response, error in
                if let response = response, response.isOK {
                    let json = self.client.responseParser.parse(data)
                    if let json = json {
                        let persistable = T(JSON: json)
                        if let objectId = self.persistable.entityId, let sync = self.sync {
                            sync.removeAllPendingOperations(objectId, methods: ["POST", "PUT"])
                        }
                        if let persistable = persistable, let cache = self.cache {
                            cache.remove(entity: self.persistable)
                            cache.save(entity: persistable)
                        }
                        self.merge(&self.persistable, json: json)
                    }
                    completionHandler?(.success(self.persistable))
                } else {
                    completionHandler?(.failure(buildError(data, response, error, self.client)))
                }
            }
        }
        return request
    }
    
    fileprivate func checkRequirements(_ completionHandler: CompletionHandler?) -> Bool {
        guard let _ = client.activeUser else {
            completionHandler?(.failure(Error.noActiveUser))
            return false
        }
        
        return true
    }
    
}
