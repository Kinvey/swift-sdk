//
//  NetworkAppDataStrategy.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-22.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

class NetworkAppDataExecutorStrategy<T: Persistable>: AppDataExecutorStrategy<T> {
    
    let collectionName: String
    let client: Client
    let cache: Cache?
    
    init(client: Client = sharedClient, cache: Cache? = nil) {
        self.client = client
        self.collectionName = T.kinveyCollectionName()
        self.cache = cache
    }
    
    override func get(id: String, completionHandler: Store<T>.ObjectCompletionHandler?) -> Request {
        let request = client.networkRequestFactory.buildAppDataGetById(collectionName: collectionName, id: id)
        request.execute() { data, response, error in
            var obj: T? = nil
            if let response = response where response.isResponseOK {
                obj = self.client.responseParser.parse(data, type: T.self)
            }
            if let cache = self.cache, let obj = obj where error == nil {
//                cache.saveEntity(self.toJson(obj))
            }
            self.dispatchAsyncTo(completionHandler)?(obj, error)
        }
        return request
    }
    
    override func find(query: Query, completionHandler: Store<T>.ArrayCompletionHandler?) -> Request {
        let request = client.networkRequestFactory.buildAppDataFindByQuery(collectionName: collectionName, query: query)
        request.execute() { data, response, error in
            var array: [T]? = nil
            if let response = response where response.isResponseOK {
                array = self.client.responseParser.parseArray(data, type: T.self)
            }
            if let cache = self.cache, let array = array where error == nil {
//                self.cache.saveEntities(self.toJson(array))
            }
            self.dispatchAsyncTo(completionHandler)?(array, error)
        }
        return request
    }
    
    override func save(persistable: T, completionHandler: Store<T>.ObjectCompletionHandler?) -> Request {
        let request = client.networkRequestFactory.buildAppDataSave(collectionName: collectionName, persistable: persistable)
        request.execute() { data, response, error in
            if let response = response where response.isResponseOK {
                let json = self.client.responseParser.parse(data, type: [String : AnyObject].self)
                if let json = json {
                    persistable.loadFromJson(json)
                    
                    if let cache = self.cache where error == nil {
//                        self.cache.saveEntity(json)
                    }
                }
            }
            self.dispatchAsyncTo(completionHandler)?(persistable, error)
        }
        return request
    }
    
    override func remove(query: Query, completionHandler: Store<T>.UIntCompletionHandler?) -> Request {
        let request = client.networkRequestFactory.buildAppDataRemoveByQuery(collectionName: collectionName, query: query)
        request.execute() { data, response, error in
            var count: UInt? = nil
            if let response = response where response.isResponseOK {
                let results = self.client.responseParser.parse(data, type: [String : AnyObject].self)
                if let results = results, let _count = results["count"] as? UInt {
                    count = _count
                }
            }
            if let cache = self.cache where error == nil {
//                self.cache.removeEntitiesByQuery(KCSQueryAdapter(query: query))
            }
            self.dispatchAsyncTo(completionHandler)?(count, error)
        }
        return request
    }
    
    override func push(completionHandler: Store<T>.UIntCompletionHandler?) throws {
        fatalError("Operation not permitted")
    }
    
    override func purge() throws {
        fatalError("Operation not permitted")
    }
    
}
