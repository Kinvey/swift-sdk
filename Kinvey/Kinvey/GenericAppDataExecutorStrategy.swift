//
//  GenericAppDataExecutorStrategy.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-25.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

class GenericAppDataExecutorStrategy<T: Persistable>: AppDataExecutorStrategy {
    
    private let instance: GenericAppDataExecutorStrategy?
    
    init(_ instance: GenericAppDataExecutorStrategy?) {
        self.instance = instance
    }
    
    func get(id: String, completionHandler: Store<T>.ObjectCompletionHandler?) -> Request {
        return instance!.get(id, completionHandler: completionHandler)
    }
    
    func find(query: Query, completionHandler: Store<T>.ArrayCompletionHandler?) -> Request {
        return instance!.find(query, completionHandler: completionHandler)
    }
    
    func save(persistable: T, completionHandler: Store<T>.ObjectCompletionHandler?) -> Request {
        return instance!.save(persistable, completionHandler: completionHandler)
    }
    
    func remove(query: Query, completionHandler: Store<T>.UIntCompletionHandler?) -> Request {
        return instance!.remove(query, completionHandler: completionHandler)
    }
    
}
