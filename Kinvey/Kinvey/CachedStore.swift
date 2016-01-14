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
    
    let expiration: CachedStoreExpiration
    let calendar: NSCalendar
    
    private let entityPersistence: KCSEntityPersistenceProtocol
    private let clazz: AnyClass = T.self as! AnyClass
    
    internal convenience init(expiration: Expiration, calendar: NSCalendar = NSCalendar.currentCalendar(), client: Client = Kinvey.sharedClient) {
        let _expiration: CachedStoreExpiration
        switch expiration.1 {
            case .Second:
                _expiration = CachedStoreExpiration.Second(expiration.0)
            case .Minute:
                _expiration = CachedStoreExpiration.Minute(expiration.0)
            case .Hour:
                _expiration = CachedStoreExpiration.Hour(expiration.0)
            case .Day:
                _expiration = CachedStoreExpiration.Day(expiration.0)
            case .Month:
                _expiration = CachedStoreExpiration.Month(expiration.0)
            case .Year:
                _expiration = CachedStoreExpiration.Year(expiration.0)
        }
        self.init(expiration: _expiration, client: client)
    }
    
    internal init(expiration: CachedStoreExpiration, calendar: NSCalendar = NSCalendar.currentCalendar(), entityPersistence: KCSEntityPersistenceProtocol = KCSRealmEntityPersistence.offlineManager(), client: Client = Kinvey.sharedClient) {
        self.expiration = expiration
        self.calendar = calendar
        self.entityPersistence = entityPersistence
        super.init(client: client)
    }
    
    internal var expirationDate: NSDate {
        get {
            return expiration.date(calendar)
        }
    }
    
    internal func saveEntity(object: T, expirationDate: NSDate) {
        let json = toJson(object)
        if var entity = json as? [String : NSObject] {
            entity[PersistableTimeToLiveKey] = expirationDate
            if let userId = client.activeUser?.userId {
                entity[PersistableAclKey] = Acl(creator: userId).toJson()
            }
            entityPersistence.saveEntity(entity, forClass: clazz)
        }
    }
    
    internal func saveEntity(objects: [T], expirationDate: NSDate) {
        for object in objects {
            saveEntity(object, expirationDate: expirationDate)
        }
    }
    
    func saveEntity(object: T) {
        saveEntity(object, expirationDate: expirationDate)
    }
    
    func saveEntity(objects: [T]) {
        saveEntity(objects, expirationDate: expirationDate)
    }
    
    override func get(id: String, completionHandler: ObjectCompletionHandler?) {
        let json = entityPersistence.findEntity(id, forClass: clazz)
        if let obj = fromJson(json) {
            dispatchAsyncTo(completionHandler)?(obj, nil)
            super.get(id) { (obj, error) -> Void in
                if let obj = obj {
                    self.saveEntity(obj)
                }
            }
        } else {
            super.get(id) { (obj, error) -> Void in
                self.dispatchAsyncTo(completionHandler)?(obj, error)
            }
        }
    }
    
    override func find(query: Query, completionHandler: ArrayCompletionHandler?) {
        let jsonArray = entityPersistence.findEntityByQuery(KCSQueryAdapter(query: query), forClass: clazz)
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
    
    override func remove(query: Query, completionHandler: UIntCompletionHandler?) {
        super.remove(query) { (count, error) -> Void in
            //TODO: check with backend if we can return the deleted ids
            if let _ = count {
                self.entityPersistence.removeEntitiesByQuery(KCSQueryAdapter(query: query), forClass: self.clazz)
            }
            self.dispatchAsyncTo(completionHandler)?(count, error)
        }
    }

}
