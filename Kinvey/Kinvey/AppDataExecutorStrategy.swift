//
//  GenericAppDataExecutorStrategy.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-25.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

class AppDataExecutorStrategy<T: Persistable> {
    
    func get(id: String, completionHandler: Store<T>.ObjectCompletionHandler?) -> Request {
        fatalError("Method \(__FILE__).\(__FUNCTION__):\(__LINE__) not implemented")
    }
    
    func find(query: Query, completionHandler: Store<T>.ArrayCompletionHandler?) -> Request {
        fatalError("Method \(__FILE__).\(__FUNCTION__):\(__LINE__) not implemented")
    }
    
    func save(persistable: T, completionHandler: Store<T>.ObjectCompletionHandler?) -> Request {
        fatalError("Method \(__FILE__).\(__FUNCTION__):\(__LINE__) not implemented")
    }
    
    func remove(query: Query, completionHandler: Store<T>.UIntCompletionHandler?) -> Request {
        fatalError("Method \(__FILE__).\(__FUNCTION__):\(__LINE__) not implemented")
    }
    
    func push(completionHandler: Store<T>.UIntCompletionHandler?) throws {
        fatalError("Method \(__FILE__).\(__FUNCTION__):\(__LINE__) not implemented")
    }
    
    func purge() throws {
        fatalError("Method \(__FILE__).\(__FUNCTION__):\(__LINE__) not implemented")
    }
    
    func sync(query: Query = Query(), completionHandler: Store<T>.UIntArrayCompletionHandler? = nil) throws {
        fatalError("Method \(__FILE__).\(__FUNCTION__):\(__LINE__) not implemented")
    }
    
    func dispatchAsyncTo(queue queue: dispatch_queue_t = dispatch_get_main_queue(), _ completionHandler: Store<T>.ObjectCompletionHandler? = nil) -> Store<T>.ObjectCompletionHandler? {
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
    
    func dispatchAsyncTo(queue queue: dispatch_queue_t = dispatch_get_main_queue(), _ completionHandler: Store<T>.ArrayCompletionHandler? = nil) -> Store<T>.ArrayCompletionHandler? {
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
    
    func dispatchAsyncTo(queue queue: dispatch_queue_t = dispatch_get_main_queue(), _ completionHandler: Store<T>.UIntCompletionHandler? = nil) -> Store<T>.UIntCompletionHandler? {
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
    
    func toJson(obj: T) -> [String : AnyObject] {
        let obj = obj as! AnyObject
        let keys = T.kinveyPropertyMapping().map({ keyValuePair in keyValuePair.0 })
        return obj.dictionaryWithValuesForKeys(keys)
    }
    
    func toJson(array: [T]) -> [[String : AnyObject]] {
        var entities: [[String : AnyObject]] = []
        for obj in array {
            let obj = obj as! AnyObject
            let keys = T.kinveyPropertyMapping().map({ keyValuePair in keyValuePair.0 })
            entities.append(obj.dictionaryWithValuesForKeys(keys))
        }
        return entities
    }
    
}
