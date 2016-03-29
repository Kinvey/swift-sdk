//
//  SaveOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

@objc(__KNVSaveOperation)
internal class SaveOperation: WriteOperation {
    
    let persistable: Persistable
    
    init(persistable: Persistable, writePolicy: WritePolicy, sync: Sync, cache: Cache, client: Client) {
        self.persistable = persistable
        super.init(writePolicy: writePolicy, sync: sync, persistableType: persistable.dynamicType, cache: cache, client: client)
    }
    
    override func executeLocal(completionHandler: CompletionHandler?) -> Request {
        let request = LocalRequest()
        request.execute { () -> Void in
            let request = self.client.networkRequestFactory.buildAppDataSave(self.persistable)
            
            let persistable = self.fillObject(self.persistable)
            var json = persistable.toJson()
            json = self.fillJson(json)
            self.cache.saveEntity(json)
            
            self.sync.savePendingOperation(self.sync.createPendingOperation(request.request, objectId: persistable.kinveyObjectId))
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
                        var persistableJson = self.merge(persistable, json: json)
                        if var kmd = persistableJson[PersistableMetadataKey] as? [String : AnyObject] where kmd[PersistableMetadataLastRetrievedTimeKey] == nil {
                            kmd[PersistableMetadataLastRetrievedTimeKey] = NSDate().toString()
                            persistableJson[PersistableMetadataKey] = kmd
                        }
                        self.cache.saveEntity(persistableJson)
                        self.persistable.merge(persistable)
                    }
                    completionHandler?(self.persistable, nil)
                } else if let error = error {
                    completionHandler?(nil, error)
                } else {
                    completionHandler?(nil, Error.InvalidResponse)
                }
            }
        }
        return request
    }
    
    private func checkRequirements(completionHandler: ObjectCompletionHandler?) -> Bool {
        guard let _ = client.activeUser else {
            completionHandler?(nil, Error.NoActiveUser)
            return false
        }
        
        return true
    }
    
}
