//
//  CachedBaseStore.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-17.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import KinveyKit

class CachedBaseStore<T: Persistable>: BaseStore<T> {
    
    internal let entityPersistence: KCSEntityPersistenceProtocol
    internal let clazz: AnyClass = T.self as! AnyClass
    
    internal init(entityPersistence: KCSEntityPersistenceProtocol = KCSRealmEntityPersistence.offlineManager(), client: Client) {
        self.entityPersistence = entityPersistence
        super.init(client: client)
    }
    
    internal func saveEntity(object: T, expirationDate: NSDate) {
        let json = toJson(object)
        if var entity = json as? [String : NSObject] {
            entity[Kinvey.PersistableTimeToLiveKey] = expirationDate
            if let userId = self.client.activeUser?.userId {
                entity[Kinvey.PersistableAclKey] = Acl(creator: userId).toJson()
            }
            entityPersistence.saveEntity(entity, forClass: clazz)
        }
    }
    
    internal func saveEntity(objects: [T], expirationDate: NSDate) {
        for object in objects {
            saveEntity(object, expirationDate: expirationDate)
        }
    }
    
    internal var expirationDate: NSDate {
        get {
            return NSDate()
        }
    }
    
    func saveEntity(object: T) {
        saveEntity(object, expirationDate: expirationDate)
    }
    
    func saveEntity(objects: [T]) {
        saveEntity(objects, expirationDate: expirationDate)
    }
    
    override func get(id: String, completionHandler: ObjectCompletionHandler?) {
        super.get(id) { (obj, error) -> Void in
            self.dispatchAsyncTo(completionHandler)?(obj, error)
        }
    }
    
    override func find(query: Query, completionHandler: ArrayCompletionHandler?) {
        let jsonArray = entityPersistence.findEntity(KCSQueryAdapter(query: query), forClass: clazz)
        let results = fromJson(jsonArray)
        super.find(query) { (results, error) -> Void in
            if let results = results {
                self.saveEntity(results)
            }
        }
        self.dispatchAsyncTo(completionHandler)?(results, nil)
    }
    
    override func save(persistable: T, completionHandler: ObjectCompletionHandler?) {
        super.save(persistable) { (obj, error) -> Void in
            if let obj = obj {
                self.saveEntity(obj)
            }
            self.dispatchAsyncTo(completionHandler)?(obj, error)
        }
    }
    
    override func remove(query: Query, completionHandler: IntCompletionHandler?) {
        super.remove(query) { (count, error) -> Void in
            //TODO: check with backend if we can return the deleted ids
            self.dispatchAsyncTo(completionHandler)?(count, error)
        }
    }

}
