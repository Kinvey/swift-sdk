//
//  SaveOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class SaveOperation<T: Persistable>: WriteOperation<T> {
    
    let persistable: T
    
    init(persistable: T, writePolicy: WritePolicy, sync: Sync? = nil, cache: Cache<T>? = nil, client: Client) {
        self.persistable = persistable
        super.init(writePolicy: writePolicy, sync: sync, cache: cache, client: client)
    }
    
    override func executeLocal(completionHandler: CompletionHandler?) -> Request {
        let request = LocalRequest()
        request.execute { () -> Void in
            let request = self.client.networkRequestFactory.buildAppDataSave(self.persistable)
            
            let persistable = self.fillObject(self.persistable)
            if let cache = self.cache {
                cache.saveEntity(persistable)
                var json = persistable.toJSON()
                json = self.fillJson(json)
                cache.saveEntity(json)
            }
            
            if let sync = self.sync {
                sync.savePendingOperation(sync.createPendingOperation(request.request, objectId: persistable.kinveyObjectId))
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
                        let persistable = self.persistableType.fromJson(json)
                        if let cache = self.cache {
                            var persistableJson = self.merge(persistable, json: json)
                            if var kmd = persistableJson[PersistableMetadataKey] as? [String : AnyObject] where kmd[PersistableMetadataLastRetrievedTimeKey] == nil {
                                kmd[PersistableMetadataLastRetrievedTimeKey] = NSDate().toString()
                                persistableJson[PersistableMetadataKey] = kmd
                            }
                            cache.saveEntity(persistableJson)
                        }
                        self.persistable.merge(persistable)
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
