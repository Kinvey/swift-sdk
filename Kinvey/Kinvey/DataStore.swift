//
//  BaseStore.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-14.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

/// Class to interact with a specific collection in the backend.
public class DataStore<T: Persistable where T: NSObject> {
    
    public typealias ArrayCompletionHandler = ([T]?, ErrorType?) -> Void
    public typealias ObjectCompletionHandler = (T?, ErrorType?) -> Void
    public typealias UIntCompletionHandler = (UInt?, ErrorType?) -> Void
    public typealias UIntArrayCompletionHandler = (UInt?, [T]?, ErrorType?) -> Void
    
    private let readPolicy: ReadPolicy
    private let writePolicy: WritePolicy
    
    /// Collection name that matches with the name in the backend.
    public let collectionName: String
    
    /// Client instance attached to the DataStore.
    public let client: Client
    
    /// DataStoreType defines how the DataStore will behave.
    public let type: DataStoreType
    
    private let cache: Cache
    private let sync: Sync
    
    /// TTL (Time to Live) defines a filter of how old the data returned from the DataStore can be.
    public var ttl: TTL? {
        didSet {
            cache.ttl = ttl != nil ? ttl!.1.toTimeInterval(ttl!.0) : 0
        }
    }
    
    /// Factory method that returns a `DataStore`.
    public class func getInstance(type: DataStoreType = .Cache, client: Client = sharedClient) -> DataStore {
        return DataStore<T>(type: type, client: client, filePath: nil)
    }
    
    private init(type: DataStoreType, client: Client, filePath: String?) {
        self.type = type
        self.client = client
        collectionName = T.kinveyCollectionName()
        cache = client.cacheManager.cache(collectionName, filePath: filePath)
        sync = client.syncManager.sync(collectionName, filePath: filePath)
        readPolicy = type.readPolicy
        writePolicy = type.writePolicy
    }
    
    /// Gets a single record using the `_id` of the record.
    public func findById(id: String, readPolicy: ReadPolicy? = nil, completionHandler: ObjectCompletionHandler? = nil) -> Request {
        assert(id != "")
        let readPolicy = readPolicy ?? self.readPolicy
        let operation = GetOperation(id: id, readPolicy: readPolicy, persistableType: T.self, cache: cache, client: client)
        let request = operation.execute(dispatchAsyncMainQueue(completionHandler))
        return request
    }
    
    /// Gets a single record using the `_id` of the record.
    public func find(id: String, readPolicy: ReadPolicy? = nil, completionHandler: ObjectCompletionHandler? = nil) -> Request {
        return findById(id, readPolicy: readPolicy, completionHandler: completionHandler)
    }
    
    /// Gets a list of records that matches with the query passed by parameter.
    public func find(query: Query = Query(), deltaSet: Bool = true, readPolicy: ReadPolicy? = nil, completionHandler: ArrayCompletionHandler?) -> Request {
        let readPolicy = readPolicy ?? self.readPolicy
        let operation = FindOperation(query: Query(query: query, persistableType: T.self), deltaSet: deltaSet, readPolicy: readPolicy, persistableType: T.self, cache: cache, client: client)
        let request = operation.execute(dispatchAsyncMainQueue(completionHandler))
        return request
    }
    
    /// Creates or updates a record.
    public func save(persistable: T, writePolicy: WritePolicy? = nil, completionHandler: ObjectCompletionHandler?) -> Request {
        let writePolicy = writePolicy ?? self.writePolicy
        let operation = SaveOperation(persistable: persistable, writePolicy: writePolicy, sync: sync, cache: cache, client: client)
        let request = operation.execute(dispatchAsyncMainQueue(completionHandler))
        return request
    }
    
    /// Deletes a record.
    public func remove(persistable: T, writePolicy: WritePolicy? = nil, completionHandler: UIntCompletionHandler?) throws -> Request {
        guard let id = persistable.kinveyObjectId else {
            throw Error.ObjectIdMissing
        }
        return removeById(id, writePolicy:writePolicy, completionHandler: completionHandler)
    }
    
    /// Deletes a list of records.
    public func remove(array: [T], writePolicy: WritePolicy? = nil, completionHandler: UIntCompletionHandler?) -> Request {
        var ids: [String] = []
        for persistable in array {
            if let id = persistable.kinveyObjectId {
                ids.append(id)
            }
        }
        return removeById(ids, writePolicy:writePolicy, completionHandler: completionHandler)
    }
    
    /// Deletes a record using the `_id` of the record.
    public func removeById(id: String, writePolicy: WritePolicy? = nil, completionHandler: UIntCompletionHandler?) -> Request {
        let query = Query(format: "\(T.idKey) == %@", id)
        return remove(query, writePolicy: writePolicy, completionHandler: completionHandler)
    }
    
