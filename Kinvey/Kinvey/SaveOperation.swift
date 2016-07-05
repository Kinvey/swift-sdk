//
//  SaveOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class SaveOperation<T: Persistable where T: NSObject>: WriteOperation<T, T?> {
    
    var persistable: T
    
    init(inout persistable: T, writePolicy: WritePolicy, sync: Sync<T>? = nil, cache: Cache<T>? = nil, client: Client) {
        self.persistable = persistable
        super.init(writePolicy: writePolicy, sync: sync, cache: cache, client: client)
    }
    
    init(persistable: T, writePolicy: WritePolicy, sync: Sync<T>? = nil, cache: Cache<T>? = nil, client: Client) {
        self.persistable = persistable
        super.init(writePolicy: writePolicy, sync: sync, cache: cache, client: client)
    }
    
    override func executeLocal(completionHandler: CompletionHandler?) -> Request {
        let request = LocalRequest()
        request.execute { () -> Void in
            let request = self.client.networkRequestFactory.buildAppDataSave(self.persistable)
            
            let persistable = self.fillObject(&self.persistable)
            if let cache = self.cache {
                cache.saveEntity(persistable)
            }
            
            if let sync = self.sync {
                sync.savePendingOperation(sync.createPendingOperation(request.request, objectId: persistable.entityId))
            }
            completionHandler?(self.persistable, nil)
        }
        return request
    }
    
    override func executeNetwork(completionHandler: CompletionHandler?) -> Request {
        let request = client.networkRequestFactory.buildAppDataSave(persistable)
        if checkRequirements(completionHandler) {
            request.execute() { data, response, error in
                if let response = response where response.isResponseOK {
                    let json = self.client.responseParser.parse(data)
                    if let json = json {
                        let persistable = T(JSON: json)
                        if let persistable = persistable, let cache = self.cache {
                            cache.saveEntity(persistable)
                        }
                        self.merge(&self.persistable, json: json)
                    }
                    completionHandler?(self.persistable, nil)
                } else if let error = error {
                    completionHandler?(nil, error as NSError)
                } else {
                    completionHandler?(nil, KinveyError.InvalidResponse)
                }
            }
        }
        return request
    }
    
    private func checkRequirements(completionHandler: ObjectCompletionHandler?) -> Bool {
        guard let _ = client.activeUser else {
            completionHandler?(nil, KinveyError.NoActiveUser)
            return false
        }
        
        return true
    }
    
}
