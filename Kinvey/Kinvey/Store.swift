//
//  BaseStore.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-14.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import KinveyKit

public class Store<T: Persistable> {
    
    public typealias ArrayCompletionHandler = ([T]?, NSError?) -> Void
    public typealias ObjectCompletionHandler = (T?, NSError?) -> Void
    public typealias UIntCompletionHandler = (UInt?, NSError?) -> Void
    
//    private var ReadPolicy {get set}
//    private var WritePolicy {get set}
    
    public let collectionName: String
    public let client: Client
    
    internal var cache: Cache {
        get {
            return CacheManager.getInstance(client.appKey!).cache(T.kinveyCollectionName())
        }
    }
    
    internal var sync: Sync {
        get {
            return SyncManager.getInstance(client.appKey!).sync(T.kinveyCollectionName())
        }
    }
    
    internal let clazz: AnyClass = T.self as! AnyClass
    
    init(client: Client = Kinvey.sharedClient) {
        self.client = client
        self.collectionName = T.kinveyCollectionName()
    }
    
    public func get(id: String, completionHandler: ObjectCompletionHandler?) -> Request {
        assert(id != "")
        let request = HttpRequest(endpoint: Endpoint.AppDataById(client: client, collectionName: collectionName, id: id), credential: client.activeUser, client: client)
        request.execute() { data, response, error in
            var obj: T? = nil
            if let response = response where response.isResponseOK {
                obj = self.client.responseParser.parse(data, type: T.self)
            }
            completionHandler?(obj, error)
        }
        return request
    }
    
    public func find(query: Query = Query(), completionHandler: ArrayCompletionHandler?) -> Request {
        let request = HttpRequest(endpoint: Endpoint.AppDataByQuery(client: client, collectionName: collectionName, query: query), credential: client.activeUser, client: client)
        request.execute() { data, response, error in
            var obj: [T]? = nil
            if let response = response where response.isResponseOK {
                obj = self.client.responseParser.parseArray(data, type: T.self)
            }
            completionHandler?(obj, error)
        }
        return request
    }
    
    public func findAll(completionHandler: ArrayCompletionHandler?) -> Request {
        return find(completionHandler: completionHandler)
    }
    
    internal func buildSaveRequest(persistable: T) -> Request {
        let bodyObject = persistable.toJson()
        let request = HttpRequest(
            httpMethod: bodyObject[Kinvey.PersistableIdKey] == nil ? .Post : .Put,
            endpoint: Endpoint.AppData(client: client, collectionName: collectionName),
            credential: client.activeUser,
            client: client
        )
        
        request.request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(bodyObject, options: [])
        return request
    }
    
    public func save(persistable: T, completionHandler: ObjectCompletionHandler?) -> Request {
        let request = buildSaveRequest(persistable)
        request.execute() { data, response, error in
            if let response = response where response.isResponseOK {
                let json = self.client.responseParser.parse(data, type: [String : AnyObject].self)
                if let json = json {
                    persistable.loadFromJson(json)
                }
            }
            completionHandler?(persistable, error)
        }
        return request
    }
    
    public func save(array: [T], completionHandler: ArrayCompletionHandler?) {
        //TODO: future implementation
    }
    
    public func remove(persistable: T, completionHandler: UIntCompletionHandler?) throws -> Request {
        guard let id = persistable.kinveyObjectId else {
            throw Error.ObjectIdMissing
        }
        return remove(id, completionHandler: completionHandler)
    }
    
    public func remove(array: [T], completionHandler: UIntCompletionHandler?) -> Request {
        var ids: [String] = []
        for persistable in array {
            if let id = persistable.kinveyObjectId {
                ids.append(id)
            }
        }
        return remove(ids, completionHandler: completionHandler)
    }
    
    public func remove(id: String, completionHandler: UIntCompletionHandler?) -> Request {
        let query = Query(format: "\(T.idKey) == %@", id)
        return remove(query, completionHandler: completionHandler)
    }
    
