//
//  SaveOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

class SaveOperation<T: Persistable where T: NSObject>: Operation<T> {
    
    let persistable: T
    
    init(persistable: T, client: Client, cache: Cache, sync: Sync, writePolicy: WritePolicy) {
        self.persistable = persistable
        super.init(client: client, cache: cache, sync: sync, writePolicy: writePolicy)
    }
    
    func execute(completionHandler: ObjectCompletionHandler?) -> Request {
        switch writePolicy! {
        case .ForceLocal:
            let request = LocalRequest()
            request.execute({ (_, _, _) -> Void in
                self.executeLocal(completionHandler)
            })
            return request
        case .LocalThenNetwork:
            self.executeLocal(completionHandler)
            fallthrough
        case .ForceNetwork:
            return executeNetwork(completionHandler)
        }
    }
    
    private func executeLocal(completionHandler: ObjectCompletionHandler?) {
        let request = self.client.networkRequestFactory.buildAppDataSave(collectionName: T.kinveyCollectionName(), persistable: self.persistable) as! HttpRequest
        
        let persistable = self.fillObject(self.persistable)
        var json = persistable.toJson()
        json = self.fillJson(json)
        self.cache.saveEntity(json)
        
        if let sync = self.sync {
            sync.savePendingOperation(sync.createPendingOperation(request.request, objectId: persistable.kinveyObjectId))
        }
        completionHandler?(self.persistable, nil)
    }
    
    private func executeNetwork(completionHandler: ObjectCompletionHandler?) -> Request {
        let request = client.networkRequestFactory.buildAppDataSave(collectionName: T.kinveyCollectionName(), persistable: persistable)
        if checkRequirements(completionHandler) {
            request.execute() { data, response, error in
                if let response = response where response.isResponseOK {
                    let json = self.client.responseParser.parse(data, type: [String : AnyObject].self)
                    if let json = json {
                        let persistable: T = T.fromJson(json)
                        var persistableJson = self.merge(persistable, json: json)
                        if var kmd = persistableJson[PersistableMetadataKey] as? [String : AnyObject] where kmd[PersistableMetadataLastRetrievedTimeKey] == nil {
                            kmd[PersistableMetadataLastRetrievedTimeKey] = NSDate()
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
