//
//  GenericAppDataExecutorStrategy.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-25.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

class AppDataExecutorStrategy<T: Persistable where T: NSObject> {
    
    func get(id: String, completionHandler: DataStore<T>.ObjectCompletionHandler?) -> Request {
        fatalError("Method \(__FILE__).\(__FUNCTION__):\(__LINE__) not implemented")
    }
    
    func find(query: Query, completionHandler: DataStore<T>.ArrayCompletionHandler?) -> Request {
        fatalError("Method \(__FILE__).\(__FUNCTION__):\(__LINE__) not implemented")
    }
    
    func save(persistable: T, completionHandler: DataStore<T>.ObjectCompletionHandler?) -> Request {
        fatalError("Method \(__FILE__).\(__FUNCTION__):\(__LINE__) not implemented")
    }
    
    func remove(query: Query, completionHandler: DataStore<T>.UIntCompletionHandler?) -> Request {
        fatalError("Method \(__FILE__).\(__FUNCTION__):\(__LINE__) not implemented")
    }
    
    func push(completionHandler: DataStore<T>.UIntCompletionHandler?) throws {
        fatalError("Method \(__FILE__).\(__FUNCTION__):\(__LINE__) not implemented")
    }
    
    func pull(query: Query, completionHandler: DataStore<T>.ArrayCompletionHandler?) throws {
        fatalError("Method \(__FILE__).\(__FUNCTION__):\(__LINE__) not implemented")
    }
    
    func purge(completionHandler: DataStore<T>.UIntCompletionHandler?) throws {
        fatalError("Method \(__FILE__).\(__FUNCTION__):\(__LINE__) not implemented")
    }
    
    func sync(query: Query, completionHandler: DataStore<T>.UIntArrayCompletionHandler?) throws {
        fatalError("Method \(__FILE__).\(__FUNCTION__):\(__LINE__) not implemented")
    }
    
    func dispatchAsyncTo(queue queue: dispatch_queue_t = dispatch_get_main_queue(), _ completionHandler: DataStore<T>.ObjectCompletionHandler? = nil) -> DataStore<T>.ObjectCompletionHandler? {
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
    
    func dispatchAsyncTo(queue queue: dispatch_queue_t = dispatch_get_main_queue(), _ completionHandler: DataStore<T>.ArrayCompletionHandler? = nil) -> DataStore<T>.ArrayCompletionHandler? {
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
    
    func dispatchAsyncTo(queue queue: dispatch_queue_t = dispatch_get_main_queue(), _ completionHandler: DataStore<T>.UIntCompletionHandler? = nil) -> DataStore<T>.UIntCompletionHandler? {
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
    
    func fromJson(json: [String : AnyObject]) -> T {
        let obj = T.self.init()
        for key in T.kinveyPropertyMapping().keys {
            obj.setValue(json[key], forKey: key)
        }
        return obj
    }
    
    func fromJson(jsonArray: [[String : AnyObject]]) -> [T] {
        var results: [T] = []
        for json in jsonArray {
            let obj = fromJson(json)
            results.append(obj)
        }
        return results
    }
    
    func toJson(array: [T]) -> [[String : AnyObject]] {
        var entities: [[String : AnyObject]] = []
        for obj in array {
            let keys = T.kinveyPropertyMapping().map({ keyValuePair in keyValuePair.0 })
            entities.append(obj.dictionaryWithValuesForKeys(keys))
        }
        return entities
    }
    
}
