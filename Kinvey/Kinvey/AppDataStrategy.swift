//
//  AppDataStrategy.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-22.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

protocol AppDataExecutorStrategy {
    
    typealias T
    typealias ArrayCompletionHandler = ([T]?, NSError?) -> Void
    typealias ObjectCompletionHandler = (T?, NSError?) -> Void
    typealias UIntCompletionHandler = (UInt?, NSError?) -> Void
    
    func get(id: String, completionHandler: ObjectCompletionHandler?) -> Request
    func find(query: Query, completionHandler: ArrayCompletionHandler?) -> Request
    func save(persistable: T, completionHandler: ObjectCompletionHandler?) -> Request
    func remove(query: Query, completionHandler: UIntCompletionHandler?) -> Request
    
}

extension AppDataExecutorStrategy {
    
    func dispatchAsyncTo<T: Persistable>(queue queue: dispatch_queue_t = dispatch_get_main_queue(), type: T.Type, _ completionHandler: Store<T>.ObjectCompletionHandler? = nil) -> Store<T>.ObjectCompletionHandler? {
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
    
    func dispatchAsyncTo<T: Persistable>(queue queue: dispatch_queue_t = dispatch_get_main_queue(), type: T.Type, _ completionHandler: Store<T>.ArrayCompletionHandler? = nil) -> Store<T>.ArrayCompletionHandler? {
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
    
    func dispatchAsyncTo<T: Persistable>(queue queue: dispatch_queue_t = dispatch_get_main_queue(), type: T.Type, _ completionHandler: Store<T>.UIntCompletionHandler? = nil) -> Store<T>.UIntCompletionHandler? {
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
    
    func fromJson(json: [String : AnyObject]) -> T? {
        if let objectType = T.self as? NSObject.Type {
            let obj = objectType.init()
            obj.setValuesForKeysWithDictionary(json)
            return obj as? T
        }
        return nil
    }
    
    func fromJson(jsonArray: [[String : AnyObject]]) -> [T] {
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
    
    func toJson<T: Persistable>(obj: T) -> [String : AnyObject] {
        let obj = obj as! AnyObject
        let keys = T.kinveyPropertyMapping().map({ keyValuePair in keyValuePair.0 })
        return obj.dictionaryWithValuesForKeys(keys)
    }
    
    func toJson<T: Persistable>(array: [T]) -> [[String : AnyObject]] {
        var entities: [[String : AnyObject]] = []
        for obj in array {
            let obj = obj as! AnyObject
            let keys = T.kinveyPropertyMapping().map({ keyValuePair in keyValuePair.0 })
            entities.append(obj.dictionaryWithValuesForKeys(keys))
        }
        return entities
    }
    
}
