//
//  BaseStore.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-14.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import KinveyKit

extension ReadPolicy {
    
    private func execute<T: Persistable>(store: Store<T>) -> GenericAppDataExecutorStrategy<T> {
        switch self {
        case .ForceLocal:
            return LocalAppDataExecutorStrategy<T>(client: store.client, cache: store.cache, sync: store.sync)
        case .ForceNetwork:
            return NetworkAppDataExecutorStrategy<T>(client: store.client, cache: store.cache)
//        case .PreferLocal:
//            print("")
//        case .PreferNetwork:
//            print("")
        }
    }
    
}

public class Store<T: Persistable> {
    
    public typealias ArrayCompletionHandler = ([T]?, NSError?) -> Void
    public typealias ObjectCompletionHandler = (T?, NSError?) -> Void
    public typealias UIntCompletionHandler = (UInt?, NSError?) -> Void
    public typealias UIntArrayCompletionHandler = (UInt?, [T]?, NSError?) -> Void
    
    private let readPolicy: ReadPolicy
    
    public let collectionName: String
    public let client: Client
    
    private let cache: Cache
    private let sync: Sync
    
    internal let clazz: AnyClass = T.self as! AnyClass
    
    // TODO: chage to ReadPolicy to be .PreferLocal
    init(client: Client = Kinvey.sharedClient, readPolicy: ReadPolicy = .ForceNetwork) {
        self.client = client
        self.collectionName = T.kinveyCollectionName()
        self.readPolicy = readPolicy
        self.cache = client.cacheManager.cache(T.kinveyCollectionName())
        self.sync = client.syncManager.sync(T.kinveyCollectionName())
    }
    
    public func get(id: String, completionHandler: ObjectCompletionHandler?) -> Request {
        assert(id != "")
        return readPolicy.execute(self).get(id, completionHandler: completionHandler)
    }
    
    public func find(query: Query = Query(), completionHandler: ArrayCompletionHandler?) -> Request {
        return readPolicy.execute(self).find(query, completionHandler: completionHandler)
    }
    
    public func findAll(completionHandler: ArrayCompletionHandler?) -> Request {
        return find(completionHandler: completionHandler)
    }
    
    public func save(persistable: T, completionHandler: ObjectCompletionHandler?) -> Request {
        return readPolicy.execute(self).save(persistable, completionHandler: completionHandler)
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
    
    public func remove(query: Query = Query(), completionHandler: UIntCompletionHandler?) -> Request {
        return readPolicy.execute(self).remove(query, completionHandler: completionHandler)
    }
    
    public func removeAll(completionHandler: UIntCompletionHandler?) -> Request {
        return remove(completionHandler: completionHandler)
    }
    
    public func push(completionHandler: UIntCompletionHandler? = nil) {
    }
    
    public func sync(query: Query = Query(), completionHandler: UIntArrayCompletionHandler? = nil) {
    }
    
    public func purge() {
    }

}