    public func remove(ids: [String], completionHandler: UIntCompletionHandler?) -> Request {
        let query = Query(format: "\(T.idKey) IN %@", ids)
        return remove(query, completionHandler: completionHandler)
    }
    
    internal func buildRemoveRequest(query: Query = Query()) -> Request {
        let request = HttpRequest(
            httpMethod: .Delete,
            endpoint: Endpoint.AppDataByQuery(client: client, collectionName: collectionName, query: query),
            credential: client.activeUser,
            client: client
        )
        return request
    }
    
    public func remove(query: Query = Query(), completionHandler: UIntCompletionHandler?) -> Request {
        let request = buildRemoveRequest(query)
        request.execute() { data, response, error in
            var count: UInt? = nil
            if let response = response where response.isResponseOK {
                let results = self.client.responseParser.parse(data, type: [String : AnyObject].self)
                if let results = results, let _count = results["count"] as? UInt {
                    count = _count
                }
            }
            completionHandler?(count, error)
        }
        return request
    }
    
    public func removeAll(completionHandler: UIntCompletionHandler?) -> Request {
        return remove(completionHandler: completionHandler)
    }
    
    internal func toJson(obj: T) -> [String : AnyObject] {
        let obj = obj as! AnyObject
        let keys = T.kinveyPropertyMapping().map({ keyValuePair in keyValuePair.0 })
        return obj.dictionaryWithValuesForKeys(keys)
    }
    
    internal func toJson(array: [T]) -> [[String : AnyObject]] {
        var entities: [[String : AnyObject]] = []
        for obj in array {
            let obj = obj as! AnyObject
            let keys = T.kinveyPropertyMapping().map({ keyValuePair in keyValuePair.0 })
            entities.append(obj.dictionaryWithValuesForKeys(keys))
        }
        return entities
    }
    
    internal func fromJson(json: [String : AnyObject]) -> T? {
        if let objectType = T.self as? NSObject.Type {
            let obj = objectType.init()
            obj.setValuesForKeysWithDictionary(json)
            return obj as? T
        }
        return nil
    }
    
    internal func fromJson(jsonArray: [[String : AnyObject]]) -> [T] {
        var results: [T] = []
        if let objectType = T.self as? NSObject.Type {
            for json in jsonArray {
                let obj = objectType.init()
                obj.setValuesForKeysWithDictionary(json)
                results.append(obj as! T)
            }
        }
        return results
    }
    
    //MARK: - Dispatch Async To
    
    internal func dispatchAsyncTo(queue queue: dispatch_queue_t = dispatch_get_main_queue(), _ completionHandler: ObjectCompletionHandler? = nil) -> ObjectCompletionHandler? {
        var completionHandler = completionHandler
        if let originalCompletionHandler = completionHandler {
            completionHandler = { obj, error in
                dispatch_async(queue, { () -> Void in
                    originalCompletionHandler(obj, error)
                })
            }
        }
        return completionHandler
    }
    
    internal func dispatchAsyncTo(queue queue: dispatch_queue_t = dispatch_get_main_queue(), _ completionHandler: ArrayCompletionHandler? = nil) -> ArrayCompletionHandler? {
        var completionHandler = completionHandler
        if let originalCompletionHandler = completionHandler {
            completionHandler = { objs, error in
                dispatch_async(queue, { () -> Void in
                    originalCompletionHandler(objs, error)
                })
            }
        }
        return completionHandler
    }
    
    internal func dispatchAsyncTo(queue queue: dispatch_queue_t = dispatch_get_main_queue(), _ completionHandler: UIntCompletionHandler? = nil) -> UIntCompletionHandler? {
        var completionHandler = completionHandler
        if let originalCompletionHandler = completionHandler {
            completionHandler = { objs, error in
                dispatch_async(queue, { () -> Void in
                    originalCompletionHandler(objs, error)
                })
            }
        }
        return completionHandler
    }

}
