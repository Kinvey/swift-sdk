//
//  CachedStore.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import KinveyKit

class CachedStore<T: Persistable>: Store<T> {    
    
    let ttl: TTL
    
    internal init(ttl: TTL, client: Client = Kinvey.sharedClient) {
        self.ttl = ttl
        super.init(client: client)
    }
    
    var expirationDate: NSDate {
        get {
            return ttl.0.date(ttl.1)
        }
    }
    
    internal func saveEntity(objects: [T], expirationDate: NSDate) {
        for object in objects {
            saveEntity(object)
        }
    }
    
    func saveEntity(object: T) {
        let json = toJson(object)
        if var entity = json as? [String : NSObject] {
            if let userId = client.activeUser?.userId {
                entity[PersistableAclKey] = Acl(creator: userId).toJson()
            }
            cache.saveEntity(entity)
        }
    }
    
    func saveEntity(objects: [T]) {
        saveEntity(objects, expirationDate: expirationDate)
    }
    
    override func get(id: String, completionHandler: ObjectCompletionHandler?) -> Request {
        let json = cache.findEntity(id)
        if let obj = fromJson(json) {
            dispatchAsyncTo(completionHandler)?(obj, nil)
            return super.get(id) { (obj, error) -> Void in
                if let obj = obj {
                    self.saveEntity(obj)
                }
            }
        } else {
            return super.get(id) { (obj, error) -> Void in
                self.dispatchAsyncTo(completionHandler)?(obj, error)
            }
        }
    }
    
    override func find(query: Query, completionHandler: ArrayCompletionHandler?) -> Request {
        let filterExpiredQuery = NSPredicate(format: "_kmd.\(PersistableMetadataLastRetrievedTime) < %@", expirationDate)
        let modifiedQuery: Query
        if let predicate = query.predicate {
            modifiedQuery = Query(predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [filterExpiredQuery, predicate]))
        } else {
            modifiedQuery = Query(predicate: filterExpiredQuery)
        }
        let jsonArray = cache.findEntityByQuery(KCSQueryAdapter(query: modifiedQuery))
        let results = fromJson(jsonArray)
        return super.find(query) { (results, error) -> Void in
            if let results = results {
                self.saveEntity(results)
            }
        }
        self.dispatchAsyncTo(completionHandler)?(results, nil)
    }
    
    override func save(persistable: T, completionHandler: ObjectCompletionHandler?) -> Request {
        return super.save(persistable) { (obj, error) -> Void in
            if let obj = obj {
                self.saveEntity(obj)
            }
            self.dispatchAsyncTo(completionHandler)?(obj, error)
        }
    }
    
    override func remove(query: Query, completionHandler: UIntCompletionHandler?) -> Request {
        return super.remove(query) { (count, error) -> Void in
            //TODO: check with backend if we can return the deleted ids
            if let _ = count {
                self.cache.removeEntitiesByQuery(KCSQueryAdapter(query: query))
            }
            self.dispatchAsyncTo(completionHandler)?(count, error)
        }
    }

}
