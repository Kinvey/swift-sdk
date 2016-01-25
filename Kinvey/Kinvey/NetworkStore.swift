//
//  NetworkStore.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import KinveyKit

class NetworkStore<T: Persistable> {
    
    private let cacheEnabled: Bool
    
    init(client: Client, cacheEnabled: Bool = true) {
        self.cacheEnabled = cacheEnabled
//        super.init(client: client)
    }
    
//    override func get(id: String, completionHandler: ObjectCompletionHandler?) -> Request {
//        return super.get(id) { (obj, error) -> Void in
//            if self.cacheEnabled, let obj = obj {
//                self.cache.saveEntity(self.toJson(obj))
//            }
//            self.dispatchAsyncTo(completionHandler)?(obj, error)
//        }
//    }
//    
//    override func find(query: Query, completionHandler: ArrayCompletionHandler?) -> Request {
//        return super.find(query) { (array, error) -> Void in
//            if self.cacheEnabled, let array = array {
//                self.cache.saveEntities(self.toJson(array))
//            }
//            self.dispatchAsyncTo(completionHandler)?(array, error)
//        }
//    }
//    
//    override func save(persistable: T, completionHandler: ObjectCompletionHandler?) -> Request {
//        return super.save(persistable) { (obj, error) -> Void in
//            if self.cacheEnabled, let obj = obj {
//                self.cache.saveEntity(self.toJson(obj))
//            }
//            self.dispatchAsyncTo(completionHandler)?(obj, error)
//        }
//    }
//    
//    override func remove(query: Query, completionHandler: UIntCompletionHandler?) -> Request {
//        return super.remove(query) { (count, error) -> Void in
//            if self.cacheEnabled && error == nil {
//                self.cache.removeEntitiesByQuery(KCSQueryAdapter(query: query))
//            }
//            self.dispatchAsyncTo(completionHandler)?(count, error)
//        }
//    }

}
