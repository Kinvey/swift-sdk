//
//  BaseStore.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-14.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import KinveyKit

extension StoreType {
    
    private func readPolicy() -> ReadPolicy {
        switch self {
        case .Cache:
            return .PreferLocal
        case .Network:
            return .ForceNetwork
        case .Sync:
            return .ForceLocal
        }
    }
    
    private func writePolicy() -> WritePolicy {
        switch self {
        case .Cache:
            return .LocalThenNetwork
        case .Network:
            return .ForceNetwork
        case .Sync:
            return .ForceLocal
        }
    }
    
}

extension ReadPolicy {
    
    private func executor<T: Persistable where T: NSObject>(store: DataStore<T>) -> AppDataExecutorStrategy<T> {
        switch self {
        case .ForceLocal:
            return LocalAppDataExecutorStrategy<T>(client: store.client, cache: store.cache, sync: nil)
        case .ForceNetwork:
            return NetworkAppDataExecutorStrategy<T>(client: store.client, cache: store.cache)
        case .PreferLocal:
            return LocalAppDataExecutorStrategy<T>(client: store.client, cache: store.cache, sync: nil)
        case .PreferNetwork:
            return LocalAppDataExecutorStrategy<T>(client: store.client, cache: nil, sync: store.sync)
        }
    }
    
}

extension WritePolicy {
    
    private func executor<T: Persistable where T: NSObject>(store: DataStore<T>) -> AppDataExecutorStrategy<T> {
        switch self {
        case .ForceLocal:
            return LocalAppDataExecutorStrategy<T>(client: store.client, cache: store.cache, sync: store.sync)
        case .ForceNetwork:
            return NetworkAppDataExecutorStrategy<T>(client: store.client, cache: store.cache)
        case .LocalThenNetwork:
            return LocalAppDataExecutorStrategy<T>(client: store.client, cache: store.cache, sync: store.sync)
        }
    }
    
}

public class DataStore<T: Persistable where T: NSObject> {
    
    public typealias ArrayCompletionHandler = ([T]?, ErrorType?) -> Void
    public typealias ObjectCompletionHandler = (T?, ErrorType?) -> Void
    public typealias UIntCompletionHandler = (UInt?, ErrorType?) -> Void
    public typealias UIntArrayCompletionHandler = (UInt?, [T]?, ErrorType?) -> Void
    
    private let readPolicy: ReadPolicy
    private let writePolicy: WritePolicy
    
    public let collectionName: String
    public let client: Client
    
    private let cache: Cache
    private let sync: Sync
    
    public class func getInstance(type: StoreType = .Cache, client: Client = sharedClient) -> DataStore {
        return DataStore<T>(readPolicy: type.readPolicy(), writePolicy: type.writePolicy(), client: client)
    }
    
    // TODO: chage to ReadPolicy to be .PreferLocal
    private init(readPolicy: ReadPolicy, writePolicy: WritePolicy, client: Client = Kinvey.sharedClient) {
        self.readPolicy = readPolicy
        self.writePolicy = writePolicy
        self.client = client
        self.collectionName = T.kinveyCollectionName()
        self.cache = client.cacheManager.cache(T.kinveyCollectionName())
        self.sync = client.syncManager.sync(T.kinveyCollectionName())
    }
    
    public func findById(id: String, completionHandler: ObjectCompletionHandler?) -> Request {
        assert(id != "")
        return readPolicy.executor(self).get(id, completionHandler: completionHandler)
    }
    
    public func find(query: Query = Query(), completionHandler: ArrayCompletionHandler?) -> Request {
        return readPolicy.executor(self).find(query, completionHandler: completionHandler)
    }
    
    public func save(persistable: T, completionHandler: ObjectCompletionHandler?) -> Request {
        return writePolicy.executor(self).save(persistable, completionHandler: completionHandler)
    }
    
    public func remove(persistable: T, completionHandler: UIntCompletionHandler?) throws -> Request {
        guard let id = persistable.kinveyObjectId else {
            throw Error.ObjectIdMissing
        }
        return removeById(id, completionHandler: completionHandler)
    }
    
    public func remove(array: [T], completionHandler: UIntCompletionHandler?) -> Request {
        var ids: [String] = []
        for persistable in array {
            if let id = persistable.kinveyObjectId {
                ids.append(id)
            }
        }
        return removeById(ids, completionHandler: completionHandler)
    }
    
    public func removeById(id: String, completionHandler: UIntCompletionHandler?) -> Request {
        let query = Query(format: "\(T.idKey) == %@", id)
        return remove(query, completionHandler: completionHandler)
    }
    
    public func removeById(ids: [String], completionHandler: UIntCompletionHandler?) -> Request {
        let query = Query(format: "\(T.idKey) IN %@", ids)
        return remove(query, completionHandler: completionHandler)
    }
    
    public func remove(query: Query = Query(), completionHandler: UIntCompletionHandler?) -> Request {
        return writePolicy.executor(self).remove(query, completionHandler: completionHandler)
    }
    
    public func removeAll(completionHandler: UIntCompletionHandler?) -> Request {
        return remove(completionHandler: completionHandler)
    }
    
    public func push(completionHandler: UIntCompletionHandler? = nil) throws {
        try writePolicy.executor(self).push(completionHandler)
    }
    
    public func pull(query: Query = Query(), completionHandler: DataStore<T>.ArrayCompletionHandler?) throws {
        try writePolicy.executor(self).pull(query, completionHandler: completionHandler)
    }
    
    public func sync(query: Query = Query(), completionHandler: UIntArrayCompletionHandler? = nil) throws {
        try writePolicy.executor(self).sync(query, completionHandler: completionHandler)
    }
    
    public func purge() throws {
        try writePolicy.executor(self).purge()
    }

}
