//
//  BaseStore.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-14.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

class DataStoreTypeTag: Hashable {
    
    let persistableType: Persistable.Type
    let tag: String
    let type: DataStoreType
    
    init(persistableType: Persistable.Type, tag: String, type: DataStoreType) {
        self.persistableType = persistableType
        self.tag = tag
        self.type = type
    }
    
    var hashValue: Int {
        var hash = NSDecimalNumber(integer: 5)
        hash = 23 * hash + NSDecimalNumber(integer: NSStringFromClass(persistableType as! AnyClass).hashValue)
        hash = 23 * hash + NSDecimalNumber(integer: tag.hashValue)
        hash = 23 * hash + NSDecimalNumber(integer: type.hashValue)
        return hash.hashValue
    }
    
}

func +(lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> NSDecimalNumber {
    return lhs.decimalNumberByAdding(rhs)
}

func *(lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> NSDecimalNumber {
    return lhs.decimalNumberByMultiplyingBy(rhs)
}

func ==(lhs: DataStoreTypeTag, rhs: DataStoreTypeTag) -> Bool {
    return lhs.persistableType == rhs.persistableType &&
        lhs.tag == rhs.tag &&
        lhs.type == rhs.type
}

let defaultTag = "kinvey"

/// Class to interact with a specific collection in the backend.
public class DataStore<T: Persistable where T: NSObject> {
    
    public typealias ArrayCompletionHandler = ([T]?, ErrorType?) -> Void
    public typealias ObjectCompletionHandler = (T?, ErrorType?) -> Void
    public typealias UIntCompletionHandler = (UInt?, ErrorType?) -> Void
    public typealias UIntErrorTypeArrayCompletionHandler = (UInt?, [ErrorType]?) -> Void
    public typealias UIntArrayCompletionHandler = (UInt?, [T]?, [ErrorType]?) -> Void
    
    private let readPolicy: ReadPolicy
    private let writePolicy: WritePolicy
    
    /// Collection name that matches with the name in the backend.
    public let collectionName: String
    
    /// Client instance attached to the DataStore.
    public let client: Client
    
    /// DataStoreType defines how the DataStore will behave.
    public let type: DataStoreType
    
    private let cache: Cache<T>?
    private let sync: Sync<T>?
    
    private var deltaSet: Bool
    
    /// TTL (Time to Live) defines a filter of how old the data returned from the DataStore can be.
    public var ttl: TTL? {
        didSet {
            if let cache = cache {
                cache.ttl = ttl != nil ? ttl!.1.toTimeInterval(ttl!.0) : nil
            }
        }
    }
    
    /**
     Deprecated method. Please use `collection()` instead.
     */
    @available(*, deprecated=3.0.22, message="Please use `collection()` instead")
    public class func getInstance(type: DataStoreType = .Cache, deltaSet: Bool? = nil, client: Client = sharedClient, tag: String = defaultTag) -> DataStore {
        return collection(type, deltaSet: deltaSet, client: client, tag: tag)
    }

    /**
     Factory method that returns a `DataStore`.
     - parameter type: defines the data store type which will define the behavior of the `DataStore`. Default value: `Cache`
     - parameter deltaSet: Enables delta set cache which will increase performance and reduce data consumption. Default value: `false`
     - parameter client: define the `Client` to be used for all the requests for the `DataStore` that will be returned. Default value: `Kinvey.sharedClient`
     - parameter tag: A tag/nickname for your `DataStore` which will cache instances with the same tag name. Default value: `Kinvey.defaultTag`
     - returns: An instance of `DataStore` which can be a new instance or a cached instance if you are passing a `tag` parameter.
     */
    public class func collection(type: DataStoreType = .Cache, deltaSet: Bool? = nil, client: Client = sharedClient, tag: String = defaultTag) -> DataStore {
        precondition(client.isInitialized(), "Client is not initialized. Call Kinvey.sharedClient.initialize(...) to initialize the client before creating a DataStore.")
        let key = DataStoreTypeTag(persistableType: T.self, tag: tag, type: type)
        var dataStore = client.dataStoreInstances[key] as? DataStore
        if dataStore == nil {
            let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
            let path = paths.first! as NSString
            var filePath = path.stringByAppendingPathComponent(client.appKey!) as NSString
            
            let fileManager = NSFileManager.defaultManager()
            do {
                let filePath = filePath as String
                if !fileManager.fileExistsAtPath(filePath) {
                    try! fileManager.createDirectoryAtPath(filePath, withIntermediateDirectories: true, attributes: nil)
                }
            }
            
            filePath = filePath.stringByAppendingPathComponent("\(tag).realm")
            dataStore = DataStore<T>(type: type, deltaSet: deltaSet ?? false, client: client, filePath: filePath as String, encryptionKey: client.encryptionKey)
            client.dataStoreInstances[key] = dataStore
        }
        return dataStore!
    }
    
    private init(type: DataStoreType, deltaSet: Bool, client: Client, filePath: String?, encryptionKey: NSData?) {
        self.type = type
        self.deltaSet = deltaSet
        self.client = client
        collectionName = T.collectionName()
        if type != .Network, let _ = T.self as? Entity.Type {
            cache = client.cacheManager.cache(filePath: filePath, type: T.self)
            sync = client.syncManager.sync(filePath: filePath, type: T.self)
        } else {
            cache = nil
            sync = nil
        }
        readPolicy = type.readPolicy
        writePolicy = type.writePolicy
    }
    
    /**
     Gets a single record using the `_id` of the record.
     - parameter id: The `_id` value of the entity to be find
     - parameter readPolicy: Enforces a different `ReadPolicy` otherwise use the client's `ReadPolicy`. Default value: `nil`
     - parameter completionHandler: Completion handler to be called once the respose returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    public func findById(id: String, readPolicy: ReadPolicy? = nil, completionHandler: ObjectCompletionHandler? = nil) -> Request {
        precondition(!id.isEmpty)
        let readPolicy = readPolicy ?? self.readPolicy
        let operation = GetOperation<T>(id: id, readPolicy: readPolicy, cache: cache, client: client)
        let request = operation.execute(dispatchAsyncMainQueue(completionHandler))
        return request
    }
    
    /**
     Gets a single record using the `_id` of the record.
     
     PS: This method is just a shortcut for `findById()`
     - parameter id: The `_id` value of the entity to be find
     - parameter readPolicy: Enforces a different `ReadPolicy` otherwise use the client's `ReadPolicy`. Default value: `nil`
     - parameter completionHandler: Completion handler to be called once the respose returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    public func find(id: String, readPolicy: ReadPolicy? = nil, completionHandler: ObjectCompletionHandler? = nil) -> Request {
        return findById(id, readPolicy: readPolicy, completionHandler: completionHandler)
    }
    
    /**
     Gets a list of records that matches with the query passed by parameter.
     - parameter query: The query used to filter the results
     - parameter deltaSet: Enforces delta set cache otherwise use the client's `deltaSet` value. Default value: `false`
     - parameter readPolicy: Enforces a different `ReadPolicy` otherwise use the client's `ReadPolicy`. Default value: `nil`
     - parameter completionHandler: Completion handler to be called once the respose returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    public func find(query: Query = Query(), deltaSet: Bool? = nil, readPolicy: ReadPolicy? = nil, completionHandler: ArrayCompletionHandler?) -> Request {
        let readPolicy = readPolicy ?? self.readPolicy
        let deltaSet = deltaSet ?? self.deltaSet
        let operation = FindOperation<T>(query: Query(query: query, persistableType: T.self), deltaSet: deltaSet, readPolicy: readPolicy, cache: cache, client: client)
        let request = operation.execute(dispatchAsyncMainQueue(completionHandler))
        return request
    }
    
    /// Creates or updates a record.
    public func save(inout persistable: T, writePolicy: WritePolicy? = nil, completionHandler: ObjectCompletionHandler?) -> Request {
        let writePolicy = writePolicy ?? self.writePolicy
        let operation = SaveOperation<T>(persistable: &persistable, writePolicy: writePolicy, sync: sync, cache: cache, client: client)
        let request = operation.execute(dispatchAsyncMainQueue(completionHandler))
        return request
    }
    
    /// Creates or updates a record.
    public func save(persistable: T, writePolicy: WritePolicy? = nil, completionHandler: ObjectCompletionHandler?) -> Request {
        let writePolicy = writePolicy ?? self.writePolicy
        let operation = SaveOperation<T>(persistable: persistable, writePolicy: writePolicy, sync: sync, cache: cache, client: client)
        let request = operation.execute(dispatchAsyncMainQueue(completionHandler))
        return request
    }
    
    /// Deletes a record.
    public func remove(persistable: T, writePolicy: WritePolicy? = nil, completionHandler: UIntCompletionHandler?) throws -> Request {
        guard let id = persistable.entityId else {
            throw Error.ObjectIdMissing
        }
        return removeById(id, writePolicy:writePolicy, completionHandler: completionHandler)
    }
    
    /// Deletes a list of records.
    public func remove(array: [T], writePolicy: WritePolicy? = nil, completionHandler: UIntCompletionHandler?) -> Request {
        var ids: [String] = []
        for persistable in array {
            if let id = persistable.entityId {
                ids.append(id)
            }
        }
        return removeById(ids, writePolicy:writePolicy, completionHandler: completionHandler)
    }
    
    /// Deletes a record using the `_id` of the record.
    public func removeById(id: String, writePolicy: WritePolicy? = nil, completionHandler: UIntCompletionHandler?) -> Request {
        precondition(!id.isEmpty)

        let writePolicy = writePolicy ?? self.writePolicy
        let operation = RemoveByIdOperation<T>(objectId: id, writePolicy: writePolicy, sync: sync, cache: cache, client: client)
        let request = operation.execute(dispatchAsyncMainQueue(completionHandler))
        return request
    }
    
    /// Deletes a list of records using the `_id` of the records.
    public func removeById(ids: [String], writePolicy: WritePolicy? = nil, completionHandler: UIntCompletionHandler?) -> Request {
        precondition(ids.count > 0)
        let query = Query(format: "\(T.entityIdProperty()) IN %@", ids)
        return remove(query, writePolicy: writePolicy, completionHandler: completionHandler)
    }
    
    /// Deletes a list of records that matches with the query passed by parameter.
    public func remove(query: Query = Query(), writePolicy: WritePolicy? = nil, completionHandler: UIntCompletionHandler?) -> Request {
        let writePolicy = writePolicy ?? self.writePolicy
        let operation = RemoveByQueryOperation<T>(query: Query(query: query, persistableType: T.self), writePolicy: writePolicy, sync: sync, cache: cache, client: client)
        let request = operation.execute(dispatchAsyncMainQueue(completionHandler))
        return request
    }
    
    /// Deletes all the records.
    public func removeAll(writePolicy: WritePolicy? = nil, completionHandler: UIntCompletionHandler?) -> Request {
        return remove(writePolicy: writePolicy, completionHandler: completionHandler)
    }
    
    /// Sends to the backend all the pending records in the local cache.
    public func push(timeout timeout: NSTimeInterval? = nil, completionHandler: UIntErrorTypeArrayCompletionHandler? = nil) -> Request {
        let completionHandler = dispatchAsyncMainQueue(completionHandler)
        if type == .Network {
            completionHandler?(nil, [Error.InvalidDataStoreType])
            return LocalRequest()
        }
        
        let operation = PushOperation<T>(sync: sync, cache: cache, client: client)
        let request = operation.execute(timeout: timeout, completionHandler: completionHandler)
        return request
    }
    
    /// Gets the records from the backend that matches with the query passed by parameter and saves locally in the local cache.
    public func pull(query: Query = Query(), deltaSet: Bool? = nil, completionHandler: DataStore<T>.ArrayCompletionHandler? = nil) -> Request {
        let completionHandler = dispatchAsyncMainQueue(completionHandler)
        if type == .Network {
            completionHandler?(nil, Error.InvalidDataStoreType)
            return LocalRequest()
        }
        
        if self.syncCount() > 0 {
            completionHandler?(nil, Error.InvalidOperation(description: "You must push all pending sync items before new data is pulled. Call push() on the data store instance to push pending items, or purge() to remove them."))
            return LocalRequest()
        }
        
        let deltaSet = deltaSet ?? self.deltaSet
        let operation = FindOperation<T>(query: Query(query: query, persistableType: T.self), deltaSet: deltaSet, readPolicy: .ForceNetwork, cache: cache, client: client)
        let request = operation.execute(completionHandler)
        return request
    }
    
    /// Returns the number of changes not synced yet.
    public func syncCount() -> UInt {
        if let sync = sync {
            return UInt(sync.pendingOperations().count)
        }
        return 0
    }
    
    /// Calls `push` and then `pull` methods, so it sends all the pending records in the local cache and then gets the records from the backend and saves locally in the local cache.
    public func sync(query: Query = Query(), completionHandler: UIntArrayCompletionHandler? = nil) -> Request {
        let completionHandler = dispatchAsyncMainQueue(completionHandler)
        if type == .Network {
            completionHandler?(nil, nil, [Error.InvalidDataStoreType])
            return LocalRequest()
        }
        
        let requests = MultiRequest()
        let request = push() { count, errors in
            if let count = count where errors == nil || errors!.isEmpty {
                let request = self.pull(query) { results, error in
                    completionHandler?(count, results, error != nil ? [error!] : nil)
                }
                requests.addRequest(request)
            } else {
                completionHandler?(count, nil, errors)
            }
        }
        requests.addRequest(request)
        return requests
    }
    
    /// Deletes all the pending changes in the local cache.
    public func purge(query: Query = Query(), completionHandler: DataStore<T>.UIntCompletionHandler? = nil) -> Request {
        let completionHandler = dispatchAsyncMainQueue(completionHandler)
        
        if type == .Network {
            completionHandler?(nil, Error.InvalidDataStoreType)
            return LocalRequest()
        }
        
        let executor = Executor()
        
        let operation = PurgeOperation<T>(sync: sync, cache: cache, client: client)
        let request = operation.execute { (count, error: ErrorType?) -> Void in
            if let count = count {
                executor.execute {
                    self.pull(query) { (results, error) -> Void in
                        completionHandler?(count, error)
                    }
                }
            } else {
                completionHandler?(count, error)
            }
        }
        return request
    }
    
    //MARK: Dispatch Async Main Queue
    
    private func dispatchAsyncMainQueue<R, E>(completionHandler: ((R, E) -> Void)? = nil) -> ((R, E) -> Void)? {
        if let completionHandler = completionHandler {
            return { (obj, error) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionHandler(obj, error)
                })
            }
        }
        return nil
    }
    
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
    
    private func dispatchAsyncMainQueue<R1, R2, R3>(completionHandler: ((R1?, R2?, R3?) -> Void)? = nil) -> ((R1?, R2?, R3?) -> Void)? {
        if let completionHandler = completionHandler {
            return { (obj1: R1?, obj2: R2?, error: R3?) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionHandler(obj1, obj2, error)
                })
            }
        }
        return nil
    }
    
    /// Clear all data for all collections.
    public class func clearCache(tag: String? = nil, client: Client = sharedClient) {
        client.cacheManager.clearAll(tag)
    }

    /// Clear all data for the collection attached to the DataStore.
    public func clearCache() {
        cache?.removeAllEntities()
        sync?.removeAllPendingOperations()
    }

}
