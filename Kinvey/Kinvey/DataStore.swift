//
//  BaseStore.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-14.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

public class DataStore<T: Persistable where T: NSObject> {
    
    public typealias ArrayCompletionHandler = ([T]?, ErrorType?) -> Void
    public typealias ObjectCompletionHandler = (T?, ErrorType?) -> Void
    public typealias UIntCompletionHandler = (UInt?, ErrorType?) -> Void
    public typealias UIntArrayCompletionHandler = (UInt?, [T]?, ErrorType?) -> Void
    
    private let readPolicy: ReadPolicy
    private let writePolicy: WritePolicy
    
    public let collectionName: String
    public let client: Client
    
    public let type: DataStoreType
    
    private let cache: Cache
    private let sync: Sync
    
    public class func getInstance(type: DataStoreType = .Cache, client: Client = sharedClient) -> DataStore {
        return DataStore<T>(type: type, client: client)
    }
    
    private init(type: DataStoreType, client: Client) {
        self.type = type
        self.client = client
        collectionName = T.kinveyCollectionName()
        cache = client.cacheManager.cache(collectionName)
        sync = client.syncManager.sync(collectionName)
        readPolicy = type.readPolicy
        writePolicy = type.writePolicy
    }
    
    public func findById(id: String, readPolicy: ReadPolicy? = nil, completionHandler: ObjectCompletionHandler? = nil) -> Request {
        assert(id != "")
        let readPolicy = readPolicy ?? self.readPolicy
        let operation = GetOperation(id: id, readPolicy: readPolicy, persistableType: T.self, cache: cache, client: client)
        let request = operation.execute(dispatchAsyncMainQueue(completionHandler))
        return request
    }
    
    public func find(query: Query = Query(), readPolicy: ReadPolicy? = nil, completionHandler: ArrayCompletionHandler?) -> Request {
        let readPolicy = readPolicy ?? self.readPolicy
        let operation = FindOperation(query: Query(query: query, persistableType: T.self), readPolicy: readPolicy, persistableType: T.self, cache: cache, client: client)
        let request = operation.execute(dispatchAsyncMainQueue(completionHandler))
        return request
    }
    
    public func save(persistable: T, writePolicy: WritePolicy? = nil, completionHandler: ObjectCompletionHandler?) -> Request {
        let writePolicy = writePolicy ?? self.writePolicy
        let operation = SaveOperation(persistable: persistable, writePolicy: writePolicy, sync: sync, cache: cache, client: client)
        let request = operation.execute(dispatchAsyncMainQueue(completionHandler))
        return request
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
    
    public func remove(query: Query = Query(), writePolicy: WritePolicy? = nil, completionHandler: UIntCompletionHandler?) -> Request {
        let writePolicy = writePolicy ?? self.writePolicy
        let operation = RemoveOperation(query: Query(query: query, persistableType: T.self), writePolicy: writePolicy, sync: sync, persistableType: T.self, cache: cache, client: client)
        let request = operation.execute(dispatchAsyncMainQueue(completionHandler))
        return request
    }
    
    public func removeAll(completionHandler: UIntCompletionHandler?) -> Request {
        return remove(completionHandler: completionHandler)
    }
    
    public func push(completionHandler: UIntCompletionHandler? = nil) -> Request {
        let completionHandler = dispatchAsyncMainQueue(completionHandler)
        guard type == .Sync else {
            completionHandler?(nil, Error.InvalidStoreType)
            return LocalRequest()
        }
        
        let operation = PushOperation(writePolicy: writePolicy, sync: sync, persistableType: T.self, cache: cache, client: client)
        let request = operation.execute(completionHandler)
        return request
    }
    
    public func pull(query: Query = Query(), completionHandler: DataStore<T>.ArrayCompletionHandler? = nil) -> Request {
        let completionHandler = dispatchAsyncMainQueue(completionHandler)
        guard type == .Sync else {
            completionHandler?(nil, Error.InvalidStoreType)
            return LocalRequest()
        }
        
        let operation = PullOperation(query: Query(query: query, persistableType: T.self), writePolicy: writePolicy, sync: sync, persistableType: T.self, cache: cache, client: client)
        let request = operation.execute(completionHandler)
        return request
    }
    
    public func sync(query: Query = Query(), completionHandler: UIntArrayCompletionHandler? = nil) -> Request {
        let completionHandler = dispatchAsyncMainQueue(completionHandler)
        guard type == .Sync else {
            completionHandler?(nil, nil, Error.InvalidStoreType)
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
    
    public func purge(completionHandler: DataStore<T>.UIntCompletionHandler? = nil) -> Request {
        let completionHandler = dispatchAsyncMainQueue(completionHandler)
        guard type == .Sync else {
            completionHandler?(nil, Error.InvalidStoreType)
            return LocalRequest()
        }
        
        let operation = PurgeOperation(writePolicy: writePolicy, sync: sync, persistableType: T.self, cache: cache, client: client)
        let request = operation.execute { (count, error) -> Void in
            if let count = count {
                self.pull() { (results, error) -> Void in
                    completionHandler?(count, error)
                }
            } else if let error = error {
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