    /// Deletes a list of records using the `_id` of the records.
    public func removeById(ids: [String], writePolicy: WritePolicy? = nil, completionHandler: UIntCompletionHandler?) -> Request {
        let query = Query(format: "\(T.idKey) IN %@", ids)
        return remove(query, writePolicy: writePolicy, completionHandler: completionHandler)
    }
    
    /// Deletes a list of records that matches with the query passed by parameter.
    public func remove(query: Query = Query(), writePolicy: WritePolicy? = nil, completionHandler: UIntCompletionHandler?) -> Request {
        let writePolicy = writePolicy ?? self.writePolicy
        let operation = RemoveOperation(query: Query(query: query, persistableType: T.self), writePolicy: writePolicy, sync: sync, persistableType: T.self, cache: cache, client: client)
        let request = operation.execute(dispatchAsyncMainQueue(completionHandler))
        return request
    }
    
    /// Deletes all the records.
    public func removeAll(writePolicy: WritePolicy? = nil, completionHandler: UIntCompletionHandler?) -> Request {
        return remove(writePolicy: writePolicy, completionHandler: completionHandler)
    }
    
    /// Sends to the backend all the pending records in the local cache.
    public func push(timeout timeout: NSTimeInterval? = nil, completionHandler: UIntCompletionHandler? = nil) -> Request {
        let completionHandler = dispatchAsyncMainQueue(completionHandler)
        guard type == .Sync else {
            completionHandler?(nil, KinveyError.InvalidDataStoreType)
            return LocalRequest()
        }
        
        let operation = PushOperation(sync: sync, persistableType: T.self, cache: cache, client: client)
        let request = operation.execute(timeout: timeout, completionHandler: completionHandler)
        return request
    }
    
    /// Gets the records from the backend that matches with the query passed by parameter and saves locally in the local cache.
    public func pull(query: Query = Query(), completionHandler: DataStore<T>.ArrayCompletionHandler? = nil) -> Request {
        let completionHandler = dispatchAsyncMainQueue(completionHandler)
        guard type == .Sync else {
            completionHandler?(nil, KinveyError.InvalidDataStoreType)
            return LocalRequest()
        }
        
        let operation = FindOperation(query: Query(query: query, persistableType: T.self), deltaSet: true, readPolicy: .ForceNetwork, persistableType: T.self, cache: cache, client: client)
        let request = operation.execute(completionHandler)
        return request
    }
    
    /// Calls `push` and then `pull` methods, so it sends all the pending records in the local cache and then gets the records from the backend and saves locally in the local cache.
    public func sync(query: Query = Query(), completionHandler: UIntArrayCompletionHandler? = nil) -> Request {
        let completionHandler = dispatchAsyncMainQueue(completionHandler)
        guard type == .Sync else {
            completionHandler?(nil, nil, KinveyError.InvalidDataStoreType)
            return LocalRequest()
        }
        
        let requests = MultiRequest()
        let request = push() { count, error in
            if let count = count where error == nil {
                let request = self.pull(query) { results, error in
                    completionHandler?(count, results, error)
                }
                requests.addRequest(request)
            } else {
                completionHandler?(count, nil, error)
            }
        }
        requests.addRequest(request)
        return requests
    }
    
    /// Deletes all the pending chances in the local cache.
    public func purge(query: Query = Query(), completionHandler: DataStore<T>.UIntCompletionHandler? = nil) -> Request {
        let completionHandler = dispatchAsyncMainQueue(completionHandler)
        guard type == .Sync else {
            completionHandler?(nil, Error.InvalidDataStoreType)
            return LocalRequest()
        }
        
        let operation = PurgeOperation(sync: sync, persistableType: T.self, cache: cache, client: client)
        let request = operation.execute { (count, error: ErrorType?) -> Void in
            if let count = count {
                self.pull(query) { (results, error) -> Void in
                    completionHandler?(count, error)
                }
            } else {
                completionHandler?(count, error)
            }
        }
        return request
    }
    
    //MARK: Dispatch Async Main Queue
    
    private func dispatchAsyncMainQueue<R>(completionHandler: ((R?, ErrorType?) -> Void)? = nil) -> ((AnyObject?, ErrorType?) -> Void)? {
        if let completionHandler = completionHandler {
            return { (obj: AnyObject?, error: ErrorType?) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionHandler(obj as? R, error)
                })
            }
        }
        return nil
    }
    
    private func dispatchAsyncMainQueue<R1, R2>(completionHandler: ((R1?, R2?, ErrorType?) -> Void)? = nil) -> ((R1?, R2?, ErrorType?) -> Void)? {
        if let completionHandler = completionHandler {
            return { (obj1: R1?, obj2: R2?, error: ErrorType?) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionHandler(obj1, obj2, error)
                })
            }
        }
        return nil
    }

}
