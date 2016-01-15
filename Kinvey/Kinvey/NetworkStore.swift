//
//  NetworkStore.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import KinveyKit

class NetworkStore<T: Persistable>: Store<T> {
    
    private let cacheEnabled: Bool
    
    init(client: Client, cacheEnabled: Bool = true) {
        self.cacheEnabled = cacheEnabled
        super.init(client: client)
    }
    
    override func get(id: String, completionHandler: ObjectCompletionHandler?) {
        super.get(id) { (obj, error) -> Void in
            if self.cacheEnabled, let obj = obj {
                self.entityPersistence.saveEntity(self.toJson(obj), forClass: self.clazz)
            }
            self.dispatchAsyncTo(completionHandler)?(obj, error)
        }
    }
    
    override func find(query: Query, completionHandler: ArrayCompletionHandler?) {
        super.find(query) { (array, error) -> Void in
            if self.cacheEnabled, let array = array {
                self.entityPersistence.saveEntities(self.toJson(array), forClass: self.clazz)
            }
            self.dispatchAsyncTo(completionHandler)?(array, error)
        }
    }
    
    override func save(persistable: T, completionHandler: ObjectCompletionHandler?) {
        super.save(persistable) { (obj, error) -> Void in
            if self.cacheEnabled, let obj = obj {
                self.entityPersistence.saveEntity(self.toJson(obj), forClass: self.clazz)
            }
            self.dispatchAsyncTo(completionHandler)?(obj, error)
        }
    }
    
    override func remove(query: Query, completionHandler: UIntCompletionHandler?) {
        super.remove(query) { (count, error) -> Void in
            if self.cacheEnabled && error == nil {
                self.entityPersistence.removeEntitiesByQuery(KCSQueryAdapter(query: query), forClass: self.clazz)
            }
            self.dispatchAsyncTo(completionHandler)?(count, error)
        }
    }

}
